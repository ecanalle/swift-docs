# Closures and Higher-Order Functions

## Overview

Closures are self-contained blocks of functionality that can be passed around and used in your code. They're a powerful pattern for asynchronous operations, callbacks, and functional programming in Swift.

## Main Topics

- [Closure Basics](#closure-basics)
- [Closure Syntax](#closure-syntax)
- [Capturing Values](#capturing-values)
- [Escaping Closures](#escaping-closures)
- [Higher-Order Functions](#higher-order-functions)
- [Practical Patterns](#practical-patterns)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Closures](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures)
- [Functional Programming with Swift](https://developer.apple.com/videos/play/wwdc2016/229/)

---

## Closure Basics

### Defining and Using Closures

```swift
// Closure types declaration
let greeting: (String) -> String = { name in
    return "Hello, \(name)!"
}

print(greeting("Alice"))  // "Hello, Alice!"

// Closure returning multiple values
let getCoordinates: () -> (Int, Int) = {
    return (x: 10, y: 20)
}

// Closure with parameters
let add: (Int, Int) -> Int = { a, b in
    return a + b
}

print(add(5, 3))  // 8

// Closure with no return (Void)
let printValue: (String) -> Void = { value in
    print(value)
}
printValue("Hello")
```

### Type Inference

```swift
// Swift can infer the closure type from context
let numbers = [1, 2, 3, 4, 5]

// Type is explicitly written
let doubled: ([Int]) -> [Int] = { nums in
    return nums.map { $0 * 2 }
}

// Type is inferred from function parameter
func applyOperation(_ values: [Int], operation: (Int) -> Int) -> [Int] {
    return values.map(operation)
}

let result = applyOperation(numbers) { value in
    value * 2
}
```

---

## Closure Syntax

### Full vs Shorthand Syntax

```swift
// Full syntax
let add: (Int, Int) -> Int = { (a: Int, b: Int) -> Int in
    return a + b
}

// Parameter types inferred
let addInferred: (Int, Int) -> Int = { a, b in
    return a + b
}

// Shorthand with implicit return
let addShorthand: (Int, Int) -> Int = { a, b in
    a + b
}

// Multi-line closure
let complexOperation: (Int, Int) -> String = { a, b in
    let sum = a + b
    let product = a * b
    return "Sum: \(sum), Product: \(product)"
}
```

### Shorthand Argument Names

```swift
// Closures have automatic shortcuts: $0, $1, $2, etc.
let numbers = [1, 2, 3, 4, 5]

// Full form
let doubled = numbers.map { value in value * 2 }

// Shorthand
let doubledShort = numbers.map { $0 * 2 }

// Even shorter with method reference
let tripled = numbers.map { $0 * 3 }

// Multiple parameters in shorthand
let sum: (Int, Int) -> Int = { $0 + $1 }
print(sum(5, 3))  // 8
```

### Trailing Closure Syntax

```swift
// When closure is last parameter, it can be outside parentheses
let numbers = [1, 2, 3, 4, 5]

// Traditional
let doubled = numbers.map({ $0 * 2 })

// Trailing closure (cleaner)
let doubledTrailing = numbers.map { $0 * 2 }

// Complex example
func performOperation(_ a: Int, _ b: Int, operation: (Int, Int) -> Int) -> Int {
    return operation(a, b)
}

// Using trailing closure
let result = performOperation(5, 3) { $0 + $1 }

// Multiple trailing closures (rare)
func loadData(onSuccess: @escaping (Data) -> Void, 
              onFailure: @escaping (Error) -> Void) {
    // ...
}

loadData { data in
    print("Success: \(data)")
} onFailure: { error in
    print("Error: \(error)")
}
```

---

## Capturing Values

Closures can capture values from their surrounding context:

```swift
// Capturing constant
let multiplier = 5

let multiplyByCaptured = { value in
    return value * multiplier  // Captures multiplier
}

print(multiplyByCaptured(3))  // 15

// Capturing variables (important!)
var counter = 0

let incrementCounter = {
    counter += 1
    return counter
}

print(incrementCounter())  // 1
print(incrementCounter())  // 2
print(counter)             // 2 (closures capture by reference)

// Capture list to capture by value
var value = 5
let capturedByValue = { [value] in
    value  // Captures value at creation time
}

value = 10
print(capturedByValue())  // 5 (captured the original value)

// Capture self in classes (preventing retain cycles)
class Counter {
    var count = 0
    
    func makeIncrementer() -> () -> Int {
        return { [weak self] in
            self?.count += 1
            return self?.count ?? 0
        }
    }
}
```

---

## Escaping Closures

Escaping closures can outlive the function they're passed to:

```swift
// Non-escaping closure (default)
func doSomething(operation: (Int) -> Int) {
    let result = operation(5)
    print(result)
}

// Can't store non-escaping closures for later

// Escaping closure - can outlive the function
var storedClosures: [(Int) -> Void] = []

func storeClosures(operation: @escaping (Int) -> Void) {
    storedClosures.append(operation)  // Store for later
}

storeClosures { value in
    print("Stored: \(value)")
}

// Typical async pattern with escaping
func fetchData(completion: @escaping (String) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        completion("Data fetched!")
    }
}

fetchData { data in
    print(data)
}

// Capturing self with escaping
class DataFetcher {
    var data = ""
    
    func fetch(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.data = "Fetched"
            completion()
        }
    }
}
```

---

## Higher-Order Functions

### Map

```swift
let numbers = [1, 2, 3, 4, 5]

// Basic map
let doubled = numbers.map { $0 * 2 }  // [2, 4, 6, 8, 10]

// Type transformation
let strings = numbers.map { String($0) }  // ["1", "2", "3", "4", "5"]

// Complex transformation
let summaries = numbers.map { number in
    if number % 2 == 0 {
        return "Even: \(number)"
    } else {
        return "Odd: \(number)"
    }
}

// Nested map
let matrix = [[1, 2], [3, 4], [5, 6]]
let flattened = matrix.map { row in row.map { $0 * 2 } }
```

### Filter

```swift
let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

// Filter evens
let evens = numbers.filter { $0 % 2 == 0 }  // [2, 4, 6, 8, 10]

// Filter by condition
let greaterThanFive = numbers.filter { $0 > 5 }  // [6, 7, 8, 9, 10]

// Chaining filter and map
let evenDoubled = numbers.filter { $0 % 2 == 0 }.map { $0 * 2 }
// [4, 8, 12, 16, 20]

// Complex filtering
let words = ["swift", "apple", "code", "programming"]
let longWords = words.filter { $0.count > 4 }  // ["swift", "apple", "programming"]
```

### Reduce

```swift
let numbers = [1, 2, 3, 4, 5]

// Sum
let sum = numbers.reduce(0) { $0 + $1 }  // 15

// Product
let product = numbers.reduce(1) { $0 * $1 }  // 120

// Building a string
let words = ["Hello", "Swift", "Developer"]
let sentence = words.reduce("") { result, word in
    result.isEmpty ? word : result + " " + word
}  // "Hello Swift Developer"

// Building a dictionary
let items = ["apple", "banana", "apple", "cherry", "banana"]
let counts = items.reduce(into: [:]) { dictionary, item in
    dictionary[item, default: 0] += 1
}  // ["apple": 2, "banana": 2, "cherry": 1]
```

### Combining Higher-Order Functions

```swift
let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

// Filter evens, multiply by 2, sum them
let result = numbers
    .filter { $0 % 2 == 0 }    // [2, 4, 6, 8, 10]
    .map { $0 * 2 }             // [4, 8, 12, 16, 20]
    .reduce(0) { $0 + $1 }      // 60

// Complex transformation
let data = ["apple", "banana", "cherry", "date", "elderberry"]
let processedData = data
    .filter { $0.count > 4 }                           // ["apple", "banana", "cherry", "elderberry"]
    .map { $0.uppercased() }                           // ["APPLE", "BANANA", "CHERRY", "ELDERBERRY"]
    .map { "Fruit: \($0)" }                            // ["Fruit: APPLE", ...]
    .reduce("") { $0 + "\n" + $1 }                     // Multi-line list
```

---

## Practical Patterns

### Callback Pattern

```swift
class ImageLoader {
    func loadImage(from url: URL, 
                   onSuccess: @escaping (UIImage) -> Void,
                   onFailure: @escaping (Error) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                onFailure(error)
            } else if let data = data, let image = UIImage(data: data) {
                onSuccess(image)
            } else {
                onFailure(NSError(domain: "Invalid data", code: -1))
            }
        }.resume()
    }
}

// Using
let loader = ImageLoader()
loader.loadImage(from: URL(string: "https://example.com/image.png")!) { image in
    imageView.image = image
} onFailure: { error in
    print("Failed to load image: \(error)")
}
```

### Composition

```swift
func compose<A, B, C>(_ f: @escaping (A) -> B, 
                       _ g: @escaping (B) -> C) -> (A) -> C {
    return { a in g(f(a)) }
}

let double = { $0 * 2 }
let addOne = { $0 + 1 }

let doubleThenAddOne = compose(double, addOne)
print(doubleThenAddOne(5))  // 11 (5*2=10, 10+1=11)
```

---

## 🎯 Best Practices

### 1. Use Trailing Closures for Readability
- Makes code more readable, less parentheses clutter

### 2. Capture Lists for Memory Management
- Use `[weak self]` to avoid retain cycles
- Be intentional about what you capture

### 3. Prefer Keywords Over Shorthand
- Use `$0` for simple operations
- Use named parameters for complex logic

### 4. Keep Closures Small
- If closure is too complex, make it a function
- Complex logic shouldn't hide in closures

### 5. Chain Functional Operations
- map → filter → reduce creates elegant pipelines
- More readable than nested loops

---

## ❌ Common Mistakes

### Mistake 1: Retain Cycles with self

**WRONG:**
```swift
func makeCompletion() -> () -> Void {
    var data = "important"
    return {
        print(self.data)  // Strong reference to self!
    }
}
```

**CORRECT:**
```swift
func makeCompletion() -> () -> Void {
    var data = "important"
    return { [weak self] in
        print(self?.data ?? "nil")
    }
}
```

---

### Mistake 2: Complex Logic in Closures

**WRONG:**
```swift
let result = numbers.map { number in
    var adjusted = number
    for i in 1...number {
        adjusted = adjusted - i
    }
    return adjusted
}
```

**CORRECT:**
```swift
func adjustNumber(_ number: Int) -> Int {
    var adjusted = number
    for i in 1...number {
        adjusted = adjusted - i
    }
    return adjusted
}

let result = numbers.map(adjustNumber(_:))
```

---

### Mistake 3: Overusing Shorthand

**WRONG:**
```swift
let result = data.reduce([]) { $0 + [$1.modified ? $1.transform() : $1.copy($1.newValue)] }
```

**CORRECT:**
```swift
let result = data.reduce([]) { accumulator, item in
    let transformed = item.modified ? item.transform() : item.copy(item.newValue)
    return accumulator + [transformed]
}
```

---

## Related Topics

- [Functions](functions.md)
- [Error Handling](../../02-architecture/error-handling.md)
- [Async/Await](../../03-networking-backend/async-await.md)

---

**Master closures to write functional, elegant Swift code!**
