extends Control

func test_int_conversion():
	var a = BigCat.BigNumber.from_uint(355841233)
	assert(a.to_uint() == 355841233, "test_int_conversion failed!")
	print("Int conversion test passed!")

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
	assert(sum.to_uint() == native_sum, "test_big_and_uint failed: " + str(p_uint) + " " + str(q_uint) + " " + str(sum.to_uint()) + " " + str(native_sum))
	
	var minus = p.subtract(q)
	var native_minus = p_uint - q_uint
	assert(minus.to_uint() == native_minus, "test_big_and_uint failed: " + str(p_uint) + " " + str(q_uint) + " " + str(minus.to_uint()) + " " + str(native_minus))
	
	var product = p.multiply(q)
	var native_product = p_uint * q_uint
	assert(product.to_uint() == native_product, "test_big_and_uint failed: " + str(p_uint) + " " + str(q_uint) + " " + str(product.to_uint()) + " " + str(native_product))
	
	var divided = p.divide(q)
	var native_divided = floor(p_uint) / q_uint
	assert(divided.to_uint() == native_divided, "test_big_and_uint failed: " + str(p_uint) + " " + str(q_uint) + " " + str(divided.to_uint()) + " " + str(native_divided))
	
	var result = sum.to_uint() == native_sum and \
				 minus.to_uint() == native_minus and \
				 product.to_uint() == native_product and \
				 divided.to_uint() == native_divided

	assert(result, "test_big_and_uint failed: " + str(p_uint) + " " + str(q_uint) + " " + str(sum.to_uint()) + " " + str(native_sum) + " " + str(minus.to_uint()) + " " + str(native_minus) + " " + str(product.to_uint()) + " " + str(native_product) + " " + str(divided.to_uint()) + " " + str(native_divided))

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
		
		assert(result.is_equal_to(BigCat.BigNumber.from_uint(expected)), "test_modulo failed: " + str(result.to_uint()) + " != " + str(expected))
		assert(result.to_uint() == expected, "test_modulo failed: " + str(result.to_uint()) + " != " + str(expected))

	print("All modulo tests passed!")

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
			print("test_power_modulo: ", i, " failed: ", result.to_uint(), " != ", expected)
		
		assert(result.is_equal_to( BigCat.BigNumber.from_uint(expected)))

	print("All power modulo tests passed!")

func test_rsa():
	print("Testing RSA... (This may take long time because BigCat is not a cheetah.)")

	var p = BigCat.BigNumber.generate_prime_threaded(128, 2, 4)
	var q = BigCat.BigNumber.generate_prime_threaded(128, 2, 4)
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

	assert(big.is_equal_to(decrypted), "RSA test failed!")
	assert(big.to_chars() == decrypted.to_chars(), "RSA test failed!")

	print("RSA test passed!")

func _ready():
	test_int_conversion()
	test_byte_conversion()
	test_four_operations()
	test_modulo()
	test_power_modulo()
	test_rsa()
