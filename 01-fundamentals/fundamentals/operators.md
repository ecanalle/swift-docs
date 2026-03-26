# Operators in Swift

## Overview

Operators are the building blocks of expressions. Swift provides comfortable familiar operators while introducing powerful custom operator capabilities for domain-specific languages and intuitive APIs.

## Main Topics

- [Basic Operators](#basic-operators)
- [Comparison Operators](#comparison-operators)
- [Logical Operators](#logical-operators)
- [Bitwise Operators](#bitwise-operators)
- [Assignment Operators](#assignment-operators)
- [Range Operators](#range-operators)
- [Custom Operators](#custom-operators)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Operators](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators)

---

## Basic Operators

### Arithmetic Operators

```swift
// Addition
let sum = 1 + 2           // 3
let concat = "Hello " + "World"  // "Hello World"

// Subtraction
let difference = 5 - 3    // 2

// Multiplication
let product = 3 * 4       // 12
let repeated = "Ha" * 3   // Not valid, use String(repeating:)

// Division
let quotient = 10 / 3     // 3 (integer division)
let precise = 10.0 / 3    // 3.333...

// Remainder
let remainder = 10 % 3    // 1
let negative = -7 % 3     // -1

// Unary Plus/Minus
let positive = +5
let negative = -5
```

### Operator Precedence

```swift
// Multiplication before addition
let result = 2 + 3 * 4    // 14, not 20

// Use parentheses for clarity
let explicit = (2 + 3) * 4  // 20
```

---

## Comparison Operators

### Basic Comparisons

```swift
let a = 5
let b = 10

a == b  // false (equal to)
a != b  // true (not equal to)
a < b   // true (less than)
a > b   // false (greater than)
a <= b  // true (less than or equal)
a >= b  // false (greater than or equal)

// String comparison
"apple" == "apple"  // true
"apple" < "banana"  // true (alphabetical)
```

### Comparing Custom Types

```swift
struct Person: Equatable {
    let name: String
    let age: Int
    
    // Equatable requires implementation
    static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.name == rhs.name && lhs.age == rhs.age
    }
}

let person1 = Person(name: "John", age: 30)
let person2 = Person(name: "John", age: 30)
let person3 = Person(name: "Jane", age: 25)

person1 == person2  // true
person1 == person3  // false

// Comparable for ordering
struct User: Comparable {
    let name: String
    let score: Int
    
    static func < (lhs: User, rhs: User) -> Bool {
        return lhs.score < rhs.score
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.name == rhs.name && lhs.score == rhs.score
    }
}

let users = [User(name: "Alice", score: 90),
             User(name: "Bob", score: 80)]
let sorted = users.sorted()  // Sorts by score
```

---

## Logical Operators

### AND, OR, NOT

```swift
let hasEmail = true
let isActive = false

hasEmail && isActive  // false (AND)
hasEmail || isActive  // true (OR)
!hasEmail             // false (NOT)

// Short-circuit evaluation
var counter = 0
func increment() -> Bool {
    counter += 1
    return true
}

if false && increment() {  // increment NOT called
    print("Won't execute")
}
print(counter)  // 0 - short-circuit prevented execution

// Combine conditions
if hasEmail && isActive && validateFormat(hasEmail) {
    print("User valid")
}
```

### Using in Collections

```swift
let numbers = [1, 2, 3, 4, 5]

// AND condition
let evenLessThan4 = numbers.filter { $0 % 2 == 0 && $0 < 4 }
// [2]

// OR condition
let firstOrLast = numbers.filter { $0 == numbers.first! || $0 == numbers.last! }
// [1, 5]

// NOT condition
let notThree = numbers.filter { $0 != 3 }
// [1, 2, 4, 5]
```

---

## Bitwise Operators

### Bitwise AND, OR, XOR

```swift
let a: UInt8 = 0b11110010
let b: UInt8 = 0b10101010

// AND - both must be 1
a & b  // 0b10100010

// OR - at least one must be 1
a | b  // 0b11111010

// XOR - exactly one must be 1
a ^ b  // 0b01011000

// NOT - flip bits
~a     // 0b00001101
```

### Bit Shifting

```swift
let x: UInt8 = 0b00010100

// Left shift (multiply by powers of 2)
x << 1  // 0b00101000 (equivalent to x * 2)
x << 2  // 0b01010000 (equivalent to x * 4)

// Right shift (divide by powers of 2)
x >> 1  // 0b00001010 (equivalent to x / 2)
x >> 2  // 0b00000101 (equivalent to x / 4)
```

### Practical Use: Flags

```swift
struct Permissions: OptionSet {
    let rawValue: Int
    
    static let read = Permissions(rawValue: 1 << 0)     // 001
    static let write = Permissions(rawValue: 1 << 1)    // 010
    static let execute = Permissions(rawValue: 1 << 2)  // 100
}

var userPermissions: Permissions = [.read, .write]

// Check if has permission
userPermissions.contains(.read)    // true
userPermissions.contains(.execute) // false

// Add permission
userPermissions.insert(.execute)

// Remove permission
userPermissions.remove(.write)
```

---

## Assignment Operators

### Basic Assignment

```swift
var x = 5
x = 10
x += 5  // x = 15
x -= 3  // x = 12
x *= 2  // x = 24
x /= 4  // x = 6
x %= 4  // x = 2
```

### Compound Assignment

```swift
var count = 0
count += 1    // 1
count += 2    // 3
count -= 1    // 2

var text = "Hello"
text += " World"  // "Hello World"
```

### Assigning Multiple Values

```swift
let (x, y) = (10, 20)
print(x, y)  // 10, 20

// In functions
func getTuple() -> (Int, String) {
    return (42, "Answer")
}
let (number, label) = getTuple()

// Ignoring values
let (first, _) = getTuple()
```

---

## Range Operators

### Closed Range

```swift
let range = 1...5
range.contains(3)  // true
range.contains(6)  // false

for i in 1...5 {
    print(i)  // 1, 2, 3, 4, 5
}

let array = [10, 20, 30, 40, 50]
array[1...3]  // [20, 30, 40]
```

### Half-Open Range

```swift
let halfOpen = 1..<5
halfOpen.contains(4)  // true
halfOpen.contains(5)  // false

for i in 1..<5 {
    print(i)  // 1, 2, 3, 4
}

let text = "Hello"
text[text.startIndex..<text.index(text.startIndex, offsetBy: 3)]
// "Hel"
```

### One-sided Ranges

```swift
let array = [10, 20, 30, 40, 50]

// From index to end
array[2...]  // [30, 40, 50]

// From start to index
array[...2]  // [10, 20, 30]

// From start to before index
array[..<2]  // [10, 20]
```

---

## Custom Operators

### Defining Custom Operators

```swift
// Define operator
infix operator ⊕

// Implement for specific type
extension String {
    static func ⊕(lhs: String, rhs: String) -> String {
        return lhs + " " + rhs
    }
}

let greeting = "Hello" ⊕ "World"  // "Hello World"

// With precedence
infix operator ⊙: MultiplicationPrecedence

struct Vector {
    let x: Int
    let y: Int
    
    static func ⊙(lhs: Vector, rhs: Vector) -> Int {
        return lhs.x * rhs.x + lhs.y * rhs.y
    }
}

let v1 = Vector(x: 2, y: 3)
let v2 = Vector(x: 4, y: 5)
let dotProduct = v1 ⊙ v2  // 23
```

### Prefix and Postfix Operators

```swift
prefix operator ‼

extension Int {
    static prefix func ‼(value: Int) -> String {
        return String(repeating: "!", count: value)
    }
}

‼3  // "!!!"

// Postfix (rare)
postfix operator ✓

extension String {
    static postfix func ✓(value: String) -> String {
        return value + " ✓"
    }
}

"Complete"✓  // "Complete ✓"
```

---

## 🎯 Best Practices

### 1. Use Standard Operators First
- Prefer `==` over custom operators
- Built-in operators are familiar
- Custom operators only for domain-specific languages

### 2. Clear Operator Precedence
```swift
// ❌ Hard to read
let result = a + b * c - d / e

// ✅ Use parentheses
let result = (a + (b * c)) - (d / e)
```

### 3. Meaningful Custom Operators
```swift
// ✅ For domain-specific use
struct Matrix {
    static func * (lhs: Matrix, rhs: Matrix) -> Matrix {
        // Matrix multiplication
    }
}

// ❌ Don't overload for unclear purpose
static func ⊕(lhs: String, rhs: String) -> Bool {
    // What does ⊕ mean here? Unclear.
}
```

### 4. Document Custom Operators
```swift
/// Computes the dot product of two vectors
/// - Parameters:
///   - lhs: First vector
///   - rhs: Second vector
/// - Returns: The scalar dot product
static func · (lhs: Vector, rhs: Vector) -> Double {
    return Double(lhs.x * rhs.x + lhs.y * rhs.y)
}
```

---

## ❌ Common Mistakes

### Mistake 1: Assignment vs Equality

**WRONG:**
```swift
if x = 5 {  // ❌ This assigns, doesn't compare
    print("x is 5")
}
```

**CORRECT:**
```swift
if x == 5 {  // ✅ This compares
    print("x is 5")
}
```

---

### Mistake 2: Confusing && with ||

**WRONG:**
```swift
if hasName || hasEmail || hasPhone {  // Should be AND if all required
    print("User valid")
}
```

**CORRECT:**
```swift
if hasName && hasEmail && hasPhone {  // All must be true
    print("User valid")
}
```

---

### Mistake 3: Integer Division

**WRONG:**
```swift
let average = (10 + 20 + 30) / 3  // 20 (integer division)
```

**CORRECT:**
```swift
let average = Double(10 + 20 + 30) / 3  // 20.0
```

---

## Related Topics

- [Data Types](data-types.md)
- [Functions](functions.md)
- [Optionals](optionals.md)

---

**Master operators for elegant, expressive code!**
