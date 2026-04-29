# Swift Advanced Topics - Beyond the Basics 🎯

## Overview
Master advanced Swift concepts that separate intermediate developers from experts. Explore memory safety, advanced generics, powerful protocols, type erasure, and concurrent programming patterns that enable building scalable, performant apps.

## Main Topics
- [Advanced Protocols](#advanced-protocols) - Protocol composition and extensions
- [Generics Deep Dive](#generics-deep-dive) - Type parameters and constraints
- [Memory Management](#memory-management) - References, value types, weak/unowned
- [Type Erasure](#type-erasure) - Working with existential types
- [Advanced Operators](#advanced-operators) - Custom operators and precedence
- [Property Wrappers](#property-wrappers) - Reusable property behavior
- [Best Practices](#-best-practices) - Design principles
- [Common Mistakes](#-common-mistakes-anti-patterns) - Pitfalls

## Official Documentation
- [Apple: Swift Language Guide](https://docs.swift.org/swift-book)
- [Apple: Advanced Swift Operators](https://docs.swift.org/swift-book/LanguageGuide/AdvancedOperators.html)
- [Apple: Generics](https://docs.swift.org/swift-book/LanguageGuide/Generics.html)

---

## Advanced Protocols

### Protocol Composition

```swift
// ✅ Correct: Composing multiple protocols
protocol Drawable {
    func draw()
}

protocol Animatable {
    func animate()
}

protocol Identifiable {
    var id: UUID { get }
}

// Combine protocols using composition
typealias DrawableAnimatable = Drawable & Animatable & Identifiable

class AnimatedShape: DrawableAnimatable {
    let id = UUID()
    
    func draw() {
        print("Drawing shape")
    }
    
    func animate() {
        print("Animating shape")
    }
}

// Use composed type
func processItem(_ item: DrawableAnimatable) {
    item.draw()
    item.animate()
    print("ID: \(item.id)")
}
```

### Conditional Protocol Conformance

```swift
// ✅ Correct: Protocols with associated type constraints
protocol Container {
    associatedtype Element
    var items: [Element] { get }
}

extension Container where Element: Comparable {
    func sorted() -> [Element] {
        return items.sorted()
    }
}

struct IntContainer: Container {
    let items: [Int]
}

struct StringContainer: Container {
    let items: [String]
}

// Only types with Comparable elements get sorted()
let intContainer = IntContainer(items: [3, 1, 2])
print(intContainer.sorted())  // ✅ Works

let stringContainer = StringContainer(items: ["c", "a", "b"])
print(stringContainer.sorted())  // ✅ Works
```

### Self and Self Requirements

```swift
// ✅ Correct: Using Self for type-safe protocols
protocol Copyable {
    func copy() -> Self
}

protocol Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool
}

class Document: Copyable {
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    func copy() -> Self {
        return Document(content: content) as! Self
    }
}

// Self ensures the exact type is returned
let original = Document(content: "Hello")
let copied = original.copy()  // Type: Document, not Copyable
```

---

## Generics Deep Dive

### Generic Functions with Constraints

```swift
// ✅ Correct: Generics with multiple constraints
func findCommonElements<T: Sequence, U: Sequence>(_ seq1: T, _ seq2: U) -> [T.Element]
where T.Element: Equatable & Hashable, T.Element == U.Element {
    let set1 = Set(seq1)
    let set2 = Set(seq2)
    return Array(set1.intersection(set2))
}

// Usage
let array1 = [1, 2, 3, 4, 5]
let array2 = [3, 4, 5, 6, 7]
let common = findCommonElements(array1, array2)
print(common)  // [3, 4, 5] (order may vary)
```

### Generic Types with Associated Types

```swift
// ✅ Correct: Complex generic with associated types
protocol DataSource {
    associatedtype Item
    associatedtype Iterator: IteratorProtocol where Iterator.Element == Item
    
    func makeIterator() -> Iterator
}

class ArrayDataSource<Element>: DataSource {
    let items: [Element]
    
    init(items: [Element]) {
        self.items = items
    }
    
    func makeIterator() -> IndexingIterator<[Element]> {
        return items.makeIterator()
    }
}

// Usage
let numbers = ArrayDataSource(items: [1, 2, 3, 4, 5])
for number in numbers {
    print(number)
}
```

### Generic Constraints with Where Clause

```swift
// ✅ Correct: Constraining generics with where clauses
func printIfEqual<T>(_ a: T, _ b: T) where T: Equatable {
    if a == b {
        print("Values are equal")
    } else {
        print("Values are different")
    }
}

// Works with any Equatable type
printIfEqual(5, 5)           // ✅ Equal
printIfEqual("hello", "world")  // ✅ Different
```

---

## Memory Management

### Reference Cycles and Weak References

```swift
// ✅ Correct: Breaking reference cycles with weak
class Parent {
    let name: String
    var child: Child?
    
    init(name: String) {
        self.name = name
        print("Parent \(name) initialized")
    }
    
    deinit {
        print("Parent \(name) deallocated")
    }
}

class Child {
    let name: String
    weak var parent: Parent?  // ✅ Weak to break cycle
    
    init(name: String, parent: Parent) {
        self.name = name
        self.parent = parent
        print("Child \(name) initialized")
    }
    
    deinit {
        print("Child \(name) deallocated")
    }
}

// Usage
var parent: Parent? = Parent(name: "Alice")
parent?.child = Child(name: "Bob", parent: parent!)

parent = nil  // Both deallocate properly
// Output:
// Parent Alice initialized
// Child Bob initialized
// Parent Alice deallocated
// Child Bob deallocated
```

### Value Types vs Reference Types

```swift
// ✅ Correct: Understanding value vs reference semantics

// Value Type (Struct) - copied on assignment
struct Location {
    var latitude: Double
    var longitude: Double
}

var home = Location(latitude: 40.7128, longitude: -74.0060)
var work = home
work.latitude = 40.7580  // Doesn't affect home

print("Home: \(home.latitude)")  // 40.7128
print("Work: \(work.latitude)")  // 40.7580

// Reference Type (Class) - shared on assignment
class Route {
    var distance: Double
    
    init(distance: Double) {
        self.distance = distance
    }
}

var commute = Route(distance: 10)
var backup = commute
backup.distance = 20  // Affects both

print("Commute: \(commute.distance)")  // 20
print("Backup: \(backup.distance)")   // 20
```

### Unowned References

```swift
// ✅ Correct: Using unowned when lifetime is guaranteed
class Department {
    let name: String
    var manager: Manager?
    
    init(name: String) {
        self.name = name
    }
    
    deinit {
        print("Department deallocated")
    }
}

class Manager {
    let name: String
    unowned let department: Department  // ✅ Unowned - lifetime guaranteed
    
    init(name: String, department: Department) {
        self.name = name
        self.department = department
    }
    
    deinit {
        print("Manager deallocated")
    }
}

// Manager can't exist without Department
let dept = Department(name: "Engineering")
dept.manager = Manager(name: "Alice", department: dept)

// Both deallocate when dept is deallocated
```

---

## Type Erasure

### Using AnySequence

```swift
// ✅ Correct: Type erasure for sequences
protocol CustomSequence {
    associatedtype Element
    func makeIterator() -> AnyIterator<Element>
}

struct CountingSequence: CustomSequence {
    let max: Int
    
    func makeIterator() -> AnyIterator<Int> {
        var current = 0
        return AnyIterator {
            current += 1
            return current <= self.max ? current : nil
        }
    }
}

// Type erase to hide underlying type
let erased: AnySequence<Int> = AnySequence(CountingSequence(max: 5))

for number in erased {
    print(number)  // 1, 2, 3, 4, 5
}
```

### Creating Custom Type Erasures

```swift
// ✅ Correct: Building custom type-erased wrapper
protocol Drawable {
    func draw()
}

struct AnyDrawable: Drawable {
    private let drawBox: () -> Void
    
    init<T: Drawable>(_ base: T) {
        self.drawBox = base.draw
    }
    
    func draw() {
        drawBox()
    }
}

class Circle: Drawable {
    func draw() {
        print("Drawing circle")
    }
}

class Square: Drawable {
    func draw() {
        print("Drawing square")
    }
}

// Use type-erased wrapper
var shapes: [AnyDrawable] = [
    AnyDrawable(Circle()),
    AnyDrawable(Square()),
    AnyDrawable(Circle())
]

for shape in shapes {
    shape.draw()
}
```

---

## Advanced Operators

### Custom Operators

```swift
// ✅ Correct: Defining custom operators
infix operator **: { MultiplicationPrecedence }  // Power operator

extension Int {
    static func ** (base: Int, exponent: Int) -> Int {
        var result = 1
        for _ in 0..<exponent {
            result *= base
        }
        return result
    }
}

// Usage
let result = 2 ** 10
print(result)  // 1024

// Define custom precedence group
precedencegroup PowerPrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator ^: PowerPrecedence

extension Double {
    static func ^ (base: Double, exponent: Int) -> Double {
        return pow(base, Double(exponent))
    }
}

// Right associativity: 2^3^2 = 2^(3^2) = 2^9 = 512
```

### Operator Overloading

```swift
// ✅ Correct: Overloading standard operators
struct Vector {
    let x: Double
    let y: Double
    
    // Vector addition
    static func + (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    // Scalar multiplication
    static func * (vector: Vector, scalar: Double) -> Vector {
        return Vector(x: vector.x * scalar, y: vector.y * scalar)
    }
    
    // Dot product
    static func * (lhs: Vector, rhs: Vector) -> Double {
        return lhs.x * rhs.x + lhs.y * rhs.y
    }
    
    // Negation
    static prefix func - (vector: Vector) -> Vector {
        return Vector(x: -vector.x, y: -vector.y)
    }
    
    // Equality
    static func == (lhs: Vector, rhs: Vector) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

// Usage
let v1 = Vector(x: 1, y: 2)
let v2 = Vector(x: 3, y: 4)
let sum = v1 + v2  // (4, 6)
let scaled = v1 * 2  // (2, 4)
let dot = v1 * v2  // 11.0
let neg = -v1  // (-1, -2)
```

---

## Property Wrappers

### Creating Custom Property Wrappers

```swift
// ✅ Correct: Building reusable property behavior
@propertyWrapper
struct Clamped {
    private var value: Double
    let min: Double
    let max: Double
    
    init(wrappedValue: Double, min: Double, max: Double) {
        self.min = min
        self.max = max
        self.value = Swift.max(min, Swift.min(max, wrappedValue))
    }
    
    var wrappedValue: Double {
        get { value }
        set { value = Swift.max(min, Swift.min(max, newValue)) }
    }
    
    var projectedValue: (min: Double, max: Double) {
        return (min, max)
    }
}

class TemperatureController {
    @Clamped(min: -273, max: 1000) var celsius: Double = 20
    @Clamped(min: -100, max: 200) var humidity: Double = 50
}

// Usage
var controller = TemperatureController()
controller.celsius = 50    // ✅ Valid
controller.celsius = 2000  // ✅ Clamped to 1000
controller.celsius = -400  // ✅ Clamped to -273

print(controller.$celsius)  // (min: -273.0, max: 1000.0)
```

### Property Wrapper with Observable Pattern

```swift
// ✅ Correct: Wrapper for reactive updates
@propertyWrapper
class Observable<T> {
    private var value: T
    private var observers: [(T) -> Void] = []
    
    init(wrappedValue: T) {
        self.value = wrappedValue
    }
    
    var wrappedValue: T {
        get { value }
        set {
            value = newValue
            notifyObservers()
        }
    }
    
    func subscribe(_ observer: @escaping (T) -> Void) {
        observers.append(observer)
        observer(value)  // Notify immediately
    }
    
    private func notifyObservers() {
        observers.forEach { $0(value) }
    }
}

class UserModel {
    @Observable var name: String = ""
    @Observable var age: Int = 0
}

// Usage
let user = UserModel()
user.$name.subscribe { newName in
    print("Name changed to: \(newName)")
}

user.name = "Alice"  // Prints: "Name changed to: Alice"
```

---

## ✅ Best Practices

### Practice 1: Prefer Value Types
**DO:**
```swift
// ✅ Use struct for data models
struct User {
    let id: Int
    var name: String
}

// ✅ Use class only for reference semantics
class NetworkManager {
    // Manages state across the app
}
```

### Practice 2: Use Generic Constraints Effectively
**DO:**
```swift
// ✅ Clear constraints prevent errors at compile time
func process<T: Sequence>(_ items: T) where T.Element: Hashable {
    // Compiler ensures T is a sequence of hashable elements
}
```

### Practice 3: Prefer Weak Over Unowned
**DO:**
```swift
// ✅ Weak is safer - handles nil gracefully
class Observer {
    weak var delegate: Delegate?
}

// ✅ Unowned only when lifetime is guaranteed
class Child {
    unowned let parent: Parent
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Reference Cycles Without Weak
**WRONG:**
```swift
// ❌ Memory leak - circular reference
class A {
    var b: B?
}

class B {
    var a: A?  // Prevents both from deallocating
}

var a: A? = A()
a?.b = B()
a?.b?.a = a
a = nil  // Neither deallocates - leak!
```

**CORRECT:**
```swift
// ✅ Break cycle with weak
class B {
    weak var a: A?  // Won't prevent deallocation
}
```

### Mistake 2: Excessive Use of Class
**WRONG:**
```swift
// ❌ Using class for simple data
class Point {
    var x: Double
    var y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// Every Point is a heap allocation + reference counting overhead
```

**CORRECT:**
```swift
// ✅ Use struct for value types
struct Point {
    var x: Double
    var y: Double
}

// Stack allocated, better performance
```

### Mistake 3: Over-Constraining Generics
**WRONG:**
```swift
// ❌ Too specific - limits usability
func process<T: NSObject & Codable>(items: [T]) {
    // Works only with NSObject subclasses that are Codable
}
```

**CORRECT:**
```swift
// ✅ Constrain only what's necessary
func process<T: Codable>(items: [T]) {
    // Works with any Codable type
}
```

### Mistake 4: Ignoring Memory Leaks in Closures
**WRONG:**
```swift
// ❌ Closure captures self, preventing deallocation
class ViewController {
    func loadData() {
        request.onComplete = {
            self.updateUI()  // self can't deallocate
        }
    }
}
```

**CORRECT:**
```swift
// ✅ Capture list weakly
request.onComplete = { [weak self] in
    self?.updateUI()
}
```

---

## 🔗 Related Topics
- [Concurrency & Async](async-concurrency.md) - Swift concurrency patterns
- [Memory Management](../02-architecture/memory-management.md) - Deep dive
- [Functional Programming](../02-architecture/functional-programming.md) - Advanced patterns
- [Protocol-Oriented Design](../02-architecture/protocol-oriented-design.md) - Design philosophy
- [Performance Optimization](performance-optimization.md) - Memory and CPU optimization
