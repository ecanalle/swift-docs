# Extensions in Swift

## Overview

Extensions add new functionality to existing types without modifying their source code. They enable powerful composition patterns, allow separating concerns, and let you extend types you don't own.

## Main Topics

- [Extension Basics](#extension-basics)
- [Methods and Properties](#methods-and-properties)
- [Computed Properties](#computed-properties)
- [Subscripts](#subscripts)
- [Protocol Conformance](#protocol-conformance)
- [Conditional Extensions](#conditional-extensions)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Extensions](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/extensions)

---

## Extension Basics

### Extending Built-in Types

```swift
// Add method to String
extension String {
    func repeated(count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

let text = "Ha".repeated(count: 3)
print(text)  // "HaHaHa"

// Add method to Int
extension Int {
    func squared() -> Int {
        return self * self
    }
}

print(5.squared())  // 25

// Add method to Array
extension Array {
    func shuffled() -> [Element] {
        var result = self
        for i in (1..<result.count).reversed() {
            let j = Int.random(in: 0...i)
            result.swapAt(i, j)
        }
        return result
    }
}

let numbers = [1, 2, 3, 4, 5]
print(numbers.shuffled())
```

### Extending Your Own Types

```swift
class Calculator {
    func add(_ a: Int, _ b: Int) -> Int {
        return a + b
    }
}

// Add functionality later
extension Calculator {
    func multiply(_ a: Int, _ b: Int) -> Int {
        return a * b
    }
    
    func divide(_ a: Int, _ b: Int) -> Int {
        return b != 0 ? a / b : 0
    }
}

let calc = Calculator()
calc.add(2, 3)       // 5
calc.multiply(2, 3)  // 6
```

---

## Methods and Properties

### Instance Methods

```swift
extension String {
    // Instance method
    func paddedTo(width: Int) -> String {
        let paddingCount = max(0, width - self.count)
        return self + String(repeating: " ", count: paddingCount)
    }
    
    // Mutating method
    mutating func removeWhitespace() {
        self = self.filter { !$0.isWhitespace }
    }
}

var text = "Hello"
print(text.paddedTo(width: 10))  // "Hello     "

var padded = "H e l l o"
padded.removeWhitespace()
print(padded)  // "Hello"
```

### Type Methods

```swift
extension Double {
    // Type method
    static func random(min: Double, max: Double) -> Double {
        return min + Double.random(in: 0..<1) * (max - min)
    }
}

let random = Double.random(min: 1.0, max: 10.0)
print(random)  // 5.234...
```

### Stored Properties? (Not Possible)

```swift
// ❌ Cannot add stored properties to classes/structs
extension User {
    // var nickname: String  // ❌ Not allowed
}

// ✅ But you CAN add computed properties
extension User {
    var displayName: String {
        return "\(firstName) \(lastName)"
    }
}
```

---

## Computed Properties

### Read-only Computed Properties

```swift
extension String {
    var reversed: String {
        return String(self.reversed())
    }
    
    var wordCount: Int {
        return self.split(separator: " ").count
    }
    
    var isCapitalized: Bool {
        return self.first?.isUppercase ?? false
    }
}

print("Hello".reversed)  // "olleH"
print("One Two Three".wordCount)  // 3
print("Hello".isCapitalized)  // true
```

### Read-Write Computed Properties

```swift
struct User {
    var firstName: String
    var lastName: String
}

extension User {
    var fullName: String {
        get {
            return "\(firstName) \(lastName)"
        }
        set {
            let parts = newValue.split(separator: " ")
            firstName = String(parts.first ?? "")
            lastName = String(parts.last ?? "")
        }
    }
}

var user = User(firstName: "John", lastName: "Doe")
print(user.fullName)  // "John Doe"

user.fullName = "Jane Smith"
print(user.firstName)  // "Jane"
print(user.lastName)   // "Smith"
```

### Property Observers (Limited)

```swift
class Temperature {
    var celsius: Double = 0
}

extension Temperature {
    var fahrenheit: Double {
        get {
            return celsius * 9/5 + 32
        }
        set {
            celsius = (newValue - 32) * 5/9
        }
    }
}

let temp = Temperature()
temp.celsius = 0
print(temp.fahrenheit)  // 32.0
```

---

## Subscripts

### Adding Subscripts

```swift
extension String {
    subscript(i: Int) -> String? {
        guard i >= 0, i < self.count else { return nil }
        let index = self.index(self.startIndex, offsetBy: i)
        return String(self[index])
    }
}

let text = "Hello"
print(text[0])  // "H"
print(text[1])  // "e"
print(text[10]) // nil

// Multiple subscripts
extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

let numbers = [1, 2, 3]
print(numbers[safe: 0])  // 1
print(numbers[safe: 10]) // nil
```

---

## Protocol Conformance

### Adding Protocol Conformance

```swift
protocol Drawable {
    func draw()
}

class Circle {
    let radius: Int
    
    init(radius: Int) {
        self.radius = radius
    }
}

// Add protocol conformance in extension
extension Circle: Drawable {
    func draw() {
        print("Drawing circle with radius \(radius)")
    }
}

let circle = Circle(radius: 5)
circle.draw()  // "Drawing circle with radius 5"
```

### Multiple Protocol Conformance

```swift
protocol Identifiable {
    var id: Int { get }
}

protocol Nameable {
    var name: String { get }
}

class User {
    let userId: Int
    let userName: String
    
    init(userId: Int, userName: String) {
        self.userId = userId
        self.userName = userName
    }
}

extension User: Identifiable {
    var id: Int {
        return userId
    }
}

extension User: Nameable {
    var name: String {
        return userName
    }
}

let user = User(userId: 1, userName: "John")
print(user.id)    // 1
print(user.name)  // "John"
```

---

## Conditional Extensions

### Generic Conditional Extensions

```swift
// Extend Array only when Element conforms to Numeric
extension Array where Element: Numeric {
    func sum() -> Element {
        return self.reduce(0, +)
    }
}

let integers = [1, 2, 3, 4]
print(integers.sum())  // 10

let floats = [1.5, 2.5, 3.0]
print(floats.sum())    // 7.0

// ❌ Can't call sum() on String array
// let strings = ["a", "b"]
// strings.sum()  // Error!
```

### Protocol Conditional Extensions

```swift
protocol Countable {
    var count: Int { get }
}

extension Countable {
    var isEmpty: Bool {
        return count == 0
    }
    
    var isNotEmpty: Bool {
        return count > 0
    }
}

extension Array: Countable {}
let items = [1, 2, 3]
print(items.isEmpty)  // false
print(items.isNotEmpty)  // true
```

### Equatable Conditional Extensions

```swift
extension Array where Element: Equatable {
    func removeDuplicates() -> [Element] {
        var result: [Element] = []
        for item in self {
            if !result.contains(item) {
                result.append(item)
            }
        }
        return result
    }
}

let numbers = [1, 2, 2, 3, 3, 3]
print(numbers.removeDuplicates())  // [1, 2, 3]
```

---

## 🎯 Best Practices

### 1. Use Extensions to Organize Code
```swift
class User {
    // Core properties
}

// Group related functionality
extension User {
    // Initialization logic
}

extension User {
    // Database operations
}

extension User {
    // Network operations
}
```

### 2. Add Protocol Conformance in Separate Extensions
```swift
// ✅ Each protocol in its own extension
extension User: Codable { }
extension User: Equatable { }
extension User: Comparable { }

// ❌ Not in the same extension
// extension User: Codable, Equatable, Comparable { }
```

### 3. Keep Extensions Cohesive
```swift
// ✅ Related functionality together
extension String {
    var reversed: String { }
    var capitalized: String { }
}

// ❌ Unrelated stuff scattered
extension String {
    var reversed: String { }
    func networkCall() { }
}
```

### 4. Document Extensions
```swift
/// Provides validation utilities for the User type
extension User {
    /// Validates email format
    func isEmailValid() -> Bool { }
}
```

### 5. Use Conditional Extensions for Generics
```swift
// ✅ Only available when type conforms
extension Array where Element: Comparable {
    func median() -> Element? { }
}
```

---

## ❌ Common Mistakes

### Mistake 1: Adding Stored Properties

**WRONG:**
```swift
extension User {
    var nickname: String = "unknown"  // ❌ Not allowed
}
```

**CORRECT:**
```swift
extension User {
    var displayName: String {  // ✅ Computed property
        return "\(firstName) \(lastName)"
    }
}
```

---

### Mistake 2: Breaking Encapsulation

**WRONG:**
```swift
extension User {
    // ❌ Breaking encapsulation - private implementation details
    func dangerousInternalOperation() { }
}
```

**CORRECT:**
```swift
extension User {
    // ✅ Public API extensions
    func validate() -> Bool { }
}
```

---

### Mistake 3: Overly Mixing Generic and Specific Extensions

**WRONG:**
```swift
extension Array {
    func removeDuplicates() { }  // ❌ Only works if Element is Equatable
}
```

**CORRECT:**
```swift
extension Array where Element: Equatable {
    func removeDuplicates() { }  // ✅ Clear requirement
}
```

---

## Related Topics

- [Protocols](protocols.md)
- [Classes and Structures](classes-and-structures.md)
- [Generics](../../07-advanced/advanced-performance/generics.md)

---

**Extensions enable clean, maintainable code organization!**
