# Generics in Swift

## Overview

Generics enable you to write flexible, reusable code that works with any type while maintaining type safety. They're fundamental to Swift's standard library—arrays, dictionaries, and optionals are all generic types.

## Main Topics

- [Generic Basics](#generic-basics)
- [Generic Functions](#generic-functions)
- [Generic Types](#generic-types)
- [Type Constraints](#type-constraints)
- [Associated Types](#associated-types)
- [Generic Where Clauses](#generic-where-clauses)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Generics](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/generics)

---

## Generic Basics

### The Problem Without Generics

```swift
// ❌ Repetitive code for each type
func swapInts(_ a: inout Int, _ b: inout Int) {
    let temp = a
    a = b
    b = temp
}

func swapStrings(_ a: inout String, _ b: inout String) {
    let temp = a
    a = b
    b = temp
}

func swapDoubles(_ a: inout Double, _ b: inout Double) {
    let temp = a
    a = b
    b = temp
}

// ✅ One generic function handles all types
func swap<T>(_ a: inout T, _ b: inout T) {
    let temp = a
    a = b
    b = temp
}

var x = 5, y = 10
swap(&x, &y)  // x = 10, y = 5

var name1 = "Alice", name2 = "Bob"
swap(&name1, &name2)  // name1 = "Bob", name2 = "Alice"
```

### Type Parameter Naming

```swift
// Single type parameter (usually T)
func first<T>(in array: [T]) -> T? {
    return array.first
}

// Multiple type parameters
func combine<T, U>(_ first: T, _ second: U) -> (T, U) {
    return (first, second)
}

// Multiple instances of same type
func zip<T>(_ array1: [T], _ array2: [T]) -> [(T, T)] {
    return Array(zip(array1, array2))
}

// Usage
let pair = combine(42, "Answer")  // (Int, String)
```

---

## Generic Functions

### Basic Generic Functions

```swift
// Generic function that works with any Comparable type
func findMax<T: Comparable>(_ array: [T]) -> T? {
    return array.max()
}

findMax([1, 5, 3])           // 5
findMax(["a", "z", "m"])     // "z"
findMax([3.14, 2.71])        // 3.14

// Generic with multiple parameters
func filter<T>(_ array: [T], where predicate: (T) -> Bool) -> [T] {
    return array.filter(predicate)
}

let numbers = [1, 2, 3, 4, 5]
let evens = filter(numbers) { $0 % 2 == 0 }  // [2, 4]
```

### Generic with Return Type

```swift
// Generic return type
func makeArray<T>(repeating: T, count: Int) -> [T] {
    return Array(repeating: repeating, count: count)
}

let ints = makeArray(repeating: 0, count: 5)        // [0, 0, 0, 0, 0]
let strings = makeArray(repeating: "hi", count: 3)  // ["hi", "hi", "hi"]

// Generic transformation
func flatten<T>(_ array: [[T]]) -> [T] {
    return array.flatMap { $0 }
}

let matrix = [[1, 2], [3, 4], [5, 6]]
let flat = flatten(matrix)  // [1, 2, 3, 4, 5, 6]
```

---

## Generic Types

### Generic Classes

```swift
// Generic Stack
class Stack<Element> {
    private var items: [Element] = []
    
    func push(_ item: Element) {
        items.append(item)
    }
    
    func pop() -> Element? {
        return items.popLast()
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    var count: Int {
        return items.count
    }
}

let intStack = Stack<Int>()
intStack.push(1)
intStack.push(2)
print(intStack.pop())  // Optional(2)

let stringStack = Stack<String>()
stringStack.push("hello")
stringStack.push("world")
```

### Generic Structs

```swift
// Generic Queue
struct Queue<Element> {
    private var items: [Element] = []
    
    mutating func enqueue(_ item: Element) {
        items.append(item)
    }
    
    mutating func dequeue() -> Element? {
        return items.isEmpty ? nil : items.removeFirst()
    }
}

var queue = Queue<String>()
queue.enqueue("first")
queue.enqueue("second")
print(queue.dequeue())  // Optional("first")
```

### Generic Extensions

```swift
// Extend generic type
extension Stack {
    func peek() -> Element? {
        return items.last
    }
}

let stack = Stack<Int>()
stack.push(42)
print(stack.peek())  // Optional(42)
```

---

## Type Constraints

### Single Type Constraint

```swift
// T must conform to Equatable
func contains<T: Equatable>(_ item: T, in array: [T]) -> Bool {
    return array.contains(item)
}

print(contains(3, in: [1, 2, 3]))      // true
print(contains("a", in: ["a", "b"]))   // true

// T must conform to Comparable
func sorted<T: Comparable>(_ array: [T]) -> [T] {
    return array.sorted()
}

print(sorted([3, 1, 2]))     // [1, 2, 3]
print(sorted(["c", "a", "b"]))  // ["a", "b", "c"]
```

### Multiple Type Constraints

```swift
// Both T and U must conform to Equatable
func compare<T: Equatable, U: Equatable>(_ first: T, _ second: U) -> Bool {
    return "\(first)" == "\(second)"
}

// T must conform to both Equatable and Comparable
func extremes<T: Equatable & Comparable>(_ array: [T]) -> (min: T, max: T)? {
    guard let first = array.first else { return nil }
    var min = first, max = first
    
    for item in array {
        if item < min { min = item }
        if item > max { max = item }
    }
    
    return (min, max)
}

if let result = extremes([5, 2, 8, 1]) {
    print("Min: \(result.min), Max: \(result.max)")  // Min: 1, Max: 8
}
```

### Protocol Constraints

```swift
protocol Drawable {
    func draw()
}

class Shape: Drawable {
    func draw() { print("Drawing shape") }
}

class Circle: Shape {
    override func draw() { print("Drawing circle") }
}

// Only works with types conforming to Drawable
func drawAll<T: Drawable>(_ items: [T]) {
    for item in items {
        item.draw()
    }
}

let shapes: [Drawable] = [Shape(), Circle()]
drawAll(shapes)
```

---

## Associated Types

### Defining Associated Types

```swift
protocol Container {
    associatedtype Item
    
    mutating func append(_ item: Item)
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}

// Implementation 1
struct IntStack: Container {
    typealias Item = Int
    
    private var items: [Int] = []
    
    mutating func append(_ item: Int) {
        items.append(item)
    }
    
    var count: Int {
        return items.count
    }
    
    subscript(i: Int) -> Int {
        return items[i]
    }
}

// Implementation 2 - Type inferred
struct StringQueue: Container {
    private var items: [String] = []
    
    mutating func append(_ item: String) {
        items.append(item)
    }
    
    var count: Int {
        return items.count
    }
    
    subscript(i: Int) -> String {
        return items[i]
    }
}
```

---

## Generic Where Clauses

### Basic Where Clause

```swift
// Only works when Element is Equatable
func removeDuplicates<T: Equatable>(_ array: [T]) -> [T] {
    var result: [T] = []
    for item in array {
        if !result.contains(item) {
            result.append(item)
        }
    }
    return result
}

print(removeDuplicates([1, 2, 2, 3, 3, 3]))  // [1, 2, 3]
```

### Complex Where Clause

```swift
// Array-specific functionality
func append<T>(element: T, to array: inout [T]) where T: Equatable {
    if !array.contains(element) {
        array.append(element)
    }
}

var numbers: [Int] = [1, 2, 3]
append(element: 2, to: &numbers)  // No change
append(element: 4, to: &numbers)  // [1, 2, 3, 4]

// Multiple conditions
func compareArrays<T>(_ array1: [T], _ array2: [T]) -> Bool where T: Equatable, T: Comparable {
    return array1.sorted() == array2.sorted()
}
```

### Associated Type Where Clause

```swift
protocol KeyValueStore {
    associatedtype Key
    associatedtype Value
    
    func get(for key: Key) -> Value?
}

// Only accept stores where Key is String
func printAll<Store: KeyValueStore>(_ store: Store) where Store.Key == String {
    // Implementation
}
```

---

## 🎯 Best Practices

### 1. Use Meaningful Type Names
```swift
// ✅ Clear what it represents
func combine<First, Second>(_ first: First, _ second: Second) -> (First, Second)

// ❌ Cryptic
func combine<A, B>(_ first: A, _ second: B) -> (A, B)
```

### 2. Add Type Constraints When Needed
```swift
// ✅ Explicit constraint
func findIndex<T: Equatable>(_ item: T, in array: [T]) -> Int?

// ❌ Missing constraint
func findIndex<T>(_ item: T, in array: [T]) -> Int?  // Can't compare T
```

### 3. Use Where Clauses for Complex Requirements
```swift
// ✅ Clear why constraint is needed
extension Array where Element: Comparable {
    func isSorted() -> Bool {
        for i in 0..<count - 1 {
            if self[i] > self[i + 1] {
                return false
            }
        }
        return true
    }
}

// ❌ Hidden requirement
extension Array {
    func isSorted() -> Bool {
        // Will crash if Element is not comparable
    }
}
```

### 4. Leverage Type Inference
```swift
// ✅ Let compiler infer
let array = [1, 2, 3]
let first = first(in: array)  // Type inferred

// Explicit when clarity matters
let result: [Int] = filtered([1, 2, 3]) { $0 > 1 }
```

---

## ❌ Common Mistakes

### Mistake 1: Missing Type Constraint

**WRONG:**
```swift
// ❌ Can't compare - won't compile
func findIndex<T>(_ item: T, in array: [T]) -> Int? {
    for (index, element) in array.enumerated() {
        if element == item {  // ❌ T doesn't support ==
            return index
        }
    }
    return nil
}
```

**CORRECT:**
```swift
// ✅ Add Equatable constraint
func findIndex<T: Equatable>(_ item: T, in array: [T]) -> Int? {
    return array.firstIndex(of: item)
}
```

---

### Mistake 2: Over-generalizing

**WRONG:**
```swift
// ❌ Too generic - loses type safety and usefulness
func process<T>(_ item: T) {
    // Can't do anything with T
}
```

**CORRECT:**
```swift
// ✅ Add meaningful constraints
func process<T: Codable>(_ item: T) {
    let json = try JSONEncoder().encode(item)
}
```

---

### Mistake 3: Forgetting Type Parameters

**WRONG:**
```swift
// ❌ Compiler can't infer type
var array: [Int] = []
array = ["a", "b", "c"]  // Type mismatch
```

**CORRECT:**
```swift
// ✅ Specify type or use consistent types
var array: [String] = []
array = ["a", "b", "c"]
```

---

## Related Topics

- [Protocols](../../01-fundamentals/object-oriented-programming/protocols.md)
- [Functions](../../01-fundamentals/functions-and-closures/functions.md)
- [Advanced Protocols](../../01-fundamentals/object-oriented-programming/advanced-protocols.md)

---

**Master generics for flexible, reusable, type-safe code!**
