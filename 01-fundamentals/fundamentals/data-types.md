# Data Types and Type System

## Overview

Swift's type system is a cornerstone of the language. Understanding how types work, from primitives to complex generics, is essential for writing safe and efficient Swift code.

## Main Topics

- [Type Basics](#type-basics) - Swift type system fundamentals
- [Numeric Types](#numeric-types) - Integers and floating-point numbers
- [String and Character](#string-and-character) - Text handling
- [Collections](#collections) - Arrays, Sets, Dictionaries
- [Type Aliases](#type-aliases) - Creating type shortcuts
- [Type Checking and Casting](#type-checking-and-casting) - Runtime type operations
- [Generic Types](#generic-types) - Reusable code with type parameters
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Types](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types)
- [Type Safety and Type Inference](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/basics/)

---

## Type Basics

### Type Safety

Swift enforces **type safety** at compile time:

```swift
// Type safety prevents errors
let number: Int = 42
// number = "hello"  // ❌ Compile error - cannot assign String to Int

// Type inference
let inferredInt = 42              // SwiftInfers Int
let inferredString = "hello"      // Swift infers String
let inferredArray = [1, 2, 3]     // Swift infers [Int]

// Explicit type annotation
let explicitInt: Int = 42
let explicitString: String = "hello"
let explicitArray: [Int] = [1, 2, 3]
```

### Type Comparison

```swift
// is operator for type checking
let value: Any = "hello"
if value is String {
    print("It's a string")
}

// as operator for type casting
if let stringValue = value as? String {
    print("Successfully cast to string: \(stringValue)")
}

// Forced cast (risky)
let forcedString = value as! String  // Crashes if wrong type
```

---

## Numeric Types

### Integer Types

```swift
// Signed integers (can be positive or negative)
let int8: Int8 = 127              // Range: -128 to 127
let int16: Int16 = 32767          // Range: -32768 to 32767
let int32: Int32 = 2147483647     // Large range
let int64: Int64 = 9223372036854775807  // Very large range

// Unsigned integers (only positive)
let uint8: UInt8 = 255            // Range: 0 to 255
let uint16: UInt16 = 65535        // Range: 0 to 65535
let uint32: UInt32 = 4294967295   // Large range
let uint64: UInt64 = 18446744073709551615  // Very large range

// Platform-specific Int
let platformInt: Int = 42         // 32-bit on 32-bit platforms, 64-bit on 64-bit
```

**When to use:**
- Use `Int` unless you have a specific reason to use a fixed size
- Use `UInt` only when you specifically need unsigned values
- Use sized integers when interoperating with C code

### Floating-Point Types

```swift
// Float (32-bit, less precise)
let floatValue: Float = 3.14      // Precision: ~6 decimal digits

// Double (64-bit, more precise)
let doubleValue: Double = 3.14159 // Precision: ~15 decimal digits

// Always prefer Double unless memory is critical
let pi: Double = 3.14159265359

// Float arithmetic
let floatResult = floatValue + 2.0   // Float + result is Float
let doubleResult: Double = 3.14 + 2.71  // Precision: better

// Special values
let infinity = Double.infinity
let negativeInfinity = -Double.infinity
let nan = Double.nan  // Not a Number

// Checking special values
if infinity.isInfinite {
    print("Value is infinite")
}
```

---

## String and Character

### String Basics

```swift
// String declaration
let greeting = "Hello, Swift!"
let multilineString = """
    This is a
    multiline string
    """

// String interpolation
let name = "Alice"
let age = 30
let message = "My name is \(name) and I'm \(age) years old"

// String manipulation
let str = "  hello world  "
let trimmed = str.trimmingCharacters(in: .whitespaces)  // "hello world"
let uppercase = str.uppercased()                         // "  HELLO WORLD  "
let lowercase = str.lowercased()                         // "  hello world  "

// Checking string properties
let isEmpty = greeting.isEmpty      // false
let count = greeting.count          // 13 (character count, not byte count)
let contains = greeting.contains("Swift")  // true
```

### Character Type

```swift
// Character vs String
let char: Character = "A"
let string: String = "A"

// Iterating through characters
let word = "Swift"
for character in word {
    print(character)
}
// Prints: S, w, i, f, t

// Character properties
let letter: Character = "é"
let isLetter = letter.isLetter      // true
let isNumber = letter.isNumber      // false
```

---

## Collections

### Arrays

```swift
// Array declaration
let numbers: [Int] = [1, 2, 3, 4, 5]
let fruits = ["apple", "banana", "orange"]  // Type inferred: [String]
var emptyArray: [String] = []

// Array operations
var mutableNumbers = [1, 2, 3]
mutableNumbers.append(4)                    // [1, 2, 3, 4]
mutableNumbers.insert(0, at: 0)             // [0, 1, 2, 3, 4]
let removed = mutableNumbers.remove(at: 2)  // [0, 1, 3, 4], removed: 2

// Accessing elements
let first = numbers[0]              // 1
let last = numbers.last             // Optional: 5
let count = numbers.count           // 5

// Array methods
let doubled = numbers.map { $0 * 2 }           // [2, 4, 6, 8, 10]
let evens = numbers.filter { $0 % 2 == 0 }    // [2, 4]
let sum = numbers.reduce(0) { $0 + $1 }       // 15

// Iterating
for (index, number) in numbers.enumerated() {
    print("Index \(index): \(number)")
}
```

### Sets

```swift
// Set declaration (unordered, unique values)
let uniqueNumbers: Set<Int> = [1, 2, 3, 2, 1]  // {1, 2, 3}
let colors: Set = ["red", "blue", "red"]        // {"red", "blue"}

// Set operations
var set1: Set = [1, 2, 3]
var set2: Set = [2, 3, 4]

let union = set1.union(set2)              // {1, 2, 3, 4}
let intersection = set1.intersection(set2) // {2, 3}
let difference = set1.subtracting(set2)    // {1}

// Set membership
let contains = set1.contains(2)            // true
let isSubset = Set([2, 3]).isSubset(of: set1)  // true
```

### Dictionaries

```swift
// Dictionary declaration
let ages: [String: Int] = ["Alice": 30, "Bob": 25, "Carol": 35]
let capitals = ["USA": "Washington", "France": "Paris"]  // [String: String]

// Accessing values
let aliceAge = ages["Alice"]             // Optional(30)
let aliceAgeOrDefault = ages["Alice"] ?? 0  // 30
let unknownAge = ages["David"] ?? 0      // 0 (not in dict)

// Modifying dictionaries
var mutableAges = ["Alice": 30, "Bob": 25]
mutableAges["Alice"] = 31                // Update value
mutableAges["Carol"] = 35                // Add new key-value

// Dictionary properties
let keys = Array(ages.keys)              // ["Alice", "Bob", "Carol"]
let values = Array(ages.values)          // [30, 25, 35]
let isEmpty = mutableAges.isEmpty        // false
let count = mutableAges.count            // 3

// Iterating
for (name, age) in ages {
    print("\(name) is \(age)")
}
```

---

## Type Aliases

Type aliases create alternative names for existing types:

```swift
// Simple type alias
typealias Age = Int
typealias Years = Int

let myAge: Age = 30
let yearsOfExperience: Years = 10

// Complex type alias
typealias Coordinate = (x: Int, y: Int)
let point: Coordinate = (x: 10, y: 20)

typealias DictionaryOfInts = [String: Int]
let scores: DictionaryOfInts = ["Alice": 100, "Bob": 95]

// Closure type alias
typealias CompletionHandler = (Bool, Error?) -> Void

func performTask(completion: CompletionHandler) {
    // Perform task
    completion(true, nil)
}
```

---

## Type Checking and Casting

### Type Checking with `is`

```swift
class Animal {}
class Dog: Animal {}
class Cat: Animal {}

let animals: [Any] = [Dog(), Cat(), Animal()]

for animal in animals {
    if animal is Dog {
        print("Found a dog")
    } else if animal is Cat {
        print("Found a cat")
    } else {
        print("Found an animal")
    }
}
```

### Type Casting

```swift
// Optional type casting (safe)
for animal in animals {
    if let dog = animal as? Dog {
        print("Successfully cast to Dog")
    }
}

// Forced type casting (risky)
let firstAnimal = animals[0] as! Dog  // Will crash if not a Dog

// Type casting in switch
for animal in animals {
    switch animal {
    case let dog as Dog:
        print("It's a dog")
    case let cat as Cat:
        print("It's a cat")
    default:
        print("It's an animal")
    }
}
```

---

## Generic Types

Generics enable you to write flexible, reusable code:

```swift
// Generic struct
struct Container<T> {
    var value: T
    
    func getValue() -> T {
        return value
    }
}

let stringContainer = Container(value: "Hello")
let intContainer = Container(value: 42)
let doubleContainer = Container(value: 3.14)

// Generic function
func swap<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}

var x = 1
var y = 2
swap(&x, &y)  // x = 2, y = 1

// Type constraints
func findMax<T: Comparable>(_ array: [T]) -> T? {
    return array.max()
}

let maxInt = findMax([1, 5, 3, 2])        // 5
let maxString = findMax(["apple", "banana", "cherry"])  // "cherry"
```

---

## 🎯 Best Practices

### 1. Prefer Type Inference
- Let Swift infer types when context is clear
- Use annotations for clarity in complex cases

### 2. Use Appropriate Collection Types
- Use `Array` for ordered data
- Use `Set` for uniqueness requirement
- Use `Dictionary` for key-value relationships

### 3. Handle Numeric Types Carefully
- Use `Int` by default
- Use `Double` for floating-point (not `Float`)
- Be aware of overflow possibilities

### 4. String Handling
- Remember that `String` is expensive in loops
- Use `Character` for single characters
- Use string interpolation for efficiency

### 5. Type Safety
- Let the type system catch errors at compile time
- Avoid force unwrapping and force casting when possible

---

## ❌ Common Mistakes

### Mistake 1: Mixing Array and Set

**WRONG:**
```swift
let numbers = [1, 2, 3, 2, 1]  // Why duplicates if using Array?
```

**CORRECT:**
```swift
let numbers: Set = [1, 2, 3, 2, 1]  // {1, 2, 3} - clear intent
```

---

### Mistake 2: Using Float When You Need Double

**WRONG:**
```swift
let pi: Float = 3.14159265359  // Loses precision
```

**CORRECT:**
```swift
let pi: Double = 3.14159265359  // Better precision
```

---

### Mistake 3: Force Casting

**WRONG:**
```swift
let object: Any = "hello"
let number = object as! Int  // ❌ Crashes!
```

**CORRECT:**
```swift
let object: Any = "hello"
if let number = object as? Int {
    print(number)
} else {
    print("Not an integer")
}
```

---

## Related Topics

- [Functions](../functions-and-closures/functions.md)
- [Protocols and Extensions](../object-oriented-programming/protocols.md)
- [Generics Advanced](../../02-architecture/generics.md)

---

**Continue learning by exploring specific collection and type operations!**
