# Advanced Protocols in Swift

## Overview

Protocols define blueprints for functionality. Beyond basics, Swift's protocol system supports powerful features like associated types, protocol composition, and default implementations that enable elegant, flexible designs.

## Main Topics

- [Associated Types](#associated-types)
- [Protocol Inheritance](#protocol-inheritance)
- [Protocol Composition](#protocol-composition)
- [Default Implementations](#default-implementations)
- [Self Requirements](#self-requirements)
- [Type Aliases in Protocols](#type-aliases-in-protocols)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Protocols](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols)

---

## Associated Types

### Basic Associated Types

```swift
// Protocol with associated type
protocol Container {
    associatedtype Item
    
    mutating func append(_ item: Item)
    var count: Int { get }
    subscript(i: Int) -> Item { get }
}

// Implementation 1: Array-like container
struct Stack<T>: Container {
    private var items: [T] = []
    
    typealias Item = T
    
    mutating func append(_ item: T) {
        items.append(item)
    }
    
    var count: Int {
        return items.count
    }
    
    subscript(i: Int) -> T {
        return items[i]
    }
}

// Implementation 2: String container
struct StringContainer: Container {
    typealias Item = String
    private var strings: [String] = []
    
    mutating func append(_ item: String) {
        strings.append(item)
    }
    
    var count: Int {
        strings.count
    }
    
    subscript(i: Int) -> String {
        strings[i]
    }
}
```

### Where Clauses in Associated Types

```swift
protocol Sequence {
    associatedtype Iterator
}

// Only works when Iterator is Equatable
extension Sequence where Iterator: Equatable {
    func hasDuplicate() -> Bool {
        var seen: [Iterator] = []
        // Check logic...
        return false
    }
}
```

---

## Protocol Inheritance

### Single Protocol Inheritance

```swift
protocol Animal {
    var name: String { get }
    func makeSound()
}

// Dog inherits from Animal
protocol Dog: Animal {
    func fetch()
}

// Implementation must conform to both
struct Labrador: Dog {
    var name: String
    
    func makeSound() {
        print("Woof!")
    }
    
    func fetch() {
        print("Fetching the ball!")
    }
}
```

### Multiple Protocol Inheritance

```swift
protocol Drawable {
    func draw()
}

protocol Resizable {
    func resize(width: Int, height: Int)
}

// Shape inherits from both
protocol Shape: Drawable & Resizable {
    var area: Double { get }
}

struct Circle: Shape {
    var radius: Double
    
    var area: Double {
        return Double.pi * radius * radius
    }
    
    func draw() {
        print("Drawing circle")
    }
    
    func resize(width: Int, height: Int) {
        // Implementation
    }
}
```

---

## Protocol Composition

### Using & to Compose Protocols

```swift
protocol Named {
    var name: String { get }
}

protocol Aged {
    var age: Int { get }
}

// Composition instead of new protocol
func greet(person: Named & Aged) {
    print("\(person.name) is \(person.age) years old")
}

class Person: Named, Aged {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

let person = Person(name: "John", age: 30)
greet(person: person)  // "John is 30 years old"
```

### Protocol Composition with Classes

```swift
protocol DataStore {
    func save(data: String)
    func load() -> String
}

protocol Logger {
    func log(_ message: String)
}

// Function accepts anything conforming to both
func process(store: DataStore & Logger) {
    store.log("Processing data...")
    store.save(data: "Important data")
}

class JSONStore: DataStore, Logger {
    func save(data: String) {
        print("Saving: \(data)")
    }
    
    func load() -> String {
        return "loaded data"
    }
    
    func log(_ message: String) {
        print("[LOG] \(message)")
    }
}

let store = JSONStore()
process(store: store)
```

---

## Default Implementations

### Using Extension for Defaults

```swift
protocol Printable {
    var description: String { get }
}

extension Printable {
    func printSelf() {
        print(description)
    }
    
    func printWithPreview() {
        print("▶ \(description)")
    }
}

struct Product: Printable {
    let name: String
    let price: Double
    
    var description: String {
        return "\(name) - $\(price)"
    }
    
    // Inherits printSelf() and printWithPreview()
}

let product = Product(name: "Laptop", price: 999.99)
product.printSelf()          // "Laptop - $999.99"
product.printWithPreview()   // "▶ Laptop - $999.99"
```

### Optional Methods

```swift
@objc protocol Camera {
    func takePhoto()
    
    @objc optional func recordVideo()
    @objc optional func zoomIn(factor: Double)
}

// ⚠️ Only works with classes, NSObject

class PhotoCamera: NSObject, Camera {
    func takePhoto() {
        print("Photo taken")
    }
    
    // Don't need to implement optional methods
}

let camera = PhotoCamera()
camera.takePhoto()  // ✅ Works
```

---

## Self Requirements

### Methods Returning Self

```swift
protocol Builder {
    func setName(_ name: String) -> Self
    func setAge(_ age: Int) -> Self
    func build() -> String
}

class PersonBuilder: Builder {
    var name: String = ""
    var age: Int = 0
    
    func setName(_ name: String) -> Self {
        self.name = name
        return self
    }
    
    func setAge(_ age: Int) -> Self {
        self.age = age
        return self
    }
    
    func build() -> String {
        return "\(name) (\(age))"
    }
}

// Fluent builder pattern
let person = PersonBuilder()
    .setName("John")
    .setAge(30)
    .build()
print(person)  // "John (30)"
```

### Class-Only Protocols

```swift
// Only classes can conform (not structs)
protocol Reference: AnyObject {
    var id: Int { get }
}

// ✅ Classes can conform
class User: Reference {
    var id: Int = 1
}

// ❌ Structs cannot conform
// struct Person: Reference { }
```

---

## Type Aliases in Protocols

### Simplifying Complex Types

```swift
protocol DataSource {
    typealias Data = [String: Any]
    
    func fetch() -> Data
}

class APIDataSource: DataSource {
    func fetch() -> [String: Any] {
        return ["key": "value"]
    }
}

// Type alias shorthand
// Without: func fetch() -> [String: Any]
// With: func fetch() -> Data (from protocol)
```

### Generic Type Aliases

```swift
protocol APIEndpoint {
    associatedtype Response: Codable
    
    var path: String { get }
    func decode(data: Data) throws -> Response
}

struct UserEndpoint: APIEndpoint {
    typealias Response = User
    
    var path: String { return "/users" }
    
    func decode(data: Data) throws -> User {
        return try JSONDecoder().decode(User.self, from: data)
    }
}

struct PostEndpoint: APIEndpoint {
    typealias Response = Post
    
    var path: String { return "/posts" }
    
    func decode(data: Data) throws -> Post {
        return try JSONDecoder().decode(Post.self, from: data)
    }
}
```

---

## 🎯 Best Practices

### 1. Use Associated Types for Flexibility
```swift
// ✅ Flexible - works with any item type
protocol Container {
    associatedtype Item
    func add(_ item: Item)
}

// ❌ Less flexible - locked to specific type
protocol StringContainer {
    func add(_ item: String)
}
```

### 2. Protocol Composition Over Inheritance
```swift
// ✅ Flexible composition
func process(store: DataStore & Logger) { }

// ❌ Less flexible - requires new protocol
protocol StoreWithLogging: DataStore, Logger { }
```

### 3. Document Associated Type Constraints
```swift
protocol GenericContainer {
    /// The type of elements stored
    /// Must be Equatable for comparison operations
    associatedtype Element: Equatable
}
```

### 4. Use Default Implementations Wisely
```swift
extension Displayable {
    // ✅ Sensible default, can override
    func display() {
        print(description)
    }
}
```

### 5. Keep Protocols Focused
```swift
// ✅ Single responsibility
protocol Saveable {
    func save()
}

protocol Loadable {
    func load()
}

// ❌ Too many responsibilities
protocol Persistent {
    func save()
    func load()
    func delete()
    func sync()
}
```

---

## ❌ Common Mistakes

### Mistake 1: Overusing Associated Types

**WRONG:**
```swift
// ❌ Associated type adds complexity unnecessarily
protocol SimpleContainer {
    associatedtype Item
    func add(_ item: Item)
}

// ✅ Simpler generic function
func add<T>(_ item: T, to container: inout [T]) { }
```

---

### Mistake 2: Protocol with Too Many Requirements

**WRONG:**
```swift
protocol Everything {
    func read()
    func write()
    func delete()
    func sync()
    func backup()
    func verify()
}
```

**CORRECT:**
```swift
protocol Readable { func read() }
protocol Writable { func write() }
protocol Deletable { func delete() }

// Compose as needed
func process(store: Readable & Writable) { }
```

---

### Mistake 3: Forgetting Default Implementations

**WRONG:**
```swift
protocol Logger {
    func log(_ message: String)
}

// Every conformer must implement
class ConsoleLogger: Logger {
    func log(_ message: String) {
        print(message)
    }
}

class FileLogger: Logger {
    func log(_ message: String) {
        writeToFile(message)
    }
}
```

**CORRECT:**
```swift
protocol Logger {
    func log(_ message: String)
}

extension Logger {
    // Default implementation
    func log(_ message: String) {
        print(message)
    }
}

// Can now use default
class JSONLogger: Logger {
    // Inherits default log
}
```

---

## Related Topics

- [Protocols Basics](protocols.md)
- [Generics](../../07-advanced/advanced-performance/generics.md)
- [Type System](data-types.md)

---

**Master advanced protocols for flexible, powerful designs!**
