# Concurrency with Async/Await

## Overview

Async/await provides a more intuitive way to write asynchronous code compared to callbacks and completion handlers. It's the modern standard for managing concurrent tasks in Swift and makes code both more readable and less error-prone.

## Main Topics

- [Async/Await Basics](#asyncawait-basics)
- [Tasks and Task Groups](#tasks-and-task-groups)
- [Actors for Thread Safety](#actors-for-thread-safety)
- [Testing Async Code](#testing-async-code)
- [Common Patterns](#common-patterns)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Swift Concurrency Documentation](https://developer.apple.com/documentation/swift/concurrency)
- [WWDC 2021: Swift Concurrency](https://developer.apple.com/videos/play/wwdc2021/10132/)

---

## Async/Await Basics

### Async Functions

```swift
// Old way with callbacks
func fetchUserWithCallback(id: Int, completion: @escaping (User?, Error?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let data = data {
            if let user = try? JSONDecoder().decode(User.self, from: data) {
                completion(user, nil)
            }
        } else {
            completion(nil, error)
        }
    }.resume()
}

// New way with async/await
async func fetchUser(id: Int) -> User? {
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let user = try JSONDecoder().decode(User.self, from: data)
        return user
    } catch {
        print("Error: \(error)")
        return nil
    }
}

// Calling async functions
Task {
    if let user = await fetchUser(id: 1) {
        print("User: \(user.name)")
    }
}
```

### Throwing Async Functions

```swift
async throws func fetchUserStrict(id: Int) throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    let user = try JSONDecoder().decode(User.self, from: data)
    return user
}

// Using throws
Task {
    do {
        let user = try await fetchUserStrict(id: 1)
        print("User: \(user.name)")
    } catch {
        print("Error: \(error)")
    }
}
```

---

## Tasks and Task Groups

### Creating Tasks

```swift
// Unstructured task
Task {
    // Runs in background
    let user = await fetchUser(id: 1)
    print(user?.name ?? "Unknown")
}

// Task with priority
Task(priority: .userInitiated) {
    await someAsyncWork()
}

// Detached task (no priority inheritance)
Task.detached(priority: .background) {
    await heavyBackgroundWork()
}
```

### Task Groups

```swift
// Fetch multiple users concurrently
func fetchMultipleUsers(ids: [Int]) async -> [User] {
    var users: [User] = []
    
    await withTaskGroup(of: User?.self) { group in
        for id in ids {
            group.addTask {
                return await fetchUser(id: id)
            }
        }
        
        // Collect results as they complete
        for await user in group {
            if let user = user {
                users.append(user)
            }
        }
    }
    
    return users
}

// ThrowingTaskGroup for error handling
func fetchUsersWithErrors(ids: [Int]) async throws -> [User] {
    var users: [User] = []
    
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask {
                try await fetchUserStrict(id: id)
            }
        }
        
        for try await user in group {
            users.append(user)
        }
    }
    
    return users
}
```

### Task Cancellation

```swift
func downloadLargeFile() async {
    let task = Task {
        while !Task.isCancelled {
            await downloadChunk()
        }
    }
    
    // Cancel after timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
        task.cancel()
    }
}

// Check cancellation
Task {
    try await withCheckedThrowingContinuation { continuation in
        if Task.isCancelled {
            continuation.resume(throwing: CancellationError())
        }
    }
}
```

---

## Actors for Thread Safety

### Basic Actor

```swift
nonisolated(unsafe) var counter = 0  // Not thread-safe

// Use Actor instead
actor DataStore {
    private var data: [String: Any] = [:]
    
    func setValue(_ value: Any, forKey key: String) {
        data[key] = value
    }
    
    func getValue(forKey key: String) -> Any? {
        return data[key]
    }
}

// Using actor
let store = DataStore()
await store.setValue("value", forKey: "key")
if let value = await store.getValue(forKey: "key") {
    print("Stored: \(value)")
}
```

### MainActor for UI

```swift
@MainActor
class UIViewModel: ObservableObject {
    @Published var users: [User] = []
    
    @MainActor
    func loadUsers() async {
        // Guaranteed to run on main thread
        do {
            let users = try await fetchUsersStrict()
            self.users = users
        } catch {
            print("Error: \(error)")
        }
    }
    
    nonisolated func expensiveCalculation() {
        // Runs on background thread
    }
}

// Using from UI
@main
struct MyApp: App {
    @StateObject var viewModel = UIViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .asyncCommit(id: UUID()) {
                    await viewModel.loadUsers()
                }
        }
    }
}
```

---

## Testing Async Code

### Testing async functions

```swift
import XCTest

class UserTests: XCTestCase {
    let sut = UserViewModel()
    
    func testFetchUser() async throws {
        let user = try await sut.fetchUser(id: 1)
        XCTAssertEqual(user.name, "John")
    }
    
    func testFetchUserError() async throws {
        // Mock error
        let result = await sut.fetchUser(id: -1)
        XCTAssertNil(result)
    }
    
    // Test with timeout
    func testFetchUserTimeout() async throws {
        let request = URLRequest(url: url)
        request.timeoutInterval = 0.001
        
        let task = Task {
            try await URLSession.shared.data(for: request)
        }
        
        // Will timeout immediately
        let result = await task.result
        switch result {
        case .failure(let error as URLError) where error.code == .timedOut:
            // Expected
            break
        default:
            XCTFail("Should timeout")
        }
    }
}
```

---

## Common Patterns

### Serial Execution in Task

```swift
// Tasks run concurrently by default
async func sequential() {
    let user1 = await fetchUser(id: 1)  // Runs after this completes
    let user2 = await fetchUser(id: 2)  // Then this
}

// Run all at once (concurrent)
async func concurrent() {
    async let user1 = fetchUser(id: 1)
    async let user2 = fetchUser(id: 2)
    
    let users = await [user1, user2]
}

// Parallel execution
async func parallelMap() {
    let ids = [1, 2, 3]
    let users = await withTaskGroup(of: User?.self) { group in
        for id in ids {
            group.addTask {
                return await fetchUser(id: id)
            }
        }
        
        return await group.reduce([User]()) { users, user in
            guard let user = user else { return users }
            return users + [user]
        }
    }
}
```

### Combining Operations

```swift
// Sequential: fetch then process
async func processUsers() {
    let users = await fetchUsers()
    let processed = await processEach(users)
}

// Concurrent init, sequential processing
async func optimized() {
    async let usersFuture = fetchUsers()
    async let processNeedsFuture = fetchProcessNeeds()
    
    let users = await usersFuture
    let needs = await processNeedsFuture
    
    let processed = await processEach(users, with: needs)
}
```

---

## 🎯 Best Practices

### 1. Use async/await over callbacks
- More readable
- Better error handling
- Avoids callback hell

### 2. Mark UI operations with @MainActor
- Ensures thread safety
- Compiler helps catch errors
- Makes intent clear

### 3. Use Actors for shared mutable state
- Thread-safe by default
- Prevents race conditions
- Clear data access patterns

### 4. Handle cancellation gracefully
- Check `Task.isCancelled`
- Clean up resources
- Test cancellation scenarios

### 5. Test concurrent code
- Use `async throws` in tests
- Test both success and failure paths
- Test cancellation

---

## ❌ Common Mistakes

### Mistake 1: Mixing Callbacks with Async/Await

**WRONG:**
```swift
async func fetchUser(id: Int) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        // Callback hell
    }.resume()
}
```

**CORRECT:**
```swift
async func fetchUser(id: Int) async -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}
```

---

### Mistake 2: Not Handling Cancellation

**WRONG:**
```swift
Task {
    while true {
        await doWork()  // Never checks cancellation
    }
}
```

**CORRECT:**
```swift
Task {
    while !Task.isCancelled {
        await doWork()
    }
}
```

---

### Mistake 3: UI Updates on Background Thread

**WRONG:**
```swift
Task.detached {
    let user = await fetchUser(id: 1)
    self.label.text = user.name  // ❌ Wrong thread
}
```

**CORRECT:**
```swift
Task {
    let user = await fetchUser(id: 1)
    await MainActor.run {
        self.label.text = user.name  // ✅ Main thread
    }
}
```

---

## Related Topics

- [URLSession](../../03-networking-backend/networking-and-apis/urlsession.md)
- [Grand Central Dispatch](grand-central-dispatch.md)
- [Testing](../../04-app-lifecycle/testing.md)

---

**Master async/await to write clean, concurrent code!**
