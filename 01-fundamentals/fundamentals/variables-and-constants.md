# Variables, Constants, and Scope

## Overview

Variables and constants are the foundation of any program. Understanding how to declare, scope, and manage them properly leads to cleaner, safer code with fewer bugs.

## Main Topics

- [Variables vs Constants](#variables-vs-constants)
- [Declaration](#declaration)
- [Type Annotation](#type-annotation)
- [Scope](#scope)
- [Mutability](#mutability)
- [Memory and Lifecycle](#memory-and-lifecycle)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Variables and Constants](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/thebasics#Variables-and-Constants)

---

## Variables vs Constants

### Constants: Use by Default

```swift
// ❌ Variable (changes are possible)
var temperature = 25.0
temperature = 26.0  // OK but risky

// ✅ Constant (immutable)
let temperature = 25.0
// temperature = 26.0  // ❌ Compile error!

// When to use:
// - Constants: Default choice for most values
// - Variables: Only when value must truly change
```

### Benefits of Constants

```swift
// Constants are easier to reason about
let PI = 3.14159  // Never changes, safe to use everywhere

// Safer refactoring
let userID = 42
// Compiler warns if you accidentally reassign
// userID = 43  // Error!

// Thread safety
// Constants don't need synchronization
let config = loadConfiguration()  // Safe to share across threads
```

---

## Declaration

### Basic Declaration

```swift
// Variable
var count = 0
var name = "John"

// Constant
let maxAttempts = 3
let PI = 3.14159

// Multiple declaration
var x = 0, y = 0, z = 0

// With explicit type (optional but can be clearer)
let firstName: String = "John"
var age: Int = 30
```

### Time of Declaration

```swift
// Must be initialized when declared
let constant = 5
var variable = 10

// Or can delay initialization for computed properties
// But basic let/var must have a value

// However with properties:
class User {
    let id: Int
    
    init(id: Int) {
        self.id = id  // OK - initialized before constructor ends
    }
}
```

### Lazy Properties

```swift
class DataProcessor {
    // Only initialized when first accessed
    lazy var expensiveResource = ExpensiveResource()
    
    func process() {
        // First access: initialization happens here
        expensiveResource.start()
    }
}

// Usage
let processor = DataProcessor()
// expensiveResource not created yet
processor.process()  // Now it's created
```

---

## Type Annotation

### When to Specify Types

```swift
// Type inferred (preferred when clear)
let greeting = "Hello"  // String
let count = 42          // Int
let pi = 3.14          // Double

// Type annotation (for clarity or when type unclear)
let numbers: [Int] = [1, 2, 3]
let dictionary: [String: Int] = ["one": 1, "two": 2]

// Required when initializer ambiguous
let number: Int = 0  // Could be Int, Double, Float...
let double: Double = 0.0

// For protocol types
let items: [Equatable] = [1, "string", 2.5]
```

### Type Conversion

```swift
// Different types
let intValue = 42
let doubleValue: Double = Double(intValue)
let stringValue = String(intValue)

// Collections with specific types
let numbers: [Int] = [1, 2, 3]  // Not [Any], specific type

// Optional types
let optional: String? = "value"
let nonOptional: String = "value"
```

---

## Scope

### Local Scope

```swift
func example() {
    let outer = "outside"
    
    if true {
        let inner = "inside"
        print(outer)  // ✅ Can access
        print(inner)  // ✅ Can access
    }
    
    print(outer)  // ✅ Can access
    // print(inner)  // ❌ Not in scope
}
```

### Function Scope

```swift
let globalConstant = "outside"

func function1() {
    print(globalConstant)  // ✅ Can access global
    
    let localConstant = "inside"
    print(localConstant)   // ✅ Can access local
}

func function2() {
    print(globalConstant)  // ✅ Can access global
    // print(localConstant)  // ❌ Not in scope from function1
}
```

### Class and Struct Scope

```swift
class Person {
    let name: String      // Class scope
    var age: Int          // Class scope
    
    func greet() {
        let greeting = "Hello"  // Local scope
        print("\(greeting) \(name)")
    }
}

let person = Person(name: "John", age: 30)
print(person.name)  // ✅ Accessible
// print(greeting)   // ❌ Not accessible
```

### Shadowing (Reusing Names in Inner Scopes)

```swift
let value = 10

if true {
    let value = 20  // Shadows outer value
    print(value)    // 20
}

print(value)        // 10
```

---

## Mutability

### Distinguishing Mut vs Immut

```swift
// Immutable variable
let immutableString = "Hello"
// immutableString = "World"  // ❌ Error

// Mutable variable
var mutableString = "Hello"
mutableString = "World"  // ✅ OK

// ⚠️ Important: Mutable REFERENCE doesn't mean mutable PROPERTIES
let array = [1, 2, 3]
// array = [4, 5, 6]  // ❌ Can't reassign
array.append(4)  // ❌ Error - array is let
```

### Collections Mutability

```swift
// Mutable collection
var mutableArray = [1, 2, 3]
mutableArray.append(4)  // ✅ OK
mutableArray[0] = 10    // ✅ OK

// Immutable collection
let immutableArray = [1, 2, 3]
// immutableArray.append(4)  // ❌ Error
// immutableArray[0] = 10    // ❌ Error
```

### Classes vs Structs

```swift
class MutableClass {
    var value: Int
    
    init(value: Int) {
        self.value = value
    }
}

// Even with let, can modify properties!
let obj = MutableClass(value: 10)
obj.value = 20  // ✅ OK - can modify class properties even if let

struct ImmutableStruct {
    var value: Int
}

let s = ImmutableStruct(value: 10)
// s.value = 20  // ❌ Error - struct is let
```

---

## Memory and Lifecycle

### Stack vs Heap

```swift
// Stack: Small, fast, short-lived
let x = 42              // Stack
var array: [Int] = []   // Storage on heap, array reference on stack

// Heap: Large, slower, longer-lived
class DataContainer {   // Allocated on heap
    var data: [String] = []
}

let container = DataContainer()  // Reference on stack, object on heap
```

### Variable Lifetime

```swift
func example() {
    let temporary = "This will be freed"
    print(temporary)
}  // temporary is deallocated here

// Automatic Reference Counting
class Resource {
    deinit {
        print("Resource deallocated")
    }
}

do {
    let resource = Resource()
}  // deinit called here
```

### Capture and Retain Cycles

```swift
class Parent {
    var child: Child?
    
    deinit {
        print("Parent deallocated")
    }
}

class Child {
    weak var parent: Parent?  // Weak to avoid retain cycle
    
    deinit {
        print("Child deallocated")
    }
}

do {
    let parent = Parent()
    let child = Child()
    parent.child = child
    child.parent = parent
}  // Both deallocate properly due to weak reference
```

---

## 🎯 Best Practices

### 1. Use Constants by Default
- Makes intent clear
- Prevents accidental mutation
- Helps compiler optimize
- Easier to reason about

### 2. Narrow Scope
- Declare variables as close to use as possible
- Reduces cognitive load
- Prevents accidental reuse

### 3. Descriptive Names
```swift
// ❌ Unclear
let d = 5

// ✅ Clear
let desiredTemperature = 5
let maxRetries = 5
```

### 4. Type Annotation for Clarity
```swift
// ✅ When it matters
let matrix: [[Int]] = [[1, 2], [3, 4]]
let handler: (String) -> Void = { print($0) }
```

### 5. Use Lazy for Expensive Operations
```swift
// Deferred initialization
lazy var expensiveComputation = computeValue()
```

---

## ❌ Common Mistakes

### Mistake 1: Over-using Variables

**WRONG:**
```swift
var result = calculateValue()
// result never changes
print(result)
```

**CORRECT:**
```swift
let result = calculateValue()
print(result)
```

---

### Mistake 2: Reassigning When Not Needed

**WRONG:**
```swift
var sum = 0
sum = sum + numbers.reduce(0, +)  // Unnecessary reassignment
```

**CORRECT:**
```swift
let sum = numbers.reduce(0, +)
```

---

### Mistake 3: Wide Scope

**WRONG:**
```swift
var result = 0  // Declared at top of large function
for i in 1...100 {
    result += i
}
// result used much later, hard to track
```

**CORRECT:**
```swift
let result = (1...100).reduce(0, +)  // Immediate scope
```

---

## Related Topics

- [Data Types](data-types.md)
- [Optionals](optionals.md)
- [Scope and Closures](closures.md)

---

**Use let by default, var sparingly. Keep scope narrow!**
