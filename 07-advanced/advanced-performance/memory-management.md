# Memory Management and ARC

## Overview

Automatic Reference Counting (ARC) is Swift's memory management system. Understanding how it works, recognizing retain cycles, and knowing how to use weak and unowned references is critical for writing apps that don't leak memory.

## Main Topics

- [How ARC Works](#how-arc-works)
- [Reference Types vs Value Types](#reference-types-vs-value-types)
- [Retain Cycles](#retain-cycles)
- [Weak References](#weak-references)
- [Unowned References](#unowned-references)
- [Memory Debugging](#memory-debugging)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Automatic Reference Counting - The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/automaticreferencecounting)
- [Memory Management in Swift](https://developer.apple.com/videos/play/wwdc2021/10019/)

---

## How ARC Works

### Reference Counting

```swift
// ARC tracks Strong References
class Person {
    let name: String
    
    init(name: String) {
        self.name = name
        print("Person \(name) initialized")
    }
    
    deinit {
        print("Person \(name) deinitialized")
    }
}

// Reference counter starts at 1
var person1: Person? = Person(name: "Alice")  // Reference count = 1

// Creating another reference increments counter
var person2 = person1                          // Reference count = 2

// Setting to nil decrements counter
person1 = nil                                  // Reference count = 1

// All references must be released
person2 = nil                                  // Reference count = 0, deinit called
```

### Automatic Memory Management

```swift
func createPerson() {
    let person = Person(name: "Bob")
    // Reference count = 1
    // Do something with person
}  // Function ends
// person out of scope, reference count = 0, deinit called
```

---

## Reference Types vs Value Types

### Reference Types (Classes)

```swift
class Dog {
    var name: String
    var owner: String?
    
    init(name: String) {
        self.name = name
    }
}

var dog1 = Dog(name: "Buddy")
var dog2 = dog1  // dog2 references same object as dog1

dog2.name = "Max"
print(dog1.name)  // "Max" - both reference same object
print(dog1 === dog2)  // true - same reference
```

### Value Types (Structs)

```swift
struct Cat {
    var name: String
    var owner: String?
}

var cat1 = Cat(name: "Whiskers")
var cat2 = cat1  // cat2 is a copy of cat1

cat2.name = "Mittens"
print(cat1.name)  // "Whiskers" - original unchanged
print(cat1 == cat2)  // false - different values
```

---

## Retain Cycles

### Understanding Retain Cycles

```swift
class Person {
    let name: String
    var pet: Dog?
    
    init(name: String) {
        self.name = name
    }
    
    deinit {
        print("Person \(name) deinitialized")
    }
}

class Dog {
    let name: String
    var owner: Person?
    
    init(name: String) {
        self.name = name
    }
    
    deinit {
        print("Dog \(name) deinitialized")
    }
}

// Creating a retain cycle
var person: Person? = Person(name: "Alice")
var dog: Dog? = Dog(name: "Buddy")

person?.pet = dog  // Person → Dog (strong reference)
dog?.owner = person  // Dog → Person (strong reference)

person = nil  // Doesn't deallocate - dog still holds reference
dog = nil     // Doesn't deallocate - person still holds reference
// Memory leak! Both objects remain in memory
```

---

## Weak References

Using `weak` to break cycles:

```swift
class Dog {
    let name: String
    weak var owner: Person?  // Weak reference - doesn't increase counter
    
    init(name: String) {
        self.name = name
    }
    
    deinit {
        print("Dog \(name) deinitialized")
    }
}

// Now it works correctly
var person: Person? = Person(name: "Alice")
var dog: Dog? = Dog(name: "Buddy")

person?.pet = dog
dog?.owner = person  // Weak reference

person = nil  // Person deallocated
dog = nil     // Dog deallocated (owner was weak)
```

### Using Weak in Closures

```swift
class NetworkManager {
    func fetchData(completion: @escaping () -> Void) {
        // Strong reference if captured
        // Leads to retain cycle
    }
}

class ViewController {
    let manager = NetworkManager()
    
    func loadData() {
        // Weak self to avoid retain cycle
        manager.fetchData { [weak self] in
            guard let self = self else { return }
            self.updateUI()
        }
    }
    
    func updateUI() {
        print("UI Updated")
    }
    
    deinit {
        print("ViewController deinitialized")
    }
}
```

---

## Unowned References

Using `unowned` when object always exists:

```swift
class CreditCard {
    let number: String
    let owner: Person  // Never nil, owner lives longer
    
    init(number: String, owner: Person) {
        self.number = number
        self.owner = owner
    }
    
    deinit {
        print("Card deinitialized")
    }
}

class Person {
    let name: String
    var creditCard: CreditCard?
    
    init(name: String) {
        self.name = name
    }
    
    deinit {
        print("Person deinitialized")
    }
}

// CreditCard has unowned reference to Person
// Person can be deallocated without issue
var person: Person? = Person(name: "Bob")
person?.creditCard = CreditCard(number: "1234", owner: person!)
person = nil  // Both deallocated properly
```

### Capturing self with unowned in closures

```swift
class ViewController: UIViewController {
    func setupButtonHandler() {
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        
        // self outlives closure in this case
        let handler = { [unowned self] in
            self.processData()
        }
        
        // OR use weak to be safe
        let safeHandler = { [weak self] in
            self?.processData()
        }
    }
    
    @objc func handleTap() {
        print("Tapped")
    }
    
    func processData() {
        print("Processing")
    }
}
```

---

## Memory Debugging

### Using Instruments

```swift
// 1. Xcode > Product > Profile
// 2. Select "Leaks" instrument
// 3. Run your app
// 4. Interact with features
// 5. Look for red/yellow markers indicating leaks

// Example to test:
func testForMemoryLeak() {
    for _ in 1...1000 {
        let vc = ViewController()
        // If ViewController leaks, memory grows
    }
}
```

### Print Statements to Check Deinit

```swift
class TestClass {
    let name = "Test"
    
    deinit {
        print("✅ \(name) deallocated")
    }
}

// Create and release
var test: TestClass? = TestClass()
test = nil  // Should print "✅ Test deallocated"

// If nothing prints, there's a retain cycle!
```

### Memory Graph Debugger

```swift
// Xcode > Debug > Memory Graph

func example() {
    let person = Person(name: "Charlie")
    let dog = Dog(name: "Max")
    
    // Set relationships
    person.pet = dog
    dog.owner = person  // If not weak, shows retain cycle in debugger
}
```

---

## 🎯 Best Practices

### 1. Prefer Value Types
- Use structs for simple data
- Avoid memory management complexity
- Better for functional programming

### 2. Use Weak References in Lifecycles
- Closures capturing self
- Delegates
- Observers

### 3. Use Unowned When Lifecycle is Clear
- Parent-child relationships where parent outlives child
- Cleaner than weak in specific cases

### 4. Regular Memory Testing
- Profile with Instruments regularly
- Write tests for memory leaks
- Check deinit calls in debug builds

### 5. Document ARC Behavior
- Make retain cycle risks clear
- Comment why weak/unowned is used
- Explain lifecycle assumptions

---

## ❌ Common Mistakes

### Mistake 1: Closure Retain Cycles

**WRONG:**
```swift
class DataManager {
    var data = []
    
    func loadData() {
        apiCall { response in
            self.data = response  // Strong reference - retain cycle!
        }
    }
    
    deinit {
        print("Never called!")
    }
}
```

**CORRECT:**
```swift
class DataManager {
    var data = []
    
    func loadData() {
        apiCall { [weak self] response in
            self?.data = response  // Weak reference
        }
    }
    
    deinit {
        print("Deallocated correctly")
    }
}
```

---

### Mistake 2: Using Unowned Unsafely

**WRONG:**
```swift
// Unowned when object might be deallocated
let handler = { [unowned self] in  // Unsafe!
    // What if self is deallocated before closure runs?
    self.processData()
}

// Store for later execution
saveForLaterExecution(handler)
// self might be deallocated before handler runs!
```

**CORRECT:**
```swift
// Use weak when timing is uncertain
let handler = { [weak self] in  // Safe
    self?.processData()
}

saveForLaterExecution(handler)  // Safe even if self deallocates
```

---

### Mistake 3: Too Many Strong References

**WRONG:**
```swift
class Service {
    let delegate: Delegate
    let cache: Cache
    let logger: Logger
    
    func doWork() {
        // Capturing self in all closures
        task1 { self.process() }
        task2 { self.log() }
        // Many strong captures
    }
}
```

**CORRECT:**
```swift
class Service {
    let delegate: Delegate
    let cache: Cache
    let logger: Logger
    
    func doWork() {
        // Capture only what's needed, use weak
        task1 { [weak self] in
            self?.process()
        }
        task2 { [weak logger = self.logger] in
            logger.log()
        }
    }
}
```

---

## Related Topics

- [Classes and Structures](../../01-fundamentals/object-oriented-programming/classes-and-structures.md)
- [Protocols](../../01-fundamentals/object-oriented-programming/protocols.md)
- [Closures](../../01-fundamentals/functions-and-closures/closures.md)

---

**Master memory management to build leak-free, efficient apps!**
