# Swift Fundamentals 🎯

## Overview

Swift's foundation begins with understanding types, optionals, and operators. This guide covers the essential building blocks that every Swift developer must master: value types vs reference types, type safety, optional handling, and control flow patterns that form the basis of all Swift code.

## Main Topics
- [Types & Value Semantics](#types--value-semantics) - Structs, enums, and classes
- [Type Safety & Inference](#type-safety--inference) - Swift's type system
- [Optionals](#optionals) - Handling absence of values
- [Operators](#operators) - Arithmetic, logical, and custom operators
- [Control Flow](#control-flow) - Conditionals and loops
- [✅ Best Practices](#-best-practices) - Idiomatic Swift patterns
- [❌ Common Mistakes](#-common-mistakes-anti-patterns) - Anti-patterns to avoid

## Official Documentation
- [Apple: Swift Language Guide - Types](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/types)
- [Apple: Swift Language Guide - Optionals](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/optionalchaining)
- [Apple: Swift Language Guide - Operators](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators)

---

## Types & Value Semantics

### Understanding Value vs Reference Types

Swift distinguishes between **value types** (structs, enums) that copy on assignment and **reference types** (classes) that share references.

```swift
// ✅ Correct: Using value semantics for data models
struct Point {
    var x: Double
    var y: Double
    
    mutating func translate(by offset: Point) {
        self.x += offset.x
        self.y += offset.y
    }
}

var point1 = Point(x: 0, y: 0)
var point2 = point1
point2.x = 10

print(point1.x)  // 0 - independent copy
print(point2.x)  // 10

// ✅ Correct: Using reference types for shared behavior
class DataStore {
    var data: [String: Any] = [:]
    
    func setValue(_ value: Any, forKey key: String) {
        data[key] = value
    }
}

let store1 = DataStore()
let store2 = store1
store2.setValue("test", forKey: "key")

print(store1.data["key"] ?? "missing")  // "test" - shared reference
```

**Key Points:**
- Structs: value semantics, thread-safe, no inheritance
- Enums: value semantics, powerful pattern matching
- Classes: reference semantics, inheritance, identity-based

```swift
// ❌ Wrong: Misusing class for simple data
class BadPoint {
    var x: Double
    var y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// Unnecessary complexity, memory overhead, and shared state issues
var bad1 = BadPoint(x: 0, y: 0)
var bad2 = bad1
bad2.x = 10

print(bad1.x)  // 10 - unintended shared modification!
```

### Enums for Type-Safe Alternatives

Enums provide type safety without the overhead of classes.

```swift
// ✅ Correct: Using enum for associated values
enum Result<Success, Failure> {
    case success(Success)
    case failure(Failure)
}

enum NetworkError: Error {
    case invalidURL
    case timeout
    case serverError(code: Int, message: String)
}

let result: Result<String, NetworkError> = .success("Data loaded")

switch result {
case .success(let data):
    print("Success: \(data)")
case .failure(.invalidURL):
    print("Invalid URL")
case .failure(.serverError(let code, let message)):
    print("Server error \(code): \(message)")
}

// ✅ Correct: Raw values for constants
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

let method = HTTPMethod.get.rawValue  // "GET"
```

```swift
// ❌ Wrong: Using strings for type-unsafe alternatives
enum BadNetworkError {
    case error(String)  // Too generic!
}

// Or worse, magic strings
let status = "error"  // What error? No type information

// Can't pattern match effectively
if status == "timeout" {
    // What about capitalization? What if typo?
}
```

---

## Type Safety & Inference

### Swift's Type System

Swift enforces compile-time type checking while allowing inference to reduce verbosity.

```swift
// ✅ Correct: Explicit type annotations where clarity matters
let name: String = "Alice"
let age: Int = 30
let isActive: Bool = true
let scores: [Int] = [95, 87, 92]
let metadata: [String: String] = ["created": "2026-01-01"]

// ✅ Correct: Type inference for obvious cases
let greeting = "Hello"  // Inferred as String
let count = 42          // Inferred as Int
let temperature = 98.6  // Inferred as Double
let items = [1, 2, 3]   // Inferred as [Int]

// ✅ Correct: Generic types with constraints
func findMax<T: Comparable>(_ items: [T]) -> T? {
    return items.max()
}

let maxInt = findMax([3, 1, 4, 1, 5])      // 5
let maxString = findMax(["zebra", "apple"]) // "zebra"

// ✅ Correct: Type aliases for clarity
typealias Coordinates = (x: Double, y: Double)

func getLocation() -> Coordinates {
    return (x: 10.5, y: 20.3)
}
```

```swift
// ❌ Wrong: Over-annotating obvious types
let message: String = "Hello"  // Unnecessary annotation
let number: Int = 5            // Let inference handle it
let array: Array<Int> = [1, 2, 3]  // Use [Int] instead

// ❌ Wrong: Implicit Any type
var anything = 5
anything = "string"  // Type mismatch!

// ❌ Wrong: Unclear generic constraints
func process<T>(item: T) {  // What can T actually do?
    // Can't use T effectively without constraints
}
```

### Type Casting and Downcasting

Safely work with polymorphic types using pattern matching.

```swift
// ✅ Correct: Safe downcasting with conditional binding
class Animal {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

class Dog: Animal {
    func bark() { print("Woof!") }
}

class Cat: Animal {
    func meow() { print("Meow!") }
}

let animals: [Animal] = [
    Dog(name: "Rex"),
    Cat(name: "Whiskers"),
    Dog(name: "Buddy")
]

for animal in animals {
    if let dog = animal as? Dog {
        dog.bark()
    } else if let cat = animal as? Cat {
        cat.meow()
    }
}

// ✅ Correct: Pattern matching in switch
for animal in animals {
    switch animal {
    case let dog as Dog:
        print("\(dog.name) barks")
    case let cat as Cat:
        print("\(cat.name) meows")
    default:
        print("\(animal.name) makes a sound")
    }
}
```

```swift
// ❌ Wrong: Force casting without verification
let animal: Animal = Dog(name: "Rex")
let dog = animal as! Dog  // Crashes if not a Dog!

// ❌ Wrong: Excessive use of Any type
func process(value: Any) {
    if let int = value as? Int {
        // Have to downcast repeatedly
    } else if let string = value as? String {
        // More downcasting
    }
}
```

---

## Optionals

### Understanding Optionals

Optionals represent the absence of a value, making nil safety explicit in the type system.

```swift
// ✅ Correct: Declaring optionals explicitly
var optionalName: String? = nil
var maybeNumber: Int? = 42
var possibleArray: [String]? = ["one", "two"]

// ✅ Correct: Safe unwrapping with if-let
func greet(name: String?) {
    if let name = name {
        print("Hello, \(name)!")
    } else {
        print("Hello, stranger!")
    }
}

// ✅ Correct: Guard for early exit
func processUser(id: Int?) -> String {
    guard let id = id else {
        return "Invalid ID"
    }
    
    return "Processing user \(id)"
}

// ✅ Correct: Nil coalescing operator
let title = optionalName ?? "Untitled"
let count = maybeNumber ?? 0

// ✅ Correct: Optional chaining
class User {
    var profile: Profile?
}

class Profile {
    var bio: String?
}

let user = User()
if let bio = user.profile?.bio {
    print("Bio: \(bio)")
}

// ✅ Correct: Multiple optional unwrapping
if let name = optionalName,
   let number = maybeNumber {
    print("\(name): \(number)")
}
```

```swift
// ❌ Wrong: Force unwrapping without verification
let unsafeValue = optionalName!  // Crashes if nil!

// ❌ Wrong: Checking optionals with == nil
if optionalName != nil {
    let name = optionalName!  // Still unsafe!
}

// ❌ Wrong: Implicit optionals when not needed
func getName() -> String! {  // Implicitly unwrapped optional
    return nil  // Forces unwrapping at call site
}

// ❌ Wrong: Ignoring optional values
let result: Int? = 42
let value = result ?? 0  // But now what was it originally?
```

### Optional Pattern Matching

Leverage optionals with pattern matching for elegant code.

```swift
// ✅ Correct: Pattern matching with optionals
enum Response {
    case success(String)
    case failure(Error)
}

let response: Response? = .success("Data loaded")

if case .success(let data)? = response {
    print("Got data: \(data)")
}

// ✅ Correct: Optional binding with pattern matching
if case let .success(data)? = response,
   data.contains("loaded") {
    print("Successfully loaded")
}
```

---

## Operators

### Arithmetic and Comparison Operators

```swift
// ✅ Correct: Using operators with type safety
let sum = 10 + 5           // 15
let difference = 10 - 5    // 5
let product = 10 * 5       // 50
let quotient = 10 / 5      // 2
let remainder = 10 % 3     // 1

let isGreater = 10 > 5     // true
let isEqual = 10 == 10     // true
let isNotEqual = 10 != 5   // true

// ✅ Correct: String concatenation
let greeting = "Hello" + ", " + "World!"

// ✅ Correct: Range operators
let range = 1...5          // Closed range [1, 2, 3, 4, 5]
let halfRange = 1..<5      // Half-open range [1, 2, 3, 4]

for i in range {
    print(i)
}
```

### Logical Operators

```swift
// ✅ Correct: Combining conditions with logical operators
let isAdult = age >= 18
let hasLicense = true
let canDrive = isAdult && hasLicense

let isFriday = false
let isHoliday = true
let isShortDay = isFriday || isHoliday

let shouldNotify = !isActive

// ✅ Correct: Ternary operator for simple conditions
let status = isActive ? "Active" : "Inactive"

// ✅ Correct: Short-circuit evaluation
func expensiveCheck() -> Bool {
    print("Expensive check called")
    return true
}

if isActive && expensiveCheck() {
    // expensiveCheck only called if isActive is true
}
```

```swift
// ❌ Wrong: Overcomplicating conditions
if isAdult == true && hasLicense == true {  // Unnecessary comparisons
    // ...
}

// ❌ Wrong: Unclear operator precedence
let result = a + b > c * d && e < f  // Confusing order of operations
```

### Custom Operators

Define domain-specific operators for clarity.

```swift
// ✅ Correct: Custom operator definition
infix operator ~=

func ~= (lhs: String, rhs: String) -> Bool {
    return lhs.lowercased() == rhs.lowercased()
}

let match = "Hello" ~= "hello"  // true

// ✅ Correct: Operator overloading for types
struct Vector {
    var x: Double
    var y: Double
    
    static func + (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func * (lhs: Vector, rhs: Double) -> Vector {
        return Vector(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

let v1 = Vector(x: 1, y: 2)
let v2 = Vector(x: 3, y: 4)
let sum = v1 + v2            // Vector(x: 4, y: 6)
let scaled = v1 * 2          // Vector(x: 2, y: 4)
```

---

## Control Flow

### Conditionals and Pattern Matching

```swift
// ✅ Correct: If-else with proper structure
if age < 13 {
    print("Child")
} else if age < 18 {
    print("Teen")
} else {
    print("Adult")
}

// ✅ Correct: Switch with exhaustive pattern matching
switch age {
case 0...12:
    print("Child")
case 13...19:
    print("Teen")
case 20...64:
    print("Adult")
case 65...:
    print("Senior")
default:
    print("Unknown age")
}

// ✅ Correct: Switch with associated values
enum NetworkStatus {
    case connected(speed: Int)
    case disconnected(reason: String)
}

let status = NetworkStatus.connected(speed: 100)

switch status {
case .connected(let speed):
    print("Connected at \(speed) Mbps")
case .disconnected(let reason):
    print("Disconnected: \(reason)")
}

// ✅ Correct: Labeled break for nested loops
outerLoop: for i in 1...3 {
    for j in 1...3 {
        if i * j == 4 {
            break outerLoop  // Exits outer loop
        }
    }
}
```

### Loops

```swift
// ✅ Correct: For-in loops with ranges
for i in 1...5 {
    print(i)
}

for i in stride(from: 0, to: 10, by: 2) {
    print(i)  // 0, 2, 4, 6, 8
}

// ✅ Correct: For-in with collections
let names = ["Alice", "Bob", "Charlie"]
for (index, name) in names.enumerated() {
    print("\(index): \(name)")
}

// ✅ Correct: While loops
var count = 0
while count < 5 {
    print(count)
    count += 1
}

// ✅ Correct: Repeat-while (do-while equivalent)
repeat {
    print(count)
    count -= 1
} while count > 0
```

```swift
// ❌ Wrong: Inefficient loops
for i in 0..<array.count {
    let item = array[i]  // Use for-in instead
}

// ❌ Wrong: Unnecessary while loops
var idx = 0
while idx < items.count {
    print(items[idx])  // Use for-in
    idx += 1
}
```

---

## ✅ Best Practices

### Choose Appropriate Types

**DO:**
```swift
// Value types for models
struct User {
    let id: Int
    let name: String
    let email: String
}

// Enums for state
enum LoadingState {
    case idle
    case loading
    case loaded(data: String)
    case error(Error)
}

// Classes only when needed
class APIClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
}
```

### Explicit Over Implicit

**DO:**
```swift
// Clear type annotations where appropriate
let userID: Int = 123
let isValid: Bool = true

// Descriptive variable names
let numberOfActiveUsers: Int = 42

// Explicit optionals
func getUser(id: Int) -> User?
```

### Handle Nil Safely

**DO:**
```swift
// Guard for early return
func processData(_ data: String?) -> String {
    guard let data = data, !data.isEmpty else {
        return "No data"
    }
    return data.uppercased()
}

// If-let for conditional logic
if let value = optionalValue {
    // Use value safely
}

// Nil coalescing for defaults
let title = optionalTitle ?? "Untitled"
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake: Overusing Force Unwrapping

**WRONG:**
```swift
// Crashes if nil
let name = optionalName!
let count = optionalArray!.count
let value = optionalDict!["key"]!
```

**CORRECT:**
```swift
// Safe unwrapping
if let name = optionalName {
    print("Name: \(name)")
}

guard let count = optionalArray?.count else {
    return
}

if let value = optionalDict?["key"] {
    print("Value: \(value)")
}
```

### Mistake: Implicit Optional Parameters

**WRONG:**
```swift
func getName() -> String! {
    // Function doesn't guarantee non-nil return
    return nil  // Still force unwraps at call site!
}

let name = getName()  // Crashes if nil
```

**CORRECT:**
```swift
func getName() -> String? {
    return "Alice"
}

if let name = getName() {
    print(name)
}
```

### Mistake: Poor Type Inference Assumptions

**WRONG:**
```swift
let data = "123"  // Inferred as String
let number = Int(data)  // Returns optional, not an Int!

let items = [1, "two", 3]  // Type error - mixed types
```

**CORRECT:**
```swift
let data = "123"
let number = Int(data) ?? 0  // Handle optional

let numbers: [Int] = [1, 2, 3]
let strings: [String] = ["one", "two"]
```

### Mistake: Ignoring Operator Precedence

**WRONG:**
```swift
let result = 2 + 3 * 4 == 14 && true || false
// Unclear what this evaluates to
```

**CORRECT:**
```swift
let multiplication = 2 + (3 * 4)  // 14
let isCorrect = (multiplication == 14)
let isTrueOr = (isCorrect && true) || false
```

---

## 🔗 Related Topics

- [**01-fundamentals/functions-and-closures.md**](functions-and-closures.md) - Functions and higher-order functions
- [**01-fundamentals/object-oriented-programming.md**](object-oriented-programming.md) - Classes, structs, and protocols
- [**01-fundamentals/animation-in-swift.md**](animation-in-swift.md) - Control flow in animations
- [**02-architecture/design-patterns.md**](../02-architecture/design-patterns.md) - Advanced type design patterns
- [**07-advanced/swift-advanced.md**](../07-advanced/swift-advanced.md) - Advanced Swift features
