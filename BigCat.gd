# Meowing Cat's Big Number Library for Godot Engine
# Copyright (C) 2024, Oğuzhan Eroğlu <rohanrhu2@gmail.com> (https://oguzhaneroglu.com)
# Licensed under MIT License (https://opensource.org/licenses/MIT)
# See LICENSE file for more information

extends Node
class_name BigCat

# ALl atomic scalar operations are done with 30-bit integers
# They never exceed the native integer limit (2^63 - 1)
# So that's why we can use ATOMIC_BITS = 30 at maximum
static var ATOMIC_BITS = 30
static var ATOMIC_BYTES = floor(ATOMIC_BITS) / ATOMIC_BITS
static var ATOMIC_MAX = int(pow(2, ATOMIC_BITS)) # Godot's Native Max: 9223372036854775807
static var ATOMIC_MAX_MINUS_ONE = ATOMIC_MAX - 1

static var IS_VERBOSE = false

static func set_atomic_bits(p_bits: int) -> void:
	BigCat.ATOMIC_BITS = p_bits
	BigCat.ATOMIC_BYTES = floor(p_bits) / BigCat.ATOMIC_BITS
	BigCat.ATOMIC_MAX = int(pow(2, BigCat.ATOMIC_BITS))
	BigCat.ATOMIC_MAX_MINUS_ONE = BigCat.ATOMIC_MAX - 1

class BigNumber:
	static var ZERO = BigNumber.from_uint(0)
	static var ONE = BigNumber.from_uint(1)
	static var TWO = BigNumber.from_uint(2)
	static var THREE = BigNumber.from_uint(3)
	static var FOUR = BigNumber.from_uint(4)
	
	var value: Array = []
	var is_negative: bool = false
	var string: String: get = _to_string
	var bytes: PackedByteArray: get = to_bytes
	var chars: PackedByteArray: get = to_chars

	static var prime_gen_threads = []
	static var prime_gen_result: BigNumber = null

	static var rng: RandomNumberGenerator = RandomNumberGenerator.new()

	func _init(p_vector: Array = [0], p_is_negative: bool = false) -> void:
		self.value = BigNumber.atomize_vector(p_vector)
		self.is_negative = p_is_negative

		while self.value.size() > 1 and self.value[-1] == 0:
			self.value.resize(self.value.size() - 1)
		
		if self.value.size() == 0:
			self.value = [0]
	
	static func from_bytes(p_bytes: PackedByteArray) -> BigNumber:
		var result = BigNumber.new()
		result.value = []
		
		var temp = 0
		var base = 1
		
		for byte in p_bytes:
			if base > floor(BigCat.ATOMIC_MAX) / 256:
				result.value.append(temp)
				temp = byte
				base = 1
			else:
				temp += byte * base
				base *= 256
		
		if temp > 0 or result.value.size() == 0:
			result.value.append(temp)
		
		return result

	func to_bytes() -> PackedByteArray:
		var result = PackedByteArray()

		for _value in self.value:
			var temp = _value
			while temp > 0:
				result.append(temp % 256)
				temp = temp / 256
			while len(result) % 4 != 0:
				result.append(0)
		
		return result

	static func from_chars(p_bytes: PackedByteArray) -> BigNumber:
		var result = BigNumber.new()
		result.value = []
		
		var temp = 0
		var base = 1
		
		for byte in p_bytes:
			if base > floor(BigCat.ATOMIC_MAX) / 127:
				result.value.append(temp)
				temp = byte
				base = 1
			else:
				temp += byte * base
				base *= 127
		
		if temp > 0 or result.value.size() == 0:
			result.value.append(temp)
		
		return result
	
	func to_chars() -> PackedByteArray:
		var result = PackedByteArray()

		for _value in self.value:
			var temp = _value
			while temp > 0:
				result.append(temp % 127)
				temp = temp / 127
			while len(result) % 4 != 0:
				result.append(0)
		
		return result

	static func from_int(p_number: int) -> BigNumber:
		if p_number == 0:
			return BigNumber.new([0])
		
		var number = abs(p_number)
		var result: Array = []

		while number > 0:
			result.append(number % BigCat.ATOMIC_MAX)
			number /= BigCat.ATOMIC_MAX

		return BigNumber.new(result, p_number < 0)

	static func from_uint(p_number: int) -> BigNumber:
		if p_number == 0:
			return BigNumber.new([0])
		
		var number = p_number
		var result: Array = []

		while number > 0:
			result.append(number % BigCat.ATOMIC_MAX)
			number /= BigCat.ATOMIC_MAX

		return BigNumber.new(result)

	static func from_string(p_number: String) -> BigNumber:
		var number_str = p_number + ""
		var _is_negative = false

		if number_str[0] == "-":
			_is_negative = true
			number_str = number_str.substr(1, number_str.length() - 1)
		
		var bn = BigNumber.new()
		for i in number_str:
			bn = bn.multiply_uint(10)
			bn = bn.add_uint(i.to_ascii_buffer()[0] - 48)
		
		bn.is_negative = _is_negative
		
		return bn

	static func from_random(p_bits: int) -> BigNumber:
		var bytes_num = floor(p_bits) / int(BigCat.ATOMIC_BITS)
		
		var scalars = []
		
		for i in range(bytes_num):
			BigNumber.rng.randomize()
			scalars.append(rng.randi_range(0, BigCat.ATOMIC_MAX))

		return BigNumber.new(scalars)

	static func from_random_range(p_min: BigNumber, p_max: BigNumber) -> BigNumber:
		var _range = p_max.subtract(p_min)
		var scalars = []
		
		for i in range(_range.value.size()):
			BigNumber.rng.randomize()
			scalars.append(rng.randi_range(0, BigCat.ATOMIC_MAX))
		
		var result = BigNumber.new(scalars)
		result = result.add(p_min)

		if result.is_greater_than(p_max):
			result = p_max.duplicate()
		
		return result

	static func atomize(p_scalar: int) -> int:
		return p_scalar % BigCat.ATOMIC_MAX

	static func atomize_vector(p_vector: Array) -> Array:
		var result: Array = []
		for i in p_vector:
			result.append(atomize(i))
		return result

	func is_probably_prime(p_witness: int = 2) -> bool:
		if self.is_less_than(BigNumber.TWO):
			return false
		if self.is_less_than(BigNumber.FOUR):
			return true
		if self.is_even():
			return false

		var s = 0
		var d = self.decrement()
		while d.is_even():
			d = d.shift_right_uint(1)
			s += 1

		for i in range(p_witness):
			var a = BigNumber.from_random_range(BigNumber.TWO, self.subtract(BigNumber.TWO))

			assert(not a.is_less_than(BigNumber.TWO) and not a.is_greater_than(self.subtract(BigNumber.TWO)), "Error: Random number is out of range: " + a._to_string() + " (2, " + self.subtract(BigNumber.TWO)._to_string() + ")" )
			
			var x = a.power_modulo(d, self)

			if x.is_equal_to(BigNumber.ONE) or x.is_equal_to(self.subtract(BigNumber.ONE)):
				continue

			var _continue = false
			for j in range(s - 1):
				x = x.power_modulo(BigNumber.TWO, self)
				if x.is_equal_to(BigNumber.ONE):
					return false
				if x.is_equal_to(self.subtract(BigNumber.ONE)):
					_continue = true
					break
			if _continue:
				continue

			return false
		
		return true

	static func generate_prime(p_bits: int, p_witness: int = 2) -> BigNumber:
		assert(p_bits >= BigCat.ATOMIC_BITS, "Error: Bit count must be greater than or equal to " + str(BigCat.ATOMIC_BITS))
		
		var random = RandomNumberGenerator.new()
		var scalars = []
		
		for i in range(floor(p_bits) / BigCat.ATOMIC_BITS):
			scalars.append(random.randi() % BigCat.ATOMIC_MAX)
		
		scalars[scalars.size() - 1] |= 1 << BigCat.ATOMIC_BITS - 1
		scalars[0] |= 1

		var number: BigNumber = BigNumber.new(scalars)

		while true:
			if BigNumber.prime_gen_result:
				return null
			
			if BigCat.IS_VERBOSE:
				print("Trying random number: ", number._to_string())

			if number.is_probably_prime(p_witness):
				if BigNumber.prime_gen_result:
					return null
				
				if BigNumber.prime_gen_threads.size() > 0:
					BigNumber.prime_gen_result = number
				
				return number
			
			number = number.add_uint(2)
		
		return null
	
	static func generate_prime_threaded_f(p_bits: int, p_witness: int = 2, p_num_threads: int = 2) -> void:
		BigNumber.prime_gen_threads = []
		BigNumber.prime_gen_result = null

		var threads_num = p_num_threads

		for i in range(threads_num):
			var thread = Thread.new()
			BigNumber.prime_gen_threads.append(thread)
			thread.start(BigNumber.generate_prime.bind(p_bits, p_witness), Thread.PRIORITY_HIGH)
		
		for i in range(threads_num):
			BigNumber.prime_gen_threads[i].wait_to_finish()
	
	static func generate_prime_threaded(p_bits: int, p_witness: int = 2, p_num_threads: int = 2) -> BigNumber:
		assert(p_bits >= BigCat.ATOMIC_BITS, "Error: Bit count must be greater than or equal to " + str(BigCat.ATOMIC_BITS))

		var thread = Thread.new()
		thread.start(BigNumber.generate_prime_threaded_f.bind(p_bits, p_witness, p_num_threads), Thread.PRIORITY_HIGH)
		thread.wait_to_finish()

		var result = BigNumber.prime_gen_result
		
		BigNumber.prime_gen_threads = []
		BigNumber.prime_gen_result = null

		return result
	
	func duplicate() -> BigNumber:
		var result: BigNumber = BigNumber.new(self.value.duplicate(), self.is_negative)
		return result
	
	func abs() -> BigNumber:
		var result: BigNumber = self.duplicate()
		result.is_negative = false
		return result
	
	func add(p_other: BigNumber) -> BigNumber:
		if self.is_negative and p_other.is_negative:
			var a = self.duplicate()
			var b = p_other.duplicate()

			a.is_negative = false
			b.is_negative = false

			var added = a.add(b)
			added.is_negative = true
			return added
		elif self.is_negative or p_other.is_negative:
			var a = self.duplicate()
			var b = p_other.duplicate()

			var a_is_negative = a.is_negative
			var b_is_negative = b.is_negative

			a.is_negative = false
			b.is_negative = false

			if a.is_greater_than(b):
				var subtracted = a.subtract(b)
				subtracted.is_negative = a_is_negative
				return subtracted
			elif b.is_greater_than(a):
				var subtracted = b.subtract(a)
				subtracted.is_negative = b_is_negative
				return subtracted
			else:
				return BigNumber.from_uint(0)
		
		var result = []
		var carry = 0

		var max_length = max(self.value.size(), p_other.value.size())
		for i in range(max_length):
			var sum = carry
			if i < self.value.size():
				sum += self.value[i]
			if i < p_other.value.size():
				sum += p_other.value[i]

			result.append(sum % BigCat.ATOMIC_MAX)
			carry = sum / BigCat.ATOMIC_MAX

		if carry > 0:
			result.append(carry)

		return BigNumber.new(result)

	func subtract(p_other: BigNumber) -> BigNumber:
		var result: Array
		var _is_negative: bool = false
		var other: BigNumber

		if self.is_negative and p_other.is_negative:
			var a = BigNumber.new(self.value.duplicate())
			var b = BigNumber.new(p_other.value.duplicate())

			a.is_negative = false
			b.is_negative = false

			var subtracted: BigNumber

			if a.is_greater_than(b):
				subtracted = a.subtract(b)
				subtracted.is_negative = true
				return subtracted
			else:
				subtracted = b.subtract(a)
				subtracted.is_negative = false
				return subtracted
		elif self.is_negative:
			var a = BigNumber.new(self.value.duplicate())
			var b = BigNumber.new(p_other.value.duplicate())

			a.is_negative = false
			b.is_negative = false

			var added = a.add(b)
			added.is_negative = true
			return added
		elif p_other.is_negative:
			var a = BigNumber.new(self.value.duplicate())
			var b = BigNumber.new(p_other.value.duplicate())

			a.is_negative = false
			b.is_negative = false

			var added = a.add(b)
			added.is_negative = false
			return added
		
		if self.is_less_than(p_other):
			result = p_other.value.duplicate()
			other = self
			_is_negative = true
		else:
			result = self.value.duplicate()
			other = p_other

		var borrow = 0

		for i in range(result.size()):
			var subtrahend = 0
			if i < other.value.size():
				subtrahend = other.value[i];
			if result[i] < subtrahend + borrow:
				result[i] = result[i] + BigCat.ATOMIC_MAX - subtrahend - borrow
				borrow = 1
			else:
				result[i] = result[i] - subtrahend - borrow
				borrow = 0

		while result.size() > 1 and result[-1] == 0:
			result.resize(result.size() - 1)

		return BigNumber.new(result, _is_negative)
	
	func multiply(p_other: BigNumber) -> BigNumber:
		var _is_negative = self.is_negative != p_other.is_negative

		var other = p_other.duplicate()
		other.is_negative = false

		var smaller
		var larger

		if self.value.size() < other.value.size():
			smaller = self.value.duplicate()
			larger = other.value
		else:
			smaller = other.value
			larger = self.value.duplicate()

		var _value = larger.duplicate()

		var result: BigNumber = BigNumber.from_uint(0)
		var carry = 0

		for i in range(smaller.size()):
			var temp = []
			for j in range(i):
				temp.append(0)
			for j in range(_value.size()):
				var product = smaller[i] * _value[j] + carry
				temp.append(product % BigCat.ATOMIC_MAX)
				carry = product / BigCat.ATOMIC_MAX
			while carry > 0:
				temp.append(carry % BigCat.ATOMIC_MAX)
				carry /= BigCat.ATOMIC_MAX
			result = result.add(BigNumber.new(temp))
		
		result.is_negative = _is_negative
		
		return result
	
	func divide(p_divisor: BigNumber) -> BigNumber:
		var divisor = p_divisor.duplicate()
		var _is_negative = self.is_negative != divisor.is_negative

		divisor.is_negative = false
		
		assert(not divisor.is_zero(), "Error: Division by zero")

		if self.is_less_than(divisor):
			return BigNumber.from_uint(0)

		if self.is_equal_to(divisor):
			return BigNumber.from_uint(1)

		var dividend = self.duplicate()
		dividend.is_negative = false
		var quotient = BigNumber.from_uint(0)

		while not dividend.is_less_than(divisor):
			var temp = divisor
			var multiple = BigNumber.ONE.duplicate()
			while dividend.is_greater_than(temp.shift_left_uint(1)):
				temp = temp.shift_left_uint(1)
				multiple = multiple.shift_left_uint(1)
			dividend = dividend.subtract(temp)
			quotient = quotient.add(multiple)

		if not quotient.is_zero():
			quotient.is_negative = _is_negative

		return quotient
	
	func mutable_increment():
		self.value[0] += 1
		var carry = 0
		for i in range(self.value.size()):
			self.value[i] += carry
			if self.value[i] > BigCat.ATOMIC_MAX:
				self.value[i] -= BigCat.ATOMIC_MAX
				carry = 1
			else:
				carry = 0
		if carry > 0:
			self.value.append(carry)
	
	func mutable_decrement():
		self.value[0] -= 1
		var borrow = 0
		for i in range(self.value.size()):
			self.value[i] -= borrow
			if self.value[i] < 0:
				self.value[i] += BigCat.ATOMIC_MAX
				borrow = 1
			else:
				borrow = 0
		while self.value.size() > 1 and self.value[-1] == 0:
			self.value.resize(self.value.size() - 1)
	
	func increment() -> BigNumber:
		var result: BigNumber = self.duplicate()
		result.mutable_increment()
		return result
	
	func decrement() -> BigNumber:
		var result: BigNumber = self.duplicate()
		result.mutable_decrement()
		return result
	
	func power(p_exponent: BigNumber) -> BigNumber:
		var base: BigNumber = self.duplicate()
		var result: BigNumber = BigNumber.from_uint(1)

		var powers = [base]
		for i in range(1, p_exponent.value.size()):
			powers.append(powers[i - 1].add(powers[i - 1]))

		for i in range(p_exponent.value.size() - 1, -1, -1):
			if p_exponent.value[i] == 1:
				result = result.add(powers[i])

		result.is_negative = self.is_negative and p_exponent.is_odd()

		return result
	
	func mutable_modulo(p_modulus: BigNumber):
		var remainder: BigNumber = BigNumber.from_uint(0)
		var iterations = range((self.value.size() * BigCat.ATOMIC_BITS) - 1, -1, -1)
		
		for i in iterations:
			remainder = remainder.shift_left_uint(1)
			remainder.value[0] |= (self.value[i / BigCat.ATOMIC_BITS] >> (i % BigCat.ATOMIC_BITS)) & 1
			if remainder.compare(p_modulus) >= 0:
				remainder.mutable_subtract(p_modulus)

		self.is_negative = p_modulus.is_negative
		self.value = remainder.value
	
	func modulo(p_modulus: BigNumber) -> BigNumber:
		var other = p_modulus.duplicate()
		other.is_negative = false
		var _is_negative = other.is_negative
		var result: BigNumber = self.duplicate()
		result.is_negative = false
		result.mutable_modulo(other)
		result.is_negative = _is_negative
		return result

	func bit_and(p_other: BigNumber) -> BigNumber:
		var other = p_other.duplicate()
		var result: Array = []

		var max_length = max(self.value.size(), other.value.size())
		for i in range(max_length):
			var anded = 0
			if i < self.value.size():
				anded = self.value[i]
			if i < other.value.size():
				anded &= other.value[i]
			result.append(anded)

		return BigNumber.new(result)
	
	func bit_or(p_other: BigNumber) -> BigNumber:
		var other = p_other.duplicate()
		var result: Array = []

		var max_length = max(self.value.size(), other.value.size())
		for i in range(max_length):
			var ored = 0
			if i < self.value.size():
				ored = self.value[i]
			if i < other.value.size():
				ored |= other.value[i]
			result.append(ored)

		return BigNumber.new(result)

	func bit_xor(p_other: BigNumber) -> BigNumber:
		var other = p_other.duplicate()
		var result: Array = []

		var max_length = max(self.value.size(), other.value.size())
		for i in range(max_length):
			var xored = 0
			if i < self.value.size():
				xored = self.value[i]
			if i < other.value.size():
				xored ^= other.value[i]
			result.append(xored)

		return BigNumber.new(result)

	func and_uint(p_number: int) -> BigNumber:
		return self.bit_and(BigNumber.from_uint(p_number))
	
	func or_uint(p_number: int) -> BigNumber:
		return self.bit_or(BigNumber.from_uint(p_number))

	func shift_left_uint(p_shift: int) -> BigNumber:
		var result: Array = self.value.duplicate()
		var carry = 0
		var temp = 0

		for i in range(result.size()):
			temp = result[i]
			result[i] = (result[i] << p_shift) | carry
			carry = (temp >> (BigCat.ATOMIC_BITS - p_shift)) & BigCat.ATOMIC_MAX_MINUS_ONE

		if carry > 0:
			result.append(carry)

		return BigNumber.new(result)
	
	func shift_left(p_shift: BigNumber) -> BigNumber:
		var result: Array = self.value.duplicate()
		var carry = 0
		var temp = 0
		
		for i in range(result.size()):
			temp = result[i]
			result[i] = (result[i] << p_shift.to_uint()) | carry
			carry = (temp >> (BigCat.ATOMIC_BITS - p_shift.to_uint())) & BigCat.ATOMIC_MAX_MINUS_ONE

		if carry > 0:
			result.append(carry)

		return BigNumber.new(result)
	
	func shift_right_uint(p_shift: int) -> BigNumber:
		var result: Array = self.value.duplicate()
		var carry = 0
		var temp = 0

		for i in range(result.size() - 1, -1, -1):
			temp = result[i]
			result[i] = (result[i] >> p_shift) | carry
			carry = (temp << (BigCat.ATOMIC_BITS - p_shift)) & BigCat.ATOMIC_MAX_MINUS_ONE

		while result.size() > 1 and result[-1] == 0:
			result.resize(result.size() - 1)

		return BigNumber.new(result)

	func shift_right(p_shift: BigNumber) -> BigNumber:
		var result: Array = self.value.duplicate()
		var carry = 0
		var temp = 0

		for i in range(result.size() - 1, -1, -1):
			temp = result[i]
			result[i] = (result[i] >> p_shift.to_uint()) | carry
			carry = (temp << (BigCat.ATOMIC_BITS - p_shift.to_uint())) & BigCat.ATOMIC_MAX_MINUS_ONE

		while result.size() > 1 and result[-1] == 0:
			result.resize(result.size() - 1)

		return BigNumber.new(result)
	
	func mutable_subtract(p_other: BigNumber):
		var borrow = 0
		for i in range(p_other.value.size()):
			var diff = self.value[i] - p_other.value[i] - borrow
			if diff < 0:
				diff += BigCat.ATOMIC_MAX
				borrow = 1
			else:
				borrow = 0
			self.value[i] = diff
		for i in range(p_other.value.size(), self.value.size()):
			if borrow == 0:
				break
			var diff = self.value[i] - borrow
			if diff < 0:
				diff += BigCat.ATOMIC_MAX
				borrow = 1
			else:
				borrow = 0
			self.value[i] = diff
		while self.value.size() > 1 and self.value[-1] == 0:
			self.value.remove_at(self.value.size() - 1)

	func is_zero() -> bool:
		return self.value.size() == 1 and self.value[0] == 0

	func is_even() -> bool:
		return (self.value[0] & 1) == 0
	
	func is_odd() -> bool:
		return (self.value[0] & 1) == 1
	
	func power_modulo(p_exponent: BigNumber, p_modulus: BigNumber) -> BigNumber:
		var result = BigNumber.from_uint(1)
		var base = self.modulo(p_modulus)

		while not p_exponent.is_zero():
			if p_exponent.is_odd():
				result = result.multiply(base).modulo(p_modulus)
			base = base.multiply(base).modulo(p_modulus)
			p_exponent = p_exponent.shift_right_uint(1)

		return result
	
	func prime_inverse_modulo(p_modulus: BigNumber) -> BigNumber:
		var g = self.gcd(p_modulus)
		
		assert(g.is_equal_to(BigNumber.ONE), "Error: " + self._to_string() + " is not invertible")
		
		var mmt = p_modulus.subtract(BigNumber.from_uint(2))
		var inverted = self.power_modulo(mmt, p_modulus)

		return inverted

	func inverse_modulo(p_modulus: BigNumber) -> BigNumber:
		var t = BigNumber.from_uint(0)
		var newt = BigNumber.from_uint(1)

		var r = p_modulus.duplicate()
		var newr = self.duplicate()

		while not newr.is_zero():
			var quotient = r.divide(newr)
			
			var temp = newt.duplicate()
			newt = t.subtract(quotient.multiply(newt))
			t = temp
			
			temp = newr.duplicate()
			newr = r.subtract(quotient.multiply(newr))
			r = temp
		
		assert(r.is_equal_to(BigNumber.ONE), "Error: " + self._to_string() + " is not invertible")
		
		if t.is_negative:
			t = t.add(p_modulus)
		
		return t
	
	func compare(p_other: BigNumber) -> int:
		if self.is_negative and not p_other.is_negative:
			return -1
		elif not self.is_negative and p_other.is_negative:
			return 1
		elif self.is_negative and p_other.is_negative:
			var a = self.duplicate()
			var b = p_other.duplicate()
			a.is_negative = false
			b.is_negative = false
			return a.compare(b) * -1

		if self.value.size() > p_other.value.size():
			return 1
		elif self.value.size() < p_other.value.size():
			return -1
		else:
			for i in range(self.value.size() - 1, -1, -1):
				if self.value[i] > p_other.value[i]:
					return 1
				elif self.value[i] < p_other.value[i]:
					return -1
			return 0
	
	func is_greater_than(p_other: BigNumber) -> bool:
		return self.compare(p_other) == 1
	
	func is_less_than(p_other: BigNumber) -> bool:
		return self.compare(p_other) == -1

	func is_equal_to(p_other: BigNumber) -> bool:
		return self.compare(p_other) == 0
	
	func is_greater_than_or_equal_to(p_other: BigNumber) -> bool:
		return self.compare(p_other) >= 0
	
	func is_less_than_or_equal_to(p_other: BigNumber) -> bool:
		return self.compare(p_other) <= 0
	
	func gcd(p_other: BigNumber) -> BigNumber:
		var a: BigNumber = self
		var b: BigNumber = p_other
		
		while not a.is_zero():
			var t = a
			a = b.modulo(a)
			b = t
		
		return b

	func add_int(p_number: int) -> BigNumber:
		var number = abs(p_number)
		var bn = BigNumber.from_uint(number)
		bn.is_negative = p_number < 0
		return self.add(bn)

	func add_uint(p_number: int) -> BigNumber:
		return self.add(BigNumber.from_uint(p_number))
	
	func subtract_int(p_number: int) -> BigNumber:
		var number = abs(p_number)
		var bn = BigNumber.from_uint(number)
		bn.is_negative = p_number < 0
		return self.subtract(bn)

	func subtract_uint(p_number: int) -> BigNumber:
		return self.subtract(BigNumber.from_uint(p_number))
	
	func multiply_int(p_number: int) -> BigNumber:
		var number = abs(p_number)
		var bn = BigNumber.from_uint(number)
		bn.is_negative = p_number < 0
		return self.multiply(bn)
	
	func multiply_uint(p_number: int) -> BigNumber:
		return self.multiply(BigNumber.from_uint(p_number))
	
	func divide_int(p_number: int) -> BigNumber:
		var number = abs(p_number)
		var bn = BigNumber.from_uint(number)
		bn.is_negative = p_number < 0
		return self.divide(bn)
	
	func divide_uint(p_number: int) -> BigNumber:
		return self.divide(BigNumber.from_uint(p_number))
	
	func to_uint() -> int:
		var result = 0
		for i in range(self.value.size() - 1, -1, -1):
			result = result * BigCat.ATOMIC_MAX + self.value[i]

		if self.is_negative:
			result *= 2
			result += 1

		return result

	func to_int() -> int:
		var result = 0
		for i in range(self.value.size() - 1, -1, -1):
			result = result * BigCat.ATOMIC_MAX + self.value[i]

		if self.is_negative:
			result *= -1

		return result

	func _to_string() -> String:
		var result: Array = []
		var number: Array = self.value.duplicate()

		while number.size() > 0:
			var remainder = 0
			for i in range(number.size() - 1, -1, -1):
				var temp = remainder * BigCat.ATOMIC_MAX + number[i]
				number[i] = temp / 10
				remainder = temp % 10

			while number.size() > 0 and number[number.size() - 1] == 0:
				number.remove_at(number.size() - 1)

			result.append(remainder)

		if result.size() == 0:
			return "0"

		var str_result: String = ""
		for i in range(result.size() - 1, -1, -1):
			str_result += str(result[i])

		if self.is_negative:
			str_result = "-" + str_result

		return str_result
