# Grand Central Dispatch (GCD) - DispatchQueue

## Overview

Grand Central Dispatch (GCD) is a low-level C API that simplifies asynchronous task execution on multiple cores. DispatchQueue manages work on threads efficiently without creating threads directly.

## Main Topics

- [Queue Types](#queue-types)
- [Basic Operations](#basic-operations)
- [Async vs Sync](#async-vs-sync)
- [Quality of Service (QoS)](#quality-of-service-qos)
- [Thread Safety](#thread-safety)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Grand Central Dispatch](https://developer.apple.com/documentation/dispatch)

---

## Queue Types

### Main Queue

```swift
// Always executes on main thread
DispatchQueue.main.async {
    // UI updates here
    label.text = "Updated"
}

// Synchronous (blocks current thread - dangerous on main!)
DispatchQueue.main.sync {
    // Only if you know it won't deadlock
    print(UIApplication.shared.applicationState)
}
```

### Global Queue

```swift
// Default priority
DispatchQueue.global().async {
    // Background work
    let data = expensiveComputation()
    
    DispatchQueue.main.async {
        // Update UI
        updateUI(with: data)
    }
}

// With QoS
DispatchQueue.global(qos: .userInitiated).async {
    // High priority background work
}
```

### Custom Queue

```swift
// Serial queue (one task at a time)
let serialQueue = DispatchQueue(label: "com.app.serial")

serialQueue.async {
    print("Task 1")  // Runs first
}

serialQueue.async {
    print("Task 2")  // Waits for Task 1
}

// Concurrent queue
let concurrentQueue = DispatchQueue(
    label: "com.app.concurrent",
    attributes: .concurrent
)

concurrentQueue.async {
    print("Task 1")  // Runs simultaneously
}

concurrentQueue.async {
    print("Task 2")  // Runs simultaneously
}
```

---

## Basic Operations

### Async (Non-blocking)

```swift
// Schedule work without waiting
DispatchQueue.global().async {
    let heavyData = fetchLargeDataset()
    
    DispatchQueue.main.async {
        self.displayData(heavyData)
    }
}

print("Continues immediately")  // Prints before async completes
```

### Sync (Blocking)

```swift
// Wait for task to complete
print("Before")

DispatchQueue.global().sync {
    print("During")  // Blocks until complete
}

print("After")  // Executes after sync completes
```

### Semaphore (Control Access)

```swift
let semaphore = DispatchSemaphore(value: 1)

// Acquire
semaphore.wait()

// Do work
criticalSection()

// Release
semaphore.signal()

// Multiple concurrent access (max 3)
let multiSemaphore = DispatchSemaphore(value: 3)
```

---

## Async vs Sync

### Pattern: Non-blocking with Async

```swift
// ✅ Responsive UI
func loadUsers(completion: @escaping ([User]) -> Void) {
    DispatchQueue.global().async {
        let users = fetchFromDatabase()
        
        DispatchQueue.main.async {
            completion(users)
        }
    }
}

// Usage
loadUsers { users in
    self.tableView.reloadData()
}
```

### Pattern: Wait with Sync (Rarely Needed)

```swift
// ⚠️ Only use when you must wait
func criticalSetup() {
    var initialized = false
    
    DispatchQueue.global().sync {
        setupDatabase()  // Blocks until done
        initialized = true
    }
    
    if initialized {
        startApp()
    }
}
```

---

## Quality of Service (QoS)

### QoS Levels

```swift
// Highest priority - time-sensitive user interaction
DispatchQueue.global(qos: .userInteractive).async {
    // Animation, gesture response
    updateAnimationFrame()
}

// High priority - user-initiated work
DispatchQueue.global(qos: .userInitiated).async {
    // Button press, search
    performSearch()
}

// Default/Standard
DispatchQueue.global(qos: .default).async {
    // General tasks
}

// Low priority - background maintenance
DispatchQueue.global(qos: .utility).async {
    // Sync, cleanup, maintenance
    syncBackgroundData()
}

// Lowest - background only when battery available
DispatchQueue.global(qos: .background).async {
    // Analytics, logs, heavy processing
    processAnalytics()
}
```

### QoS Inheritance

```swift
// Main thread (userInteractive)
DispatchQueue.global(qos: .background).async {
    // Lower QoS
    print("Background")
    
    DispatchQueue.main.async {
        // ✅ Respects main thread priority
        updateUI()
    }
}
```

---

## Thread Safety

### Problem: Race Condition

```swift
// ❌ Data race - multiple threads access simultaneously
var counter = 0

DispatchQueue.global().async {
    for _ in 0..<1000 {
        counter += 1  // Read-Modify-Write not atomic
    }
}

DispatchQueue.global().async {
    for _ in 0..<1000 {
        counter += 1  // Data race!
    }
}

// counter won't be 2000, might be 1530 or random value
```

### Solution 1: Serial Queue

```swift
// ✅ Serial queue ensures order
class Counter {
    private var value = 0
    private let queue = DispatchQueue(label: "com.app.counter")
    
    func increment() {
        queue.async {
            self.value += 1
        }
    }
    
    func getValue(completion: @escaping (Int) -> Void) {
        queue.async {
            completion(self.value)
        }
    }
}
```

### Solution 2: Barrier

```swift
// ✅ Exclusive write access
class ThreadSafeCache {
    private var cache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.app.cache", attributes: .concurrent)
    
    func set(_ key: String, _ value: Any) {
        // Barrier blocks concurrent reads/writes
        queue.async(flags: .barrier) {
            self.cache[key] = value
        }
    }
    
    func get(_ key: String) -> Any? {
        var result: Any?
        queue.sync {
            result = self.cache[key]
        }
        return result
    }
}
```

### Solution 3: Lock

```swift
// ✅ Modern approach (Swift 5.1+)
import os

class SafeCounter {
    private var value = 0
    private let lock = os.unfair_lock()
    
    func increment() {
        lock.lock()
        defer { lock.unlock() }
        value += 1
    }
    
    func getValue() -> Int {
        lock.withLock { value }
    }
}
```

---

## Advanced Patterns

### DispatchGroup (Coordinate Multiple Tasks)

```swift
let group = DispatchGroup()

// Task 1
group.enter()
DispatchQueue.global().async {
    fetchUsersFromAPI {
        group.leave()
    }
}

// Task 2
group.enter()
DispatchQueue.global().async {
    fetchPostsFromAPI {
        group.leave()
    }
}

// Wait for all to complete
group.notify(queue: .main) {
    print("Both tasks done!")
    updateUI()
}
```

### DispatchWorkItem

```swift
let workItem = DispatchWorkItem {
    print("Work item executing")
}

// Cancel before execution
workItem.cancel()

if !workItem.isCancelled {
    DispatchQueue.global().async(execute: workItem)
}
```

### Timeout Pattern

```swift
let semaphore = DispatchSemaphore(value: 0)
var result: String?

DispatchQueue.global().async {
    result = expensiveOperation()
    semaphore.signal()
}

let timeout = DispatchTime.now() + .seconds(5)
if semaphore.wait(timeout: timeout) == .timedOut {
    print("Operation timed out!")
}
```

### Weak Self Pattern

```swift
DispatchQueue.global().async { [weak self] in
    guard let self = self else {
        print("Object deallocated")
        return
    }
    
    let data = fetchData()
    
    DispatchQueue.main.async { [weak self] in
        self?.updateUI(with: data)
    }
}
```

---

## 🎯 Best Practices

### 1. Update UI on Main Thread
```swift
// ✅ Always dispatch UI updates to main
DispatchQueue.global().async {
    let data = fetchData()
    
    DispatchQueue.main.async {
        self.label.text = data
    }
}

// ❌ UI update on background thread
DispatchQueue.global().async {
    self.label.text = "Will crash or not update!"
}
```

### 2. Choose Right Queue Type
```swift
// ✅ User-initiated work gets higher priority
DispatchQueue.global(qos: .userInitiated).async {
    performSearch()
}

// ❌ Everything on default queue
DispatchQueue.global().async {
    // Low priority work mixed with high priority
}
```

### 3. Prevent Retain Cycles
```swift
// ✅ Use weak self in closures
DispatchQueue.global().async { [weak self] in
    guard let self = self else { return }
    self.updateData()
}

// ❌ Strong reference creates cycle
DispatchQueue.global().async {
    self.updateData()  // Leaks if self deallocates
}
```

### 4. Avoid Main Thread Deadlock
```swift
// ❌ Deadlock - sync on main from main
DispatchQueue.main.sync {
    // Already on main - blocks forever!
}

// ✅ Async is safe
DispatchQueue.main.async {
    // Safe - will execute after current code
}
```

---

## ❌ Common Mistakes

### Mistake 1: Sync on Main Queue

**WRONG:**
```swift
// ❌ Deadlock!
DispatchQueue.main.sync {
    print("This never executes")
}
```

**CORRECT:**
```swift
// ✅ Use async
DispatchQueue.main.async {
    print("Executes correctly")
}
```

---

### Mistake 2: Strong Reference Cycle

**WRONG:**
```swift
// ❌ Creates retain cycle
DispatchQueue.global().async {
    self.fetchData()  // self kept alive
}
// If self is deallocated, closure holds old self
```

**CORRECT:**
```swift
// ✅ Weak reference
DispatchQueue.global().async { [weak self] in
    self?.fetchData()
}
```

---

### Mistake 3: Ignoring QoS

**WRONG:**
```swift
// ❌ All background work on default QoS
DispatchQueue.global().async {
    searchData()  // User pressed search
}
```

**CORRECT:**
```swift
// ✅ Respect priority
DispatchQueue.global(qos: .userInitiated).async {
    searchData()
}
```

---

### Mistake 4: UI Update on Background Thread

**WRONG:**
```swift
// ❌ Crashes or doesn't update
DispatchQueue.global().async {
    self.label.text = "Updated"
}
```

**CORRECT:**
```swift
// ✅ Dispatch to main
DispatchQueue.global().async {
    let text = prepareText()
    DispatchQueue.main.async {
        self.label.text = text
    }
}
```

---

## Related Topics

- [Async/Await](async-await.md)
- [Combine Framework](combine.md)
- [Actors](actors.md)
- [Thread Safety](thread-safety.md)

---

**Master GCD for efficient concurrent programming in Swift!**
