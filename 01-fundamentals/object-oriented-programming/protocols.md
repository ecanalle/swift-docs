# Protocols and Interfaces

## Overview

Protocols define a blueprint of methods, properties, and other requirements. They're central to writing flexible, reusable Swift code and are Swift's way to provide interface-based programming.

## Main Topics

- [Protocol Basics](#protocol-basics)
- [Property Requirements](#property-requirements)
- [Method Requirements](#method-requirements)
- [Protocol Inheritance](#protocol-inheritance)
- [Protocol Conformance](#protocol-conformance)
- [Associated Types](#associated-types)
- [Protocol Composition](#protocol-composition)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Protocols](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols)

---

## Protocol Basics

### Defining Protocols

```swift
// Basic protocol
protocol Vehicle {
    var brand: String { get }
    var speed: Int { get set }
    
    func startEngine()
    func stopEngine()
}

// Protocol with optional requirements
@objc protocol Drawable {
    @objc optional func draw()
}

// Protocol with initializers
protocol Named {
    init(name: String)
}
```

### Conforming to Protocols

```swift
struct Car: Vehicle {
    var brand: String
    var speed: Int
    
    func startEngine() {
        print("\(brand) car engine started")
    }
    
    func stopEngine() {
        print("\(brand) car engine stopped")
    }
}

let tesla = Car(brand: "Tesla", speed: 0)
tesla.startEngine()  // "Tesla car engine started"

// Multiple protocol conformance
struct Bicycle: Vehicle, Equatable {
    var brand: String
    var speed: Int
    
    func startEngine() {
        print("Bicycle pedaling")
    }
    
    func stopEngine() {
        print("Bicycle stopped")
    }
    
    // Equatable requirement
    static func == (lhs: Bicycle, rhs: Bicycle) -> Bool {
        return lhs.brand == rhs.brand
    }
}
```

---

## Property Requirements

### Gettable Properties

```swift
protocol HasName {
    var name: String { get }
}

// Can implement as stored or computed property
struct Person: HasName {
    var name: String  // Stored property satisfies get-only requirement
}

class Animal: HasName {
    var name: String {  // Computed property satisfies get-only requirement
        return "Anonymous"
    }
}
```

### Gettable and Settable Properties

```swift
protocol Resizable {
    var width: Int { get set }
    var height: Int { get set }
}

struct Window: Resizable {
    var width: Int
    var height: Int
}

var window = Window(width: 800, height: 600)
window.width = 1024  // Can both get and set
```

### Type Properties

```swift
protocol Named {
    static var typeName: String { get }
    var instanceName: String { get }
}

struct MyStruct: Named {
    static var typeName: String {
        return "MyStruct"
    }
    
    var instanceName: String {
        return "instance"
    }
}
```

---

## Method Requirements

### Basic Method Requirements

```swift
protocol Drawable {
    func draw()
    func erase()
}

class Canvas: Drawable {
    func draw() {
        print("Drawing on canvas")
    }
    
    func erase() {
        print("Erasing canvas")
    }
}

// Protocol with parameters and return types
protocol Comparable {
    func compare(to other: Self) -> Int  // Returns -1, 0, or 1
}

struct Version: Comparable {
    var major: Int
    var minor: Int
    
    func compare(to other: Version) -> Int {
        if self.major != other.major {
            return self.major < other.major ? -1 : 1
        }
        if self.minor != other.minor {
            return self.minor < other.minor ? -1 : 1
        }
        return 0
    }
}
```

### Mutating Method Requirements

```swift
protocol Mutable {
    mutating func update()
}

// Struct implementation
struct Counter: Mutable {
    var count = 0
    
    mutating func update() {
        count += 1
    }
}

// Class implementation (doesn't need mutating)
class ClassCounter: Mutable {
    var count = 0
    
    func update() {
        count += 1
    }
}
```

---

## Protocol Inheritance

Protocols can inherit from other protocols:

```swift
protocol Named {
    var name: String { get }
}

protocol Described: Named {
    var description: String { get }
}

protocol Completable: Described {
    var isComplete: Bool { get set }
    func complete()
}

struct Task: Completable {
    var name: String
    var description: String
    var isComplete: Bool
    
    func complete() {
        var task = self
        task.isComplete = true
    }
}
```

---

## Protocol Conformance

### Extension Conformance

```swift
protocol Drawable {
    func draw()
}

struct Square {
    var side: Int
}

// Add protocol conformance via extension
extension Square: Drawable {
    func draw() {
        print("Drawing square with side \(side)")
    }
}

let square = Square(side: 10)
square.draw()  // "Drawing square with side 10"
```

### Default Implementations

```swift
protocol Logger {
    func log(_ message: String)
}

// Provide default implementation in extension
extension Logger {
    func log(_ message: String) {
        print("[\(Date())]: \(message)")
    }
}

struct ConsoleLogger: Logger {
    // Uses default implementation
}

let logger = ConsoleLogger()
logger.log("Hello")  // "[2024-01-15 10:30:00 +0000]: Hello"
```

---

## Associated Types

Associated types define placeholder names for types used in protocol methods:

```swift
protocol Container {
    associatedtype Item
    
    mutating func append(_ item: Item)
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}

struct Stack<Element>: Container {
    typealias Item = Element  // Can be explicit
    
    private var items: [Element] = []
    
    mutating func append(_ item: Element) {
        items.append(item)
    }
    
    var count: Int {
        return items.count
    }
    
    subscript(i: Int) -> Element {
        return items[i]
    }
}

var intStack = Stack<Int>()
intStack.append(1)
intStack.append(2)
print(intStack.count)  // 2
```

---

## Protocol Composition

Combining multiple protocols:

```swift
protocol Named {
    var name: String { get }
}

protocol Dated {
    var date: Date { get }
}

// Using protocol composition
func display(_ item: Named & Dated) {
    print("\(item.name) - \(item.date)")
}

struct Article: Named, Dated {
    var name: String
    var date: Date
}

let article = Article(name: "Swift Tips", date: Date())
display(article)

// Type that satisfies both protocols
let composed: Named & Dated = article
```

---

## 🎯 Best Practices

### 1. Protocol names should indicate what they do
- Use adjectives for capability protocols: `Drawable`, `Encodable`
- Use nouns for type protocols: `Vehicle`, `Animal`

### 2. Keep protocols focused
- One responsibility per protocol
- Easier to compose and test

### 3. Use extensions for default implementations
- Provides fallback behavior
- Reduces code duplication

### 4. Prefer protocol types to concrete types
- Write `func process(_ item: Drawable)` not `func process(_ item: Square)`

### 5. Use associated types for generic behavior
- More flexible than hardcoded types
- Enables protocol-based generics

---

## ❌ Common Mistakes

### Mistake 1: Overly Complex Protocols

**WRONG:**
```swift
protocol AllInOne {
    var name: String { get }
    var age: Int { get }
    var email: String { get }
    func draw()
    func run()
    func speak()
}
```

**CORRECT:**
```swift
protocol Named {
    var name: String { get }
}

protocol Drawable {
    func draw()
}

protocol Runnable {
    func run()
}
```

---

### Mistake 2: Forcing Conformance When Not Needed

**WRONG:**
```swift
protocol Entity: Codable, Equatable, Hashable {
    // Everything must implement all three
}
```

**CORRECT:**
```swift
protocol Entity {
    var id: UUID { get }
}

struct User: Entity, Codable, Equatable {
    let id: UUID
}
```

---

### Mistake 3: Not Using Default Implementations

**WRONG:**
```swift
protocol Logger {
    func log(_ message: String)
}

struct ConsoleLogger: Logger {
    func log(_ message: String) {
        print("[\(Date())]: \(message)")
    }
}

struct FileLogger: Logger {
    func log(_ message: String) {
        print("[\(Date())]: \(message)")
        // Also write to file
    }
}
```

**CORRECT:**
```swift
protocol Logger {
    func log(_ message: String)
}

extension Logger {
    func log(_ message: String) {
        print("[\(Date())]: \(message)")
    }
}

struct FileLogger: Logger {
    func log(_ message: String) {
        Logger.log(self)  // Use inherited version
        // Also write to file
    }
}
```

---

## Related Topics

- [Classes and Structures](classes-and-structures.md)
- [Generics](../../02-architecture/generics.md)
- [Protocol-Oriented Programming](../../02-architecture/protocol-oriented-programming.md)

---

**Master protocols to write flexible, maintainable Swift code!**
