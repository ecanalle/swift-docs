# Actors in Swift

## Overview

Actors are reference types that provide thread-safe access to mutable state through automatic synchronization. They solve the data-race problem in concurrent Swift by ensuring only one task can access an actor's state at a time.

## Main Topics

- [Actor Basics](#actor-basics)
- [Nonisolated](#nonisolated)
- [MainActor](#mainactor)
- [Actor Isolation](#actor-isolation)
- [Testing Actors](#testing-actors)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Actors](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency#Actors)

---

## Actor Basics

### Actor vs Class

```swift
// ❌ Class - Not thread-safe
class UnsafeCounter {
    var count = 0
    
    func increment() {
        count += 1  // Race condition!
    }
}

// Task 1 and Task 2 both read count as 0, increment to 1
// Expected: 2, Actual: 1 (data race)

// ✅ Actor - Thread-safe
actor SafeCounter {
    var count = 0
    
    func increment() {
        count += 1  // Automatically synchronized
    }
    
    func getValue() -> Int {
        return count
    }
}

// Usage
let counter = SafeCounter()
for _ in 1...100 {
    Task {
        await counter.increment()
    }
}
```

### Actor Syntax

```swift
actor UserStore {
    private var users: [User] = []
    
    // Async methods (automatically)
    func addUser(_ user: User) async {
        users.append(user)
    }
    
    func getUser(id: Int) async -> User? {
        return users.first { $0.id == id }
    }
    
    func getAllUsers() async -> [User] {
        return users
    }
}

// All access must be async
let store = UserStore()
let user = await store.getUser(id: 1)
```

---

## Nonisolated

### Mark Synchronous Methods

```swift
actor DataStore {
    let version: Int = 1
    var data: [String] = []
    
    // ✅ Nonisolated - can call synchronously
    // But cannot access mutable properties
    nonisolated func getVersion() -> Int {
        return version
    }
    
    // ❌ This won't compile
    // nonisolated func getData() -> [String] {
    //     return data  // Error: data is mutable
    // }
}

// Usage
let store = DataStore()
let version = store.getVersion()  // No await needed
```

### Read-only vs Mutating

```swift
actor User {
    let id: Int  // Immutable
    var name: String  // Mutable
    
    // ✅ Can be nonisolated (read-only)
    nonisolated var userId: Int {
        return id
    }
    
    // Must be async (mutates)
    func updateName(_ newName: String) async {
        name = newName
    }
}
```

---

## MainActor

### UI Thread Safety

```swift
// ✅ Guarantees UI code runs on main thread
@MainActor
class ViewController: UIViewController {
    var label = UILabel()
    
    // Automatically runs on main thread
    func updateUI(text: String) {
        label.text = text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "Hello"
    }
}

// Usage
let controller = ViewController()
// Can call from any thread - automatically dispatched to main
Task {
    await controller.updateUI(text: "Updated")
}
```

### @MainActor with SwiftUI

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var items: [Item] = []
    
    // Automatically updates on main thread
    func loadItems() async {
        let items = await fetchFromServer()
        self.items = items  // Safe to update UI
    }
}

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Text(item.name)
            }
        }
        .task {
            await viewModel.loadItems()
        }
    }
}
```

### Explicit MainActor

```swift
// Even if not @MainActor, mark specific methods
actor DataFetcher {
    @MainActor
    func updateUI() {
        // This runs on main thread
    }
    
    func fetchData() {
        // This can run on background thread
    }
}
```

---

## Actor Isolation

### Accessing Actor State

```swift
actor Account {
    var balance: Double = 0
    
    func withdraw(amount: Double) async -> Bool {
        if balance >= amount {
            balance -= amount
            return true
        }
        return false
    }
    
    func deposit(amount: Double) async {
        balance += amount
    }
}

// Usage - must be async
Task {
    let account = Account()
    await account.deposit(amount: 100)
    let success = await account.withdraw(amount: 50)
}
```

### Actor Sendable

```swift
// Types that are safe to transfer between actors
protocol Sendable { }

// Automatically Sendable:
// - Value types (struct, enum)
// - Classes with no mutable state
// - Actors (thread-safe by design)

struct Message: Sendable {  // Safe to send
    let text: String
    let timestamp: Date
}

actor MessageQueue {
    var messages: [Message] = []
    
    func enqueue(_ message: Message) {
        messages.append(message)
    }
}
```

### Avoiding Deadlocks

```swift
actor Bank {
    var balance: Double = 1000
    
    // ❌ Can cause deadlock
    func transferBad(amount: Double, to otherAccount: Bank) async {
        // Never call back into same actor
        // while holding its lock
        await otherAccount.deposit(amount: amount)
        balance -= amount
    }
    
    // ✅ Safer approach
    func transfer(amount: Double, to otherAccount: Bank) async {
        // Release lock before calling other actor
        let success = await otherAccount.deposit(amount: amount)
        if success {
            self.balance -= amount
        }
    }
    
    func deposit(amount: Double) async -> Bool {
        balance += amount
        return true
    }
}
```

---

## Testing Actors

### Unit Testing Actors

```swift
class CounterTests: XCTestCase {
    func testActorIncrement() async {
        let counter = SafeCounter()
        await counter.increment()
        let value = await counter.getValue()
        XCTAssertEqual(value, 1)
    }
    
    func testConcurrentAccess() async {
        let counter = SafeCounter()
        
        let tasks = (1...100).map { _ in
            Task {
                await counter.increment()
            }
        }
        
        for task in tasks {
            await task.value
        }
        
        let finalValue = await counter.getValue()
        XCTAssertEqual(finalValue, 100)
    }
}
```

---

## 🎯 Best Practices

### 1. Use Actors for Shared Mutable State
```swift
// ✅ Good use of actor
actor DatabaseConnection {
    var isConnected = false
    
    func connect() async { }
    func disconnect() async { }
}

// ❌ Overkill for simple data
actor SimpleValue {
    var value = 42
}
```

### 2. Keep Actor Methods Small
```swift
// ✅ Focused methods reduce contention
actor Queue {
    func enqueue(_ item: Item) async { }
    func dequeue() async -> Item? { }
}

// ❌ Long-running operations block access
actor Processor {
    func processAllItemsForever() async {
        // Blocks access to other methods
    }
}
```

### 3. Use @MainActor for UI
```swift
// ✅ Clear UI thread requirement
@MainActor
class ViewController: UIViewController { }

// ✅ Mark specific methods
override func viewDidLoad() {
    // Already on main thread
}
```

---

## ❌ Common Mistakes

### Mistake 1: Calling Actor Methods Without Await

**WRONG:**
```swift
// ❌ Won't compile
let counter = SafeCounter()
counter.increment()  // Error: must be called with await
```

**CORRECT:**
```swift
// ✅ Use await
let counter = SafeCounter()
await counter.increment()
```

---

### Mistake 2: Non-Sendable Types

**WRONG:**
```swift
class NonSendable { }

actor Container {
    var item: NonSendable?  // Warning: type not Sendable
}
```

**CORRECT:**
```swift
struct Sendable { }

actor Container {
    var item: Sendable?  // OK
}
```

---

### Mistake 3: Assuming Atomicity

**WRONG:**
```swift
// ❌ Not atomic
actor Counter {
    var count = 0
    
    func incrementTwice() async {
        count += 1
        // Another task could modify count here
        count += 1
    }
}
```

**CORRECT:**
```swift
// ✅ Single operation
actor Counter {
    var count = 0
    
    func incrementBy(_ amount: Int) async {
        count += amount
    }
}
```

---

## Related Topics

- [Async/Await](async-await.md)
- [Combine](combine.md)
- [GCD](gcd.md)

---

**Use actors for thread-safe concurrent code!**
