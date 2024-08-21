extends Control

func test_int_conversion():
	var rng = RandomNumberGenerator.new()
	
	for i in range(0, 100):
		var num = rng.randi_range(1, 9000000000)
		var big = BigCat.BigNumber.from_uint(num)
		assert(big.to_uint() == num, "test_int_conversion() failed! " + str(big.to_uint()) + " != " + str(num))
	
	print("Int conversion test passed!")

func test_string_conversion():
	var rng = RandomNumberGenerator.new()
	
	for i in range(0, 100):
		var num = rng.randi_range(1, 9000000000)
		var big = BigCat.BigNumber.from_string(str(num))
		assert(str(big) == str(num), "test_string_conversion() failed! " + str(big) + " != " + str(num))
	
	print("String conversion test passed!")

func test_hex_conversion():
	var rng = RandomNumberGenerator.new()

	for i in range(0, 100):
		var num = rng.randi_range(1, 9000000000)
		var big = BigCat.BigNumber.from_uint(num)
		var hex = big.to_hex()
		var from_hex = BigCat.BigNumber.from_hex(hex)
		assert(from_hex.to_uint() == num, "test_hex_conversion() failed! " + str(from_hex.to_uint()) + " != " + str(num))
	
	print("Hex conversion test passed!")

func test_byte_conversion():
	var bytes = [0, 2, 4, 0]
	var b1 = BigCat.BigNumber.from_bytes(bytes)
	var b2 = BigCat.BigNumber.from_bytes(b1.to_bytes())
	assert(b1.is_equal_to(b2), "Byte vector conversion test failed!")
	print("Byte vector conversion test passed!")

func test_big_and_uint(p_uint: int, q_uint: int):
	if q_uint > p_uint:
		var temp = p_uint
		p_uint = q_uint
		q_uint = temp
	
	var p: BigCat.BigNumber
	var q: BigCat.BigNumber

	p = BigCat.BigNumber.from_uint(p_uint)
	q = BigCat.BigNumber.from_uint(q_uint)
	
	var sum = p.add(q)
	var native_sum = p_uint + q_uint
	assert(sum.to_uint() == native_sum, "test_big_and_uint() failed: " + str(p_uint) + " " + str(q_uint) + " " + str(sum.to_uint()) + " " + str(native_sum))
	
	var minus = p.subtract(q)
	var native_minus = p_uint - q_uint
	assert(minus.to_uint() == native_minus, "test_big_and_uint() failed: " + str(p_uint) + " " + str(q_uint) + " " + str(minus.to_uint()) + " " + str(native_minus))
	
	var product = p.multiply(q)
	var native_product = p_uint * q_uint
	assert(product.to_uint() == native_product, "test_big_and_uint() failed: " + str(p_uint) + " " + str(q_uint) + " " + str(product.to_uint()) + " " + str(native_product))
	
	var divided = p.divide(q)
	var native_divided = floor(p_uint) / q_uint
	assert(divided.to_uint() == native_divided, "test_big_and_uint() failed: " + str(p_uint) + " " + str(q_uint) + " " + str(divided.to_uint()) + " " + str(native_divided))
	
	var result = sum.to_uint() == native_sum and \
				 minus.to_uint() == native_minus and \
				 product.to_uint() == native_product and \
				 divided.to_uint() == native_divided

	assert(result, "test_big_and_uint() failed: " + str(p_uint) + " " + str(q_uint) + " " + str(sum.to_uint()) + " " + str(native_sum) + " " + str(minus.to_uint()) + " " + str(native_minus) + " " + str(product.to_uint()) + " " + str(native_product) + " " + str(divided.to_uint()) + " " + str(native_divided))

	return result

func test_four_operations():
	var p
	var q

	var random = RandomNumberGenerator.new()

	for i in range(0, 1000):
		p = random.randi_range(1, 1000000)
		q = random.randi_range(1, 1000000)

		test_big_and_uint(p, q)
	
	print("All four operations tests passed!")

func test_power():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(10):
		var an = rng.randi_range(1, 12)
		var bn = rng.randi_range(1, 12)
		var a = BigCat.BigNumber.from_uint(an)
		var b = BigCat.BigNumber.from_uint(bn)
		var result = a.power(b)
		var expected = pow(an, bn)
		
		assert(result.is_equal_to(BigCat.BigNumber.from_uint(expected)), "test_power() failed: " + str(result.to_uint()) + " != " + str(expected))
		assert(result.to_uint() == expected, "test_power() failed: " + str(result.to_uint()) + " != " + str(expected))

	print("All power tests passed!")

func test_modulo():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(10):
		var an = rng.randi_range(1, 1000000)
		var bn = rng.randi_range(1, 1000000)
		var a = BigCat.BigNumber.from_uint(an)
		var b = BigCat.BigNumber.from_uint(bn)
		var result = a.modulo(b)
		var expected = an % bn
		
		assert(result.is_equal_to(BigCat.BigNumber.from_uint(expected)), "test_modulo() failed: " + str(result.to_uint()) + " != " + str(expected))
		assert(result.to_uint() == expected, "test_modulo() failed: " + str(result.to_uint()) + " != " + str(expected))

	print("All modulo tests passed!")

func test_sqrt():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(10):
		var an = rng.randi_range(1, 1000000)
		var a = BigCat.BigNumber.from_uint(an)
		var result = a.sqrt()
		var expected = int(sqrt(an))
		
		assert(result.is_equal_to(BigCat.BigNumber.from_uint(expected)), "test_sqrt() failed: " + str(result.to_uint()) + " != " + str(expected))
		assert(result.to_uint() == expected, "test_sqrt() failed: " + str(result.to_uint()) + " != " + str(expected))

	print("All sqrt tests passed!")

func power_modulo(base: int, exponent: int, modulus: int) -> int:
	if modulus == 1:
		return 0
	var result = 1
	base = base % modulus

	while exponent > 0:
		if exponent % 2 == 1:
			result = (result * base) % modulus

		exponent = exponent >> 1
		base = base * base
		base = base % modulus

	return result

func test_power_modulo():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(10):
		var an = rng.randi_range(1, 1000000)
		var bn = rng.randi_range(1, 1000000)
		var cn = rng.randi_range(1, 1000000)

		var base = BigCat.BigNumber.from_uint(an)
		var exponent = BigCat.BigNumber.from_uint(bn)
		var mod = BigCat.BigNumber.from_uint(cn)
		var result = base.power_modulo(exponent, mod)
		var expected = power_modulo(an, bn, cn)
		
		if result.to_uint() != expected:
			print("test_power_modulo(): ", i, " failed: ", result.to_uint(), " != ", expected)
		
		assert(result.is_equal_to( BigCat.BigNumber.from_uint(expected)))

	print("All power modulo tests passed!")

func test_rsa():
	print("Testing RSA... (This may take long time because BigCat is not a cheetah.)")

	var p = BigCat.BigNumber.generate_prime(128)
	var q = BigCat.BigNumber.generate_prime(128)
	var n = p.multiply(q)
	var phi = p.subtract(BigCat.BigNumber.from_int(1)).multiply(q.subtract(BigCat.BigNumber.from_int(1)))
	var e = BigCat.BigNumber.from_int(65537)
	var d = e.inverse_modulo(phi)

	print("p: \t\t\t", str(p))
	print("q: \t\t\t", str(q))

	print("Public Key: \t\t(", str(e), ", ", str(n), ")")
	print("Private Key: \t\t(", str(d), ", ", str(n), ")")

	var message = "Hello, World!"
	var big = BigCat.BigNumber.from_chars(message.to_ascii_buffer())
	var encrypted = big.power_modulo(e, n)
	var decrypted = encrypted.power_modulo(d, n)

	print("Encrypted Scalar: \t", str(encrypted))
	print("Original Scalar: \t", str(big))
	print("Decrypted Scalar: \t", str(decrypted))

	assert(big.is_equal_to(decrypted), "test_rsa() failed! big != decrypted")
	assert(big.to_chars() == decrypted.to_chars(), "test_rsa() failed! big.to_chars() != decrypted.to_chars()")

	print("RSA test passed!")

func test_aa_notation():
	const expect_postfix := [
		"k", "m", "b", "t", 
		"aa", "ab", "ac", "ad", "ae", "af", 
		"ag", "ah", "ai", "aj", "ak", "al", 
		"am", "an", "ao", "ap", "aq", "ar",
		"as", "at", "au", "av", "aw", "ax",
		"ay", "az", "ba", "bb", "bc", "bd"
	]
	
	var thousands := 3
	for postfix in expect_postfix:
		var big = BigCat.BigNumber.from_int(10)
		big = big.power_uint(thousands)
		var res_postfix := big.to_aa_notation(0).substr(1)
		assert(postfix == res_postfix)
		thousands += 3
	

func _ready():
	test_int_conversion()
	test_string_conversion()
	test_hex_conversion()
	test_byte_conversion()
	test_four_operations()
	test_power()
	test_modulo()
	test_sqrt()
	test_power_modulo()
	test_rsa()
	test_aa_notation()
