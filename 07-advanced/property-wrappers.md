# Property Wrappers - Custom Getters and Setters

## Overview

Property Wrappers (iOS 13+) allow encapsulation of property logic in reusable components with `@propertyWrapper`. They abstract common patterns like validation, transformation, and observation.

## Main Topics

- [Basic Property Wrapper](#basic-property-wrapper)
- [Common Patterns](#common-patterns)
- [Composition](#composition)
- [Advanced Usage](#advanced-usage)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Property Wrappers](https://developer.apple.com/documentation/swift/propertywrapper)

---

## Basic Property Wrapper

### Structure

```swift
@propertyWrapper
struct Clamped {
    private var value: Int
    private let min: Int
    private let max: Int
    
    init(wrappedValue: Int, min: Int, max: Int) {
        self.min = min
        self.max = max
        self.value = max(min, min(wrappedValue, max))
    }
    
    var wrappedValue: Int {
        get { value }
        set { value = max(min, min(newValue, max)) }
    }
}

// Usage
class Player {
    @Clamped(min: 0, max: 100)
    var health: Int = 50
}

var player = Player()
player.health = 150  // Becomes 100
player.health = -10  // Becomes 0
print(player.health)  // 0
```

### With Initial Value

```swift
@propertyWrapper
struct Trimmed {
    private var value: String
    
    init(wrappedValue: String) {
        self.value = wrappedValue.trimmingCharacters(in: .whitespaces)
    }
    
    var wrappedValue: String {
        get { value }
        set { value = newValue.trimmingCharacters(in: .whitespaces) }
    }
}

class User {
    @Trimmed var name: String
    
    init(name: String) {
        self._name = Trimmed(wrappedValue: name)
    }
}

let user = User(name: "  John  ")
print(user.name)  // "John"
```

### ProjectedValue

```swift
@propertyWrapper
struct Validated {
    private var value: String
    var isValid: Bool = true
    
    var wrappedValue: String {
        get { value }
        set {
            value = newValue
            isValid = !newValue.isEmpty && newValue.count > 2
        }
    }
    
    init(wrappedValue: String) {
        self.value = wrappedValue
        self.isValid = !wrappedValue.isEmpty && wrappedValue.count > 2
    }
    
    // Projected value accessible via $propertyName
    var projectedValue: Bool { isValid }
}

class Form {
    @Validated var email: String = ""
}

var form = Form()
form.email = "ab"
print(form.$email)  // false
form.email = "john@example.com"
print(form.$email)  // true
```

---

## Common Patterns

### 1. Validation Wrapper

```swift
@propertyWrapper
struct Positive {
    private var value: Double
    
    init(wrappedValue: Double) {
        self.value = max(0, wrappedValue)
    }
    
    var wrappedValue: Double {
        get { value }
        set { value = max(0, newValue) }
    }
}

class Product {
    @Positive var price: Double = 9.99
    @Positive var discount: Double = 0
}

let product = Product()
product.price = -50  // Becomes 0
product.discount = -10  // Becomes 0
```

### 2. UserDefaults Wrapper

```swift
@propertyWrapper
struct UserDefault {
    let key: String
    let defaultValue: String
    
    var wrappedValue: String {
        get { UserDefaults.standard.string(forKey: key) ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

class Settings {
    @UserDefault(key: "username", defaultValue: "Guest")
    var username: String
    
    @UserDefault(key: "theme", defaultValue: "light")
    var theme: String
}

var settings = Settings()
settings.username = "John"  // Persists to UserDefaults
print(settings.username)  // "John" (even after restart)
```

### 3. Lazy Wrapper

```swift
@propertyWrapper
struct Lazy {
    private var _value: Value?
    private let initializer: () -> Value
    
    init(wrappedValue initializer: @escaping () -> Value) {
        self.initializer = initializer
        self._value = nil
    }
    
    var wrappedValue: Value {
        mutating get {
            if _value == nil {
                _value = initializer()
            }
            return _value!
        }
    }
}

class Configuration {
    @Lazy(wrappedValue: {
        print("Initializing heavy resource")
        return ExpensiveResource()
    })
    var resource: ExpensiveResource
}

let config = Configuration()
print("Ready")
_ = config.resource  // Prints "Initializing heavy resource"
```

### 4. Observable Wrapper

```swift
@propertyWrapper
class Observable {
    private var value: Value
    var onChange: ((Value) -> Void)?
    
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            onChange?(newValue)
        }
    }
    
    var projectedValue: Observable { self }
}

class ViewModel {
    @Observable var count: Int = 0
}

let vm = ViewModel()
vm.$count.onChange = { newValue in
    print("Count changed to \(newValue)")
}

vm.count = 5  // Prints "Count changed to 5"
vm.count = 10  // Prints "Count changed to 10"
```

---

## Composition

### Combining Wrappers

```swift
@propertyWrapper
struct Uppercased {
    private var value: String
    
    init(wrappedValue: String) {
        self.value = wrappedValue.uppercased()
    }
    
    var wrappedValue: String {
        get { value }
        set { value = newValue.uppercased() }
    }
}

@propertyWrapper
struct Trimmed {
    private var value: String
    
    init(wrappedValue: String) {
        self.value = wrappedValue.trimmingCharacters(in: .whitespaces)
    }
    
    var wrappedValue: String {
        get { value }
        set { value = newValue.trimmingCharacters(in: .whitespaces) }
    }
}

class Tag {
    @Uppercased @Trimmed var name: String = "  swift  "
}

let tag = Tag()
print(tag.name)  // "SWIFT"
```

### Wrapper with Multiple Values

```swift
@propertyWrapper
struct Range {
    private var value: Int
    let min: Int
    let max: Int
    
    init(wrappedValue: Int, min: Int, max: Int) {
        self.min = min
        self.max = max
        self.value = max(min, min(wrappedValue, max))
    }
    
    var wrappedValue: Int {
        get { value }
        set { value = max(min, min(newValue, max)) }
    }
    
    var projectedValue: ClosedRange<Int> {
        min...max
    }
}

class Settings {
    @Range(wrappedValue: 50, min: 0, max: 100)
    var brightness: Int
}

let settings = Settings()
print(settings.$brightness)  // 0...100
```

---

## Advanced Usage

### Generic Property Wrapper

```swift
@propertyWrapper
struct Debounced {
    private var _value: Value
    private var task: Task<Void, Never>?
    let delay: UInt64  // nanoseconds
    
    init(wrappedValue: Value, delay: TimeInterval = 0.3) {
        self._value = wrappedValue
        self.delay = UInt64(delay * 1_000_000_000)
    }
    
    var wrappedValue: Value {
        get { _value }
        set {
            task?.cancel()
            task = Task {
                try? await Task.sleep(nanoseconds: delay)
                if !Task.isCancelled {
                    _value = newValue
                }
            }
        }
    }
}

class SearchViewModel {
    @Debounced(delay: 0.5)
    var searchText: String = ""
}
```

### ThreadSafe Wrapper

```swift
@propertyWrapper
class ThreadSafe {
    private let lock = NSLock()
    private var _value: Value
    
    init(wrappedValue: Value) {
        self._value = wrappedValue
    }
    
    var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}

class Counter {
    @ThreadSafe var count: Int = 0
}

let counter = Counter()
DispatchQueue.global().async {
    counter.count = 1  // Thread-safe
}
```

### Inspectable (SwiftUI Integration)

```swift
@propertyWrapper
struct Inspectable {
    private var value: Value
    
    init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { value },
            set: { value = $0 }
        )
    }
}

// Use in SwiftUI
struct MyView: View {
    @Inspectable var text: String = "Hello"
    
    var body: some View {
        TextField("Text", text: $text)
    }
}
```

---

## 🎯 Best Practices

### 1. Clear Purpose
```swift
// ✅ Wrapper's purpose is obvious
@propertyWrapper
struct Positive {
    // Ensures value never goes negative
}

// ❌ Vague purpose
@propertyWrapper
struct ValueWrapper {
    // What does this do?
}
```

### 2. Document Behavior
```swift
/// Ensures value stays within bounds.
/// - Parameter min: Minimum allowed value
/// - Parameter max: Maximum allowed value
@propertyWrapper
struct Clamped {
    // Implementation
}
```

### 3. Use Projected Values Wisely
```swift
// ✅ Provide useful projected value
@propertyWrapper
struct Validated {
    var projectedValue: Bool { isValid }
}

// Allows: print(user.$email)

// ❌ No clear purpose for projection
var projectedValue: String { value.uppercased() }
```

---

## ❌ Common Mistakes

### Mistake 1: Forgetting wrappedValue

**WRONG:**
```swift
// ❌ Missing wrappedValue getter/setter
@propertyWrapper
struct Custom {
    private var value: Int
    
    // Where's wrappedValue?
}
```

**CORRECT:**
```swift
// ✅ Always define wrappedValue
@propertyWrapper
struct Custom {
    private var value: Int
    
    var wrappedValue: Int {
        get { value }
        set { value = newValue }
    }
}
```

---

### Mistake 2: Mutable Projected Value

**WRONG:**
```swift
// ❌ Projected value shouldn't be mutable
@propertyWrapper
struct Validated {
    var projectedValue: Bool {
        get { isValid }
        set { isValid = newValue }  // Confusing!
    }
}
```

**CORRECT:**
```swift
// ✅ Projected value is read-only or clearly purposeful
@propertyWrapper
struct Validated {
    var projectedValue: Bool { isValid }
}
```

---

### Mistake 3: Complex Logic in Wrapper

**WRONG:**
```swift
// ❌ Too much responsibility
@propertyWrapper
struct ComplexWrapper {
    var wrappedValue: Int {
        get {
            // 50 lines of complex logic
        }
        set {
            // 50 lines of complex logic
        }
    }
}
```

**CORRECT:**
```swift
// ✅ Keep wrapper focused
@propertyWrapper
struct Simple {
    private var value: Int
    private func validate(_ newValue: Int) -> Int {
        // Validation logic
    }
    
    var wrappedValue: Int {
        get { value }
        set { value = validate(newValue) }
    }
}
```

---

## Related Topics

- [SwiftUI Bindings](../../05-features/swiftui-basics.md)
- [Property Observers](properties-and-observers.md)
- [Generics](generics.md)

---

**Master Property Wrappers to encapsulate complex property logic!**
