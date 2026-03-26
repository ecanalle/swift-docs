# Optionals in Swift

## Overview

Optionals are one of Swift's most distinctive features. They make nil-ability explicit, enabling you to represent the absence of a value as a first-class concept. Understanding optionals is fundamental to writing safe, expressive Swift code.

## Main Topics

- [Optional Basics](#optional-basics)
- [Unwrapping Optionals](#unwrapping-optionals)
- [Optional Chaining](#optional-chaining)
- [Nil Coalescing](#nil-coalescing)
- [Optional Binding](#optional-binding)
- [Guard Statements](#guard-statements)
- [Advanced Optional Patterns](#advanced-optional-patterns)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Optionals](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/thebasics#Optionals)
- [WWDC - Optionals Best Practices](https://developer.apple.com/videos/play/wwdc2016/403/)

---

## Optional Basics

### What is an Optional?

```swift
// Optional - value might be nil
var name: String? = "John"
name = nil

// Non-optional - value must be present
var age: Int = 25
// age = nil  // ❌ Compile error!

// Type representation
var optional: String?      // Syntactic sugar
var expanded: Optional<String>  // Same thing

// Optionals are enums internally
enum Optional<Wrapped> {
    case some(Wrapped)
    case none  // nil
}
```

### When to Use Optionals

```swift
// Value might not exist
let userInput: String? = readLine()

// Operation might fail
let number = Int("abc")  // nil

// Searching in collection
let index = array.firstIndex(of: value)  // Returns Int?

// Optional property
class User {
    let name: String      // Required
    let email: String?    // Optional email
    let phone: String?    // Optional phone
}
```

---

## Unwrapping Optionals

### Force Unwrap (Not Recommended)

```swift
var name: String? = "John"

// ❌ Dangerous - crashes if nil!
let unwrapped = name!
print(unwrapped)

// Only safe if you're 100% certain it's not nil
if userVerified {
    let verifiedName = name!  // OK in specific contexts
}
```

### Safe Unwrapping Methods

```swift
let name: String? = "John"

// 1. if-let (most common)
if let unwrapped = name {
    print("Name is \(unwrapped)")
} else {
    print("No name")
}

// 2. Guard statement
guard let unwrapped = name else {
    print("No name")
    return
}
print("Name is \(unwrapped)")

// 3. Switch
switch name {
case .some(let value):
    print("Name: \(value)")
case .none:
    print("No name")
}
```

---

## Optional Chaining

### Basic Chaining

```swift
class Address {
    var city: String?
}

class Person {
    var address: Address?
}

let person: Person? = Person()
person?.address?.city = "New York"

// Safe - stops at first nil
// If person or address is nil, nothing happens (no error)
```

### Chaining Methods

```swift
class Pet {
    func bark() {
        print("Woof!")
    }
}

class Person {
    var pet: Pet?
}

let person: Person? = Person()
person?.pet?.bark()  // Safe - only calls if not nil
```

### Checking Success

```swift
class Connection {
    func send(data: String) -> Bool {
        print("Sending: \(data)")
        return true
    }
}

let connection: Connection? = Connection()

// if you need to check if it executed
if connection?.send(data: "Hello") != nil {
    print("Message sent")
} else {
    print("Not sent - no connection")
}

// Subscript chaining
var array: [String]? = ["a", "b", "c"]
array?[0] = "x"  // Safe subscript
```

---

## Nil Coalescing

### Basic Operator ??

```swift
let name: String? = "John"
let defaultName = "Unknown"

// Use right side if left is nil
let displayName = name ?? defaultName
print(displayName)  // "John"

// Multiple coalescing
let first: String? = nil
let second: String? = nil
let third: String? = "Charlie"

let result = first ?? second ?? third ?? "Default"
print(result)  // "Charlie"
```

### With Collections

```swift
let nickname: String? = nil
let firstName: String? = "John"
let lastName: String? = "Doe"

// Returns first non-nil
let displayName = nickname ?? firstName ?? lastName ?? "Unknown"

// Practical example
let users: [String]? = nil
let count = users?.count ?? 0
```

---

## Optional Binding

### Single Binding

```swift
let value: String? = "Hello"

if let unwrapped = value {
    print(unwrapped)
}
```

### Multiple Bindings

```swift
let name: String? = "John"
let age: Int? = 30
let email: String? = "john@example.com"

// All must be non-nil
if let name = name, let age = age, let email = email {
    print("\(name), \(age), \(email)")
}

// With conditions
if let name = name, age ?? 0 > 18 {
    print("Adult: \(name)")
}

// Comma-separated for same variable
if let value = Int("42"), value > 0 {
    print("Positive number: \(value)")
}
```

### Early Exit

```swift
func processUser(name: String?, age: Int?, email: String?) {
    guard let name = name else {
        print("Name required")
        return
    }
    
    guard let age = age, age >= 18 else {
        print("Must be 18+")
        return
    }
    
    guard let email = email else {
        print("Email required")
        return
    }
    
    // All values are now non-nil
    print("Processing: \(name), \(age), \(email)")
}
```

---

## Guard Statements

### Guard Pattern

```swift
func validateUser(name: String?, age: Int?) {
    guard let name = name else {
        print("Name is required")
        return
    }
    
    guard let age = age else {
        print("Age is required")
        return
    }
    
    guard age >= 18 else {
        print("Must be 18 or older")
        return
    }
    
    // All conditions passed
    print("Valid user: \(name), age \(age)")
}
```

### Guard vs If-Let

```swift
// Guard: Early exit pattern
guard let value = optional else { return }
// ... continue with value

// If-let: Nested continuation
if let value = optional {
    // ... use value
} else {
    return
}

// Guard reads better for validation chains
guard let name = input.name else { throw ValidationError.missingName }
guard let age = input.age, age >= 18 else { throw ValidationError.underage }
guard !name.isEmpty else { throw ValidationError.emptyName }
// All checks passed, proceed
```

---

## Advanced Optional Patterns

### Optional Map/FlatMap

```swift
let name: String? = "John"

// Map: transform if not nil
let uppercase = name.map { $0.uppercased() }
print(uppercase)  // "JOHN"

// FlatMap: for optional-returning transformations
let number = Int("42")
let doubled = number.flatMap { value -> Int? in
    return value * 2
}
print(doubled)  // 84

// Chain operations
let text: String? = "123"
let result = text
    .flatMap { Int($0) }
    .map { $0 * 2 }
print(result)  // 246
```

### CompactMap in Collections

```swift
let values = ["1", "2", "abc", "4"]

// Filter out nils when converting
let ints = values.compactMap { Int($0) }
print(ints)  // [1, 2, 4]

// With optionals in array
let optionalNumbers: [Int?] = [1, nil, 3, nil, 5]
let nonnull = optionalNumbers.compactMap { $0 }
print(nonnull)  // [1, 3, 5]
```

### Optional Subscripts

```swift
var scores: [String: Int]? = ["player1": 100]

// Safe subscript access
let score = scores?["player1"]  // Int??
let unwrapped = scores?["player1"] ?? 0  // Int
```

---

## 🎯 Best Practices

### 1. Use Optionals Explicitly
- Only when value can be nil
- Non-optional is the default choice
- Clear intent helps maintainability

### 2. Prefer Safe Unwrapping
- Use if-let or guard
- Avoid force unwrapping (!)
- Pattern match when appropriate

### 3. Use Nil Coalescing for Defaults
- `value ?? defaultValue` is cleaner
- Reduces nested if statements
- Express intent clearly

### 4. Optional Chaining for Safety
- No crashes with optional chaining
- Returns optional result
- Works with methods and subscripts

### 5. Avoid Optional Pyramids
```swift
// ❌ Pyramid of doom
if let a = optA {
    if let b = optB {
        if let c = optC {
            doSomething(a, b, c)
        }
    }
}

// ✅ Flat structure
if let a = optA, let b = optB, let c = optC {
    doSomething(a, b, c)
}
```

---

## ❌ Common Mistakes

### Mistake 1: Force Unwrapping Non-Validated Input

**WRONG:**
```swift
let userID = userInput!  // Crashes if input is nil
```

**CORRECT:**
```swift
guard let userID = userInput else {
    print("User ID is required")
    return
}
```

---

### Mistake 2: Ignoring Optional Results

**WRONG:**
```swift
var text: String? = "Hello"
text = nil
let uppercase = text.uppercased()  // ❌ Compiler error
```

**CORRECT:**
```swift
var text: String? = "Hello"
text = nil
let uppercase = text?.uppercased()  // ✅ nil if text is nil
```

---

### Mistake 3: Nested Optional Unwrapping

**WRONG:**
```swift
if let name = firstName {
    if let age = userAge {
        if let email = userEmail {
            processUser(name, age, email)
        }
    }
}
```

**CORRECT:**
```swift
if let name = firstName, let age = userAge, let email = userEmail {
    processUser(name, age, email)
}
```

---

### Mistake 4: Overusing Optional Chaining

**WRONG:**
```swift
let name = user?.profile?.name?.uppercase()?.prefix(1)
// Hard to debug if something fails silently
```

**BETTER:**
```swift
guard let name = user?.profile?.name else { return }
let initial = name.uppercased().prefix(1)
```

---

## Related Topics

- [Error Handling](error-handling.md)
- [Type System](data-types.md)
- [Guard Statements](#guard-statements)

---

**Optionals make Swift safe and expressive. Master them!**
