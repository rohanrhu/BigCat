# BigCat, Big Numbers for Godot Engine

Meow... BigCat is a big number library for Godot Engine / GDScript.

![BigCat, Big number library for Godot Engine](media/BigCat.jpeg)

## Features

* Infinitely long numbers
* Dynamically adjustable atomic scalar (`BigCat.ATOMIC_BITS`, `BigCat.set_atomic_bits(bits)`)
* Conversions:
  * Conversions between byte arrays and big numbers
  * Conversions between signed char arrays and big numbers (It still doesn't guarantee to give the original ASCII strings.)
  * Conversions between strings and big numbers
  * Conversions between big numbers and integers
* Arithmetic Operations (addition, subtraction, multiplication, division)
* Comparison Operations (less than, greater than, equal to)
* Modular Arithmetic
* Random Number Generation
* Cryptographic Requirements:
  * Modular Exponentiation
  * Modular Multiplicative Inverse
  * Primality Test
  * Random Prime Generation
  * Dumb Multi-Threaded Prime Generation

## Limitations

I tried to make it fast and efficient as much as possible... But it is slow for random prime generation for big numbers (actually because of the primality test). I'll try to improve it in the future.

However, 128-bit random prime generation is taking an "acceptable" time, for 256-bit it is slower but still acceptable. For more, it is being more and more slower.

## Installation

Clone BigCat repository into your project directory and you'll have the `BigCat` module.

## Usage

`BigCat.BigNumber` is the main class that you'll be using. Here's a simple example:

```gdscript
extends Node

func _ready():
    var a = BigCat.BigNumber.from_uint(812387138271)
    var b = BigCat.BigNumber.from_string("091283091823908109238109382091823091")
    var c = a.add(b)
    print(str(c))

```

## Examples

### 256-bit Prime Generation

Even 256-bit primes take so long time to generate but it is still acceptable. 128-bit is more acceptable.

Single-threaded:

```gdscript
extends Node

func _ready():
    var prime = BigCat.BigNumber.generate_prime(256)
    print("Prime: ", str(prime))
```

Multi-threaded:

```gdscript
extends Node

func _ready():
    var prime = BigCat.BigNumber.generate_prime_threaded(256, 2, 4)
    print("Prime: ", str(prime))
```

### RSA Implementation

BigCat is doing things... But it is not a cheetah and always be careful with cryptographic implementations for critical data and purposes!

#### Encrypting and Decrypting a message

```gdscript
extends Node

func _ready():
    BigCat.BigNumber.IS_VERBOSE = true

    print("Generating RSA key pair...")

    var bits = 128
    var witness = 2
    var num_threads = 4

    var p = BigCat.BigNumber.generate_prime_threaded(bits, witness, num_threads)
    var q = BigCat.BigNumber.generate_prime_threaded(bits, witness, num_threads)
    var n = p.multiply(q)
    var phi = p.subtract(BigCat.BigNumber.from_int(1)).multiply(q.subtract(BigCat.BigNumber.from_int(1)))
    var e = BigCat.BigNumber.from_int(65537)
    var d = e.inverse_modulo(phi)

    print("Public Key: (" + str(e) + ", " + str(n) + ")")
    print("Private Key: (" + str(d) + ", " + str(n) + ")")

    print("Encrypting and Decrypting a message...")

    var message = "Hello, World!"
    var big = BigCat.BigNumber.from_chars(message.to_ascii_buffer())
    var encrypted = big.power_modulo(e, n)
    var decrypted = encrypted.power_modulo(d, n)

    print("Original Scalar: \t", str(big))
    print("Encrypted Scalar: \t", str(encrypted))
    print("Decrypted Scalar: \t", str(decrypted))
```

## `BigCat.BigNumber` API

### Constants

#### `BigNumber.ATOMIC_BITS: int`, `BigCat.set_atomic_bits(p_bits)`

The number of bits in the atomic scalar. Default is `30`.

> [!WARNING]
> Always use `BigCat.set_atomic_bits(bits)` to set this. It will re-calculate other atomic values too.

```gdscript
# Set the atomic bits to 8
BigNumber.set_atomic_bits(8)
# Set the atomic bits to 30 (default and maximum)
BigNumber.set_atomic_bits(30)
```

> [!WARNING]
> `2^30 = 1073741824` scalars, because more than that overflows the integer limit during scalar operations.
> All atomic scalar operations that BigCat does are done with 30-bit integers.
> It doesn't do something like `scalar1 ^ scalar2`, so there is no a logarithmic crazy result that can overflow the integer limit, so 30-bit scalars it won't overflow the integer limit.
> (Godot Engine rolls over from zero when the integer limit is exceeded.)
> (I have an idea to avoid this, but I think it would not increase the performance for some reasons like it will mostly overflow for most of scalar operations.)

#### `BigNumber.IS_VERBOSE: bool`

Enables/disables verbose outputs. (Default is `false`.)

### Constructors

#### `BigNumber.new(value: int) -> BigNumber`

Creates a new `BigNumber` object with the given scalar array.

#### `BigNumber.from_bytes(bytes: PackedByteArray) -> BigNumber`

Creates a new `BigNumber` object from the given byte array.

#### `BigNumber.from_chars(chars: PackedStringArray) -> BigNumber`

Creates a new `BigNumber` object from the given signed `char` array.

#### `BigNumber.from_string(value: String) -> BigNumber`

Creates a new `BigNumber` object from the given string.

#### `BigNumber.from_uint(value: int) -> BigNumber`

Creates a new `BigNumber` object from the given unsigned integer.

#### `BigNumber.from_int(value: int) -> BigNumber`

Creates a new `BigNumber` object from the given signed integer.

### Properties

#### `BigNumber.value: Array`

Returns the scalar array of the `BigNumber` object.

#### `BigNumber.is_negative: bool`

`true` if the `BigNumber` object is negative, `false` if not.

#### `BigNumber.bytes: PackedByteArray`

Byte representation of the `BigNumber` object.

#### `BigNumber.chars: PackedStringArray`

Signed `char` representation of the `BigNumber` object.

#### `BigNumber.string: String`

String representation of the `BigNumber` object.

### Methods

Conversion Operations:

#### `BigNumber.to_bytes() -> PackedByteArray`

Returns the byte array representation of the `BigNumber` object.

#### `BigNumber.to_chars() -> PackedStringArray`

Returns the signed `char` array representation of the `BigNumber` object.

#### `BigNumber.to_string() -> String`

Returns the string representation of the `BigNumber` object. You can do `str(big_number)` too.

#### `BigNumber.to_int() -> int`

Returns the integer representation of the `BigNumber` object.

#### `BigNumber.to_uint() -> int`

Returns the unsigned integer representation of the `BigNumber` object.

Arithmetic Operations:

#### `BigNumber.add(p_other: BigNumber) -> BigNumber`

Returns the sum of the `BigNumber` object and the given `BigNumber` object.

#### `BigNumber.add_uint(p_other: int) -> BigNumber`

Returns the sum of the `BigNumber` object and the given number.

#### `BigNumber.add_int(p_other: int) -> BigNumber`

Returns the sum of the `BigNumber` object and the given number.

#### `BigNumber.subtract(p_other: BigNumber) -> BigNumber`

Returns the difference between the `BigNumber` object and the given `BigNumber` object.

#### `BigNumber.subtract_uint(p_other: int) -> BigNumber`

Returns the difference between the `BigNumber` object and the given number.

#### `BigNumber.subtract_int(p_other: int) -> BigNumber`

Returns the difference between the `BigNumber` object and the given number.

#### `BigNumber.multiply(p_other: BigNumber) -> BigNumber`

Returns the product of the `BigNumber` object and the given `BigNumber` object.

#### `BigNumber.multiply_uint(p_other: int) -> BigNumber`

Returns the product of the `BigNumber` object and the given number.

#### `BigNumber.multiply_int(p_other: int) -> BigNumber`

Returns the product of the `BigNumber` object and the given number.

#### `BigNumber.divide(p_other: BigNumber) -> BigNumber`

Returns the quotient of the `BigNumber` object and the given `BigNumber` object.

#### `BigNumber.divide_uint(p_other: int) -> BigNumber`

Returns the quotient of the `BigNumber` object and the given number.

#### `BigNumber.divide_int(p_other: int) -> BigNumber`

Returns the quotient of the `BigNumber` object and the given number.

#### `BigNumber.power(p_exponent: BigNumber) -> BigNumber`

Returns the power of the `BigNumber` object with the given `BigNumber` object.

#### `BigNumber.power_uint(p_exponent: int) -> BigNumber`

Returns the power of the `BigNumber` object with the given number.

Comparison Operations:

#### `BigNumber.is_less_than(p_other: BigNumber) -> bool`

`true` if the `BigNumber` object is less than the given `BigNumber` object, `false` if not.

#### `BigNumber.is_greater_than(p_other: BigNumber) -> bool`

`true` if the `BigNumber` object is greater than the given `BigNumber` object, `false` if not.

#### `BigNumber.is_equal_to(p_other: BigNumber) -> bool`

`true` if the `BigNumber` object is equal to the given `BigNumber` object, `false` if not.

#### `BigNumber.is_greater_than_or_equal_to(p_other: BigNumber) -> bool`

`true` if the `BigNumber` object is greater than or equal to the given `BigNumber` object, `false` if not.

#### `BigNumber.is_less_than_or_equal_to(p_other: BigNumber) -> bool`

`true` if the `BigNumber` object is less than or equal to the given `BigNumber` object, `false` if not.

Modular Arithmetic:

#### `BigNumber.modulo(p_modulus: BigNumber) -> BigNumber`

Returns the remainder of the `BigNumber` object divided by the given `BigNumber` object.

#### `BigNumber.gcd(p_other: BigNumber) -> BigNumber`

Returns the greatest common divisor of the `BigNumber` object and the given `BigNumber` object.

Cryptophic Requirements:

#### `BigNumber.power_modulo(p_exponent: BigNumber, p_modulus: BigNumber) -> BigNumber`

Returns the modular exponentiation of the `BigNumber` object with the given exponent and modulus.

#### `BigNumber.inverse_modulo(p_modulus: BigNumber) -> BigNumber`

Returns the modular multiplicative inverse of the `BigNumber` object with the given modulus.

#### `BigNumber.prime_inverse_modulo(p_modulus: BigNumber) -> BigNumber`

Faster inverse modulo for prime numbers.

Random Number Generation:

#### `static` `BigNumber.from_frandom(p_bits: int) -> BigNumber`

Returns a random `BigNumber` object with the given number of bits.

#### `static` `BigNumber.from_random_range(p_min: BigNumber, p_max: BigNumber) -> BigNumber`

Returns a random `BigNumber` object within the given range.

#### `static` `BigNumber.generate_prime(p_bits: int, p_witness = 2) -> BigNumber`

Returns a random prime `BigNumber` object with the given number of bits with the given witness.

#### `static` `BigNumber.generate_prime_threaded(p_bits: int, p_witness = 2, p_num_threads = 2) -> BigNumber`

Multi-threaded version of `BigNumber.generate_prime()`. Spawns `p_num_threads` threads and returns the first prime number found.

#### `static` `BigNumber.is_probably_prime(p_witness: int = 2) -> bool`

`true` if the `BigNumber` object is probably prime with the given witness, `false` if not.

### Bitwise Operations

#### `BigNumber.bit_and(p_other: BigNumber) -> BigNumber`

Returns the bitwise AND of the `BigNumber` object and the given `BigNumber` object.

#### `BigNumber.bit_or(p_other: BigNumber) -> BigNumber`

Returns the bitwise OR of the `BigNumber` object and the given `BigNumber` object.

#### `BigNumber.bit_xor(p_other: BigNumber) -> BigNumber`

Returns the bitwise XOR of the `BigNumber` object and the given `BigNumber` object.

#### `BigNumber.shift_left(p_bits: BigNumber) -> BigNumber`

Returns the `BigNumber` object shifted left by the given `BigNumber` object.

#### `BigNumber.shift_right(p_bits: BigNumber) -> BigNumber`

Returns the `BigNumber` object shifted right by the given `BigNumber` object.

#### `BigNumber.shift_left_uint(p_bits: int) -> BigNumber`

Returns the `BigNumber` object shifted left by the given number of bits.

#### `BigNumber.shift_right_uint(p_bits: int) -> BigNumber`

Returns the `BigNumber` object shifted right by the given number of bits.

### Miscellaneous

#### `BigNumber.is_odd() -> bool`

`true` if the `BigNumber` object is odd, `false` if not.

#### `BigNumber.is_even() -> bool`

`true` if the `BigNumber` object is even, `false` if not.

#### `BigNumber.is_zero() -> bool`

`true` if the `BigNumber` object is zero, `false` if not.

## 🎊 Contributing

You can contribute with commiting to project or developing a plugin. All commits are welcome.

You can find me on [Discord](https://discord.gg/RyVY9MtB4S) and [Patreon](https://patreon.com/evrenselkisilik).

## ❤️ Donate

### Patreon

[![Support me on Patreon](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-patreon.vercel.app%2Fapi%3Fusername%3DEvrenselKisilik%26type%3Dpatrons&style=for-the-badge)](https://patreon.com/EvrenselKisilik)

Currencies:

| Currency | Address                                    |
| -------- | ------------------------------------------ |
| BTC      | bc1qhvlc762kwuzeawedl9a8z0duhs8449nwwc35e2 |
| ETH      | 0x1D99B2a2D85C34d478dD8519792e82B18f861974 |
| USDT     | 0x1D99B2a2D85C34d478dD8519792e82B18f861974 |
| USDC     | 0x1D99B2a2D85C34d478dD8519792e82B18f861974 |
| XMR      | 88qvS4sfUnLZ7nehFrz3PG1pWovvEgprcUhkmVLaiL8PVAFgfHjspjKPLhWLj3DUcm92rwNQENbJ1ZbvESdukWvh3epBUty |

## License

Copyright (c) 2024, Oğuzhan Eroğlu <meowingcate@gmail.com> (<https://github.com/rohanrhu>)

BigCat is licensed under the MIT License. See LICENSE file for more information.
