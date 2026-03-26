# Fundamentals 🎯

## Overview

Core Swift fundamentals including types, variables, operators, optionals, functions, and object-oriented programming. This is the foundation for all Swift development.

## Main Topics

- [Data Types](#data-types) - Swift's type system
- [Variables and Constants](#variables-and-constants) - Declaring and managing state
- [Operators](#operators) - Arithmetic, logical, comparison
- [Optionals](#optionals-handling-absence) - Safe nil handling
- [Functions](#functions) - Function declaration and parameters
- [Closures](#closures) - Anonymous functions and functional programming
- [Object-Oriented Programming](#object-oriented-programming) - Classes, structs, protocols
- [Best Practices](#-best-practices) - Do's and don'ts
- [Common Mistakes](#-common-mistakes-anti-patterns) - Avoid these

## Official Documentation

- [The Swift Programming Language - Basics](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/basics)
- [Swift Type System](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types)
- [WWDC: What's New in Swift](https://developer.apple.com/videos/play/wwdc2024/101/)

---

## Data Types

### Primitive Types

Swift has several built-in data types:

```swift
// Integers (various sizes)
let intNumber: Int = 42
let largeInt: Int64 = 9223372036854775807
let smallInt: Int8 = 127

// Floating-point numbers
let floatNumber: Float = 3.14
let doubleNumber: Double = 3.14159265359

// Boolean
let isTrue: Bool = true
let isFalse: Bool = false

// Strings
let message: String = "Hello, Swift!"
let character: Character = "A"

// Type inference (Swift figures out the type)
let inferredInt = 100              // Int
let inferredDouble = 3.14          // Double
let inferredString = "Hello"       // String
```

**Key Points:**
- Swift is **strongly typed** - every value has a specific type
- **Type inference** lets you omit type annotations when obvious
- **Type safety** prevents mixing types and catches errors at compile time
- Use **Int** for integers (not Int32/Int64 unless needed for specific sizes)
- Use **Double** for decimals (better precision than Float)

### Collections

```swift
// Arrays - ordered collection of same type
let numbers: [Int] = [1, 2, 3, 4, 5]
let fruits = ["apple", "banana", "orange"]  // Type: [String]
var mutableArray: [String] = []
mutableArray.append("item")

// Sets - unordered collection of unique values
let uniqueNumbers: Set<Int> = [1, 2, 3, 2, 1]  // Results in {1, 2, 3}
let colors: Set = ["red", "blue", "red"]       // Results in {"red", "blue"}

// Dictionaries - key-value pairs
let ages: [String: Int] = ["Alice": 30, "Bob": 25, "Carol": 35]
let capitals = ["USA": "Washington", "France": "Paris"]  // Type: [String: String]
var mutableDict: [String: Double] = [:]
mutableDict["pi"] = 3.14159
```

---

## Variables and Constants

### Declaration

```swift
// Constants - cannot be changed after assignment
let maximumAttempts = 3
let statusMessage: String = "Ready"

// Variables - can be changed
var currentScore = 0
var playerName: String = "Alice"

// Multiple declarations
let x = 1, y = 2, z = 3
var red = 0.0, green = 0.0, blue = 0.0
```

**Best Practice:**
- Use `let` by default (immutability is safer)
- Only use `var` when you need to change the value
- Declare type explicitly for clarity when not obvious

### Scope

```swift
func exampleScope() {
    let localConstant = "visible here"
    var localVariable = 0
    
    if true {
        let blockConstant = "only here"
        var blockVariable = 1
        print(localConstant)    // ✅ accessible
        print(blockConstant)    // ✅ accessible
    }
    
    print(blockConstant)        // ❌ error - out of scope
}
```

---

## Operators

### Arithmetic Operators

```swift
let a = 10
let b = 3

// Basic arithmetic
let sum = a + b                 // 13
let difference = a - b          // 7
let product = a * b             // 30
let quotient = a / b            // 3 (integer division)
let remainder = a % b           // 1 (modulo)

// Compound assignment
var x = 5
x += 3                          // x = x + 3 = 8
x -= 2                          // x = x - 2 = 6
x *= 2                          // x = x * 2 = 12
x /= 3                          // x = x / 3 = 4

// Power operator
let power = 2 ** 3              // 8 (not valid in Swift!)
// Use pow() from Foundation instead
import Foundation
let correctPower = pow(2.0, 3.0)  // 8.0
```

### Comparison Operators

```swift
let a = 10
let b = 20

a == b      // false (equal)
a != b      // true  (not equal)
a < b       // true  (less than)
a <= b      // true  (less than or equal)
a > b       // false (greater than)
a >= b      // false (greater than or equal)
```

### Logical Operators

```swift
let isAdult = true
let hasLicense = true
let hasInsurance = false

// AND - both must be true
if isAdult && hasLicense {
    print("Can drive")
}

// OR - at least one must be true
if hasLicense || hasInsurance {
    print("Has some qualification")
}

// NOT - reverses boolean
if !hasInsurance {
    print("No insurance")
}

// Combining operators
if isAdult && hasLicense && !hasInsurance {
    print("Adult with license but no insurance")
}
```

---

## Optionals: Handling Absence

Optionals let you represent the possibility that a value might be absent.

### Declaration and Unwrapping

```swift
// Optional declaration - value might be nil
var age: Int? = 25
var name: String? = nil

// Check if optional has value
if let unwrappedAge = age {
    print("Age is \(unwrappedAge)")
}

// Guard statement (recommended)
guard let unwrappedAge = age else {
    print("Age is not available")
    return
}
print("Age is \(unwrappedAge)")

// Force unwrapping (dangerous!)
let unwrappedAge = age!          // Crashes if nil!

// Nil coalescing
let finalAge = age ?? 0          // Use 0 if age is nil
let displayAge: String = "\(age ?? 18)"
```

### Optional Chaining

```swift
class Person {
    var residence: Residence?
}

class Residence {
    var numberOfRooms = 1
}

let person = Person()
// Safe - returns optional
if let rooms = person.residence?.numberOfRooms {
    print("Residence has \(rooms) rooms")
} else {
    print("No residence")
}
```

---

## Functions

### Basic Function

```swift
// Function with return value
func add(a: Int, b: Int) -> Int {
    return a + b
}

let result = add(a: 5, b: 3)     // 8

// Function with no return
func greet(name: String) {
    print("Hello, \(name)!")
}

// Function with multiple return values (tuple)
func getMaxMin(numbers: [Int]) -> (max: Int, min: Int)? {
    guard !numbers.isEmpty else { return nil }
    return (max: numbers.max()!, min: numbers.min()!)
}

if let result = getMaxMin(numbers: [3, 1, 4, 1, 5]) {
    print("Max: \(result.max), Min: \(result.min)")
}
```

### Parameters

```swift
// Default parameters
func greet(name: String = "Guest") {
    print("Hello, \(name)!")
}

greet()                          // "Hello, Guest!"
greet(name: "Alice")             // "Hello, Alice!"

// Variadic parameters
func sum(_ numbers: Int...) -> Int {
    var total = 0
    for number in numbers {
        total += number
    }
    return total
}

sum(1, 2, 3, 4, 5)             // 15

// Argument labels
func move(to destination: String, duration: TimeInterval) {
    print("Moving to \(destination) in \(duration)s")
}

move(to: "Paris", duration: 2.5)
```

---

## Closures

Closures are self-contained blocks of functionality you can pass around in code.

```swift
// Basic closure
let greeting: (String) -> String = { name in
    return "Hello, \(name)!"
}

greeting("Alice")               // "Hello, Alice!"

// Closure as parameter
func performOperation(_ values: [Int], operation: (Int) -> Int) -> [Int] {
    return values.map(operation)
}

let doubled = performOperation([1, 2, 3, 4], operation: { value in
    return value * 2
})
// Or with trailing closure syntax:
let doubled = performOperation([1, 2, 3, 4]) { $0 * 2 }

// Higher-order functions
let numbers = [1, 2, 3, 4, 5]
let evens = numbers.filter { $0 % 2 == 0 }           // [2, 4]
let doubled = numbers.map { $0 * 2 }                 // [2, 4, 6, 8, 10]
let sum = numbers.reduce(0) { $0 + $1 }              // 15
```

---

## Object-Oriented Programming

### Classes vs Structs

```swift
// Class - reference type (mutable by default)
class Person {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    func introduce() {
        print("I'm \(name), \(age) years old")
    }
}

// Struct - value type (prefer for simple data)
struct Point {
    var x: Int
    var y: Int
    
    mutating func moveBy(dx: Int, dy: Int) {
        x += dx
        y += dy
    }
}

// Usage
let person = Person(name: "Alice", age: 30)
person.name = "Bob"                         // Direct mutation
person.introduce()                          // "I'm Bob, 30 years old"

var point = Point(x: 0, y: 0)
point.moveBy(dx: 5, dy: 10)                // point is now (5, 10)
```

### Protocols

```swift
protocol Vehicle {
    var brand: String { get }
    func startEngine()
}

struct Car: Vehicle {
    let brand: String
    
    func startEngine() {
        print("\(brand) car engine started")
    }
}

let myCar = Car(brand: "Tesla")
myCar.startEngine()                        // "Tesla car engine started"
```

---

## 🎯 Best Practices

### 1. Use Type Inference Wisely
- Let Swift infer types when obvious
- Explicit types improve clarity for complex cases

### 2. Prefer Value Types
- Use structs for simple data
- Reserve classes for when you need reference semantics

### 3. Use Let by Default
- Start with constants (`let`)
- Only use variables when mutation is necessary

### 4. Handle Optionals Safely
- Use optional binding (`if let`) or guard statements
- Avoid force unwrapping unless 100% certain

### 5. Write Clear Function Names
- Function names should describe what they do
- Parameters should be clear

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Force Unwrapping Optionals

**WRONG:**
```swift
let name: String? = nil
print(name!)  // ❌ Crashes!
```

**CORRECT:**
```swift
let name: String? = nil
if let name = name {
    print(name)
} else {
    print("Name not available")
}
```

---

### Mistake 2: Using Classes When Structs Would Work

**WRONG:**
```swift
class Rectangle {
    var width: Double
    var height: Double
    
    init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}
```

**CORRECT:**
```swift
struct Rectangle {
    var width: Double
    var height: Double
}
// Simpler, better for value types
```

---

### Mistake 3: Variables Instead of Constants

**WRONG:**
```swift
var maxAttempts = 3          // 😞 Allows mutation
var π = 3.14159              // 🤔 Might change?
```

**CORRECT:**
```swift
let maxAttempts = 3          // ✅ Cannot change
let π = 3.14159              // ✅ Constant value
```

---

## Related Topics

- [Functions Details](functions-and-closures/functions.md)
- [Closures Details](functions-and-closures/closures.md)
- [Object-Oriented Programming](object-oriented-programming/)
- [Type System](types.md)

---

**Now start exploring the detailed sections for each topic!**
