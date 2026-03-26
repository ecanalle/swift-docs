# Functions and Parameters

## Overview

Functions are reusable blocks of code that perform specific tasks. Mastering function design patterns, parameter passing, and return types is essential for clean, maintainable Swift code.

## Main Topics

- [Function Basics](#function-basics) - Declaration and execution
- [Parameters](#parameters) - Input handling
- [Return Values](#return-values) - Output patterns
- [Parameters Deep Dive](#parameters-deep-dive) - Labels, defaults, variadic
- [Inout Parameters](#inout-parameters) - Modifying parameters
- [Function Types](#function-types) - Functions as values
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Functions](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/functions)
- [WWDC: Advanced Techniques with Functions](https://developer.apple.com/videos/play/wwdc2016/401/)

---

## Function Basics

### Simple Functions

```swift
// Function with no parameters or return value
func sayHello() {
    print("Hello, world!")
}
sayHello()

// Function with return value
func add(a: Int, b: Int) -> Int {
    return a + b
}
let result = add(a: 5, b: 3)  // 8

// Function with implicit return (single expression)
func multiply(a: Int, b: Int) -> Int {
    a * b
}

// Function with no return statement returns Void
func logMessage(_ message: String) {
    print(message)
}
```

### Return Early

```swift
func divide(_ a: Double, _ b: Double) -> Double? {
    guard b != 0 else {
        return nil  // Early return
    }
    return a / b
}

if let result = divide(10, 2) {
    print("Result: \(result)")
} else {
    print("Cannot divide by zero")
}
```

---

## Parameters

### Parameter Basics

```swift
// Positional parameters
func greet(firstName: String, lastName: String) {
    print("Hello, \(firstName) \(lastName)")
}
greet(firstName: "John", lastName: "Doe")

// Multiple parameters same type
func add(_ a: Int, _ b: Int) -> Int {
    return a + b
}
add(5, 3)  // Underscore means no label required

// Named parameters
func move(to destination: String, duration: Int) {
    print("Moving to \(destination) in \(duration) seconds")
}
move(to: "Paris", duration: 5)
```

### Parameter Labels

```swift
// Argument label vs Parameter name
func someFunction(argumentLabel parameterName: Int) {
    // Use 'parameterName' inside function
}
someFunction(argumentLabel: 42)  // Called with 'argumentLabel'

// Practical example
func setSize(width: Int, height: Int) {
    print("\(width)x\(height)")
}
setSize(width: 100, height: 200)

// Omit argument label with underscore
func multiplyByTwo(_ value: Int) -> Int {
    return value * 2
}
let doubled = multiplyByTwo(5)  // No label needed
```

---

## Return Values

### Single Return

```swift
func getMaximum(a: Int, b: Int) -> Int {
    return a > b ? a : b
}

// Implicit return
func getMinimum(a: Int, b: Int) -> Int {
    a < b ? a : b
}
```

### Multiple Returns (Tuples)

```swift
// Returning multiple values
func getCoordinates() -> (x: Int, y: Int) {
    return (x: 10, y: 20)
}

let location = getCoordinates()
print(location.x, location.y)

// Returning optional tuple
func findUser(id: Int) -> (name: String, age: Int)? {
    guard id > 0 else { return nil }
    return (name: "Alice", age: 30)
}

if let user = findUser(id: 1) {
    print("\(user.name) is \(user.age)")
}

// Destructuring return values
let (x, y) = getCoordinates()
let (_, yValue) = getCoordinates()  // Ignore x
```

### Optional Returns

```swift
// Function returning optional
func parseInt(_ string: String) -> Int? {
    return Int(string)
}

if let number = parseInt("42") {
    print("Parsed: \(number)")
} else {
    print("Could not parse")
}

// Returning optional with guard
func getAge(for person: [String: Int], named name: String) -> Int? {
    guard let age = person[name] else { return nil }
    return age
}
```

---

## Parameters Deep Dive

### Default Parameter Values

```swift
// Parameters with defaults
func greet(name: String, greeting: String = "Hello") {
    print("\(greeting), \(name)!")
}

greet(name: "Alice")                      // Uses default
greet(name: "Bob", greeting: "Hi")        // Override default

// Multiple defaults
func createUser(name: String, age: Int = 18, active: Bool = true) {
    print("User: \(name), \(age), active: \(active)")
}

createUser(name: "Carol")                 // age=18, active=true
createUser(name: "David", age: 25)        // active=true
```

### Variadic Parameters

```swift
// Variadic parameter accepts multiple values
func sum(_ numbers: Int...) -> Int {
    var total = 0
    for number in numbers {
        total += number
    }
    return total
}

sum(1, 2, 3, 4, 5)              // 15
sum(10, 20)                      // 30

// Multiple parameters with variadic
func concatenate(separator: String, _ items: String...) -> String {
    return items.joined(separator: separator)
}

concatenate(separator: ", ", "Swift", "is", "awesome")
// "Swift, is, awesome"

// Variadic with other parameters
func buildPath(base: String, _ components: String...) -> String {
    var path = base
    for component in components {
        path += "/\(component)"
    }
    return path
}
```

---

## Inout Parameters

Inout parameters allow functions to modify the arguments directly:

```swift
// Without inout - original value unchanged
func increment(_ value: Int) {
    // value += 1  // Error - parameters are immutable
}

// With inout
func incrementInout(_ value: inout Int) {
    value += 1
}

var number = 5
incrementInout(&number)
print(number)  // 6 (modified!)

// Swap example
func swap<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}

var x = 1, y = 2
swap(&x, &y)
print(x, y)  // 2 1

// Inout with structs
struct Point {
    var x: Int
    var y: Int
}

func movePoint(_ point: inout Point, by dx: Int, dy: Int) {
    point.x += dx
    point.y += dy
}

var origin = Point(x: 0, y: 0)
movePoint(&origin, by: 5, dy: 10)
print(origin.x, origin.y)  // 5 10
```

---

## Function Types

Functions have types and can be assigned to variables:

```swift
// Function type: (Int, Int) -> Int means takes 2 ints, returns int
func add(_ a: Int, _ b: Int) -> Int {
    return a + b
}

func multiply(_ a: Int, _ b: Int) -> Int {
    return a * b
}

// Assigning function to variable
var operation: (Int, Int) -> Int = add
var result = operation(5, 3)  // 8

operation = multiply
result = operation(5, 3)      // 15

// Function type with parameters and return
typealias MathOperation = (Int, Int) -> Int

func chooseOperation(multiply: Bool) -> MathOperation {
    return multiply ? { $0 * $1 } : { $0 + $1 }
}

let math = chooseOperation(multiply: true)
print(math(5, 3))  // 15

// Function parameters and returns
func applyTwice(_ operation: (Int) -> Int, to value: Int) -> Int {
    return operation(operation(value))
}

let double: (Int) -> Int = { $0 * 2 }
print(applyTwice(double, to: 5))  // 20 (5 * 2 = 10, 10 * 2 = 20)
```

---

## 🎯 Best Practices

### 1. Clear Function Names
- Function names should describe what they do
- Use verb-noun pattern: `calculateTotal()`, `formatString()`

### 2. Reasonable Parameter Count
- Aim for 2-3 parameters
- Use structs for related parameters

### 3. Consistent Return Types
- Be consistent: if sometimes returning optional, document always
- Use explicit return types when not obvious

### 4. Document Complex Functions
- Use comments for non-obvious logic
- Explain parameter purposes if not clear from names

### 5. Use Parameter Labels
- Make function calls self-documenting
- Use underscore only when appropriate

---

## ❌ Common Mistakes

### Mistake 1: Too Many Parameters

**WRONG:**
```swift
func createUser(_ name: String, _ email: String, _ age: Int, 
                _ city: String, _ country: String, _ active: Bool) {
    // Too many parameters!
}
```

**CORRECT:**
```swift
struct UserData {
    var name: String
    var email: String
    var age: Int
    var city: String
    var country: String
    var active: Bool
}

func createUser(_ userData: UserData) {
    // Cleaner signature
}
```

---

### Mistake 2: Force Unwrapping Return Values

**WRONG:**
```swift
func parseInt(_ string: String) -> Int {
    return Int(string)!  // ❌ Crashes on invalid input
}
```

**CORRECT:**
```swift
func parseInt(_ string: String) -> Int? {
    return Int(string)  // Returns optional safely
}

if let number = parseInt("42") {
    print(number)
}
```

---

### Mistake 3: Mutating with Inout When Not Needed

**WRONG:**
```swift
func modify(_ array: inout [Int]) {
    array.append(42)  // Unnecessary inout
}
```

**CORRECT:**
```swift
func modified(_ array: [Int]) -> [Int] {
    var result = array
    result.append(42)
    return result  // Clearer - create new array
}
```

---

## Related Topics

- [Closures](closures.md)
- [Higher-Order Functions](closures.md)
- [Function Builders](../../02-architecture/function-builders.md)

---

**Master functions to write clean, reusable Swift code!**
