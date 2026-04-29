# Swift Frameworks - Essential Libraries & Ecosystem

## Overview
The Swift ecosystem consists of powerful frameworks that extend beyond Foundation. Understanding popular frameworks and when to use them is critical for efficient, maintainable iOS development. This guide covers essential frameworks for networking, async programming, testing, and architecture.

## Main Topics
- [Networking Frameworks](#networking-frameworks)
- [Async & Concurrency Frameworks](#async--concurrency-frameworks)
- [Testing Frameworks](#testing-frameworks)
- [Architecture & Reactive Frameworks](#architecture--reactive-frameworks)
- [Performance & Profiling](#performance--profiling)
- [✅ Best Practices](#-best-practices)
- [❌ Common Mistakes](#-common-mistakes)

## Official Documentation
- [Swift Package Manager](https://www.swift.org/package-manager/)
- [Apple: Frameworks](https://developer.apple.com/documentation/swift)
- [Foundation Framework](https://developer.apple.com/documentation/foundation)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [WWDC: Modern Concurrency](https://developer.apple.com/videos/play/wwdc2021/10134/)

---

## Networking Frameworks

### URLSession (Built-in)

URLSession is Apple's native framework for network requests. It's production-ready and shouldn't be ignored in favor of third-party solutions for most use cases.

```swift
// ❌ Blocking network request on main thread
let data = try? Data(contentsOf: url)

// ✅ Proper URLSession with async/await
async {
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(Model.self, from: data)
    } catch {
        throw NetworkError.decodingFailed(error)
    }
}
```

**Key Points:**
- Handles redirects, authentication, cookies automatically
- Built-in support for HTTP/2, compression
- Modern async/await syntax eliminates callback hell
- URLSessionConfiguration for advanced customization

### Alamofire (Third-party Alternative)

Alamofire provides elegant API on top of URLSession. Use when you need significant request chaining or custom interceptors.

```swift
// ✅ Clean Alamofire syntax for complex requests
AF.request("https://api.example.com/data")
    .validate()
    .responseDecodable(of: Model.self) { response in
        switch response.result {
        case .success(let model):
            print(model)
        case .failure(let error):
            print(error)
        }
    }
```

---

## Async & Concurrency Frameworks

### Combine

Combine provides reactive programming patterns. Use for complex data flows, transformations, and timing-dependent operations.

```swift
// ✅ Declarative data flow with Combine
let searchSubject = PassthroughSubject<String, Never>()

let subscription = searchSubject
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .distinctUntilChanged()
    .flatMap { query in
        URLSession.shared.dataTaskPublisher(for: self.makeURL(query: query))
            .map { $0.data }
            .decode(type: [Result].self, decoder: JSONDecoder())
            .catch { _ in Just([]) }
    }
    .sink { results in
        print(results)
    }
```

**When to use:**
- Complex async operations with operators (map, filter, debounce)
- SwiftUI data binding
- Multiple dependent async tasks
- Real-time data streams

### async/await (Swift Concurrency)

The modern, structured approach to asynchronous code. Use for most new projects.

```swift
// ✅ Modern async/await replaces callbacks
func fetchUser(id: Int) async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: userURL(id))
    return try JSONDecoder().decode(User.self, from: data)
}

// Usage is clean and linear
async {
    do {
        let user = try await fetchUser(id: 123)
        print(user)
    } catch {
        print("Error: \(error)")
    }
}
```

**Advantages:**
- Cleaner syntax than callbacks/Combine for simple cases
- Automatic task cancellation
- Better compiler optimization
- Structured concurrency prevents race conditions

### Structured Concurrency & TaskGroups

Manage multiple concurrent operations safely:

```swift
// ✅ Concurrent operations with TaskGroup
func fetchMultipleUsers(ids: [Int]) async throws -> [User] {
    return try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask {
                try await fetchUser(id: id)
            }
        }
        
        var results = [User]()
        for try await user in group {
            results.append(user)
        }
        return results
    }
}
```

---

## Testing Frameworks

### XCTest (Built-in)

Apple's native testing framework. Essential for unit and integration tests.

```swift
// ✅ Well-structured XCTest
class UserRepositoryTests: XCTestCase {
    var sut: UserRepository!
    
    override func setUp() {
        super.setUp()
        sut = UserRepository()
    }
    
    func testFetchUserSuccess() async throws {
        let user = try await sut.fetchUser(id: 1)
        XCTAssertEqual(user.id, 1)
        XCTAssertFalse(user.name.isEmpty)
    }
    
    func testFetchUserFailure() async throws {
        let error = try XCTUnwrap(
            try? await sut.fetchUser(id: -1) as? URLError
        )
        XCTAssertNotNil(error)
    }
}
```

**Key Testing Patterns:**
- `XCTAssert` family for conditions
- `XCTUnwrap` for optional unwrapping
- Async test support with `async` keyword
- Performance testing with `measure`

### Quick + Nimble (Third-party)

BDD-style testing when you prefer expressive syntax:

```swift
// ✅ Quick + Nimble syntax
describe("UserRepository") {
    var sut: UserRepository!
    
    beforeEach {
        sut = UserRepository()
    }
    
    context("when fetching user") {
        it("returns user with correct ID") {
            let user = try await sut.fetchUser(id: 1)
            expect(user.id).to(equal(1))
        }
    }
}
```

---

## Architecture & Reactive Frameworks

### RxSwift

Reactive Extensions library. Popular but increasingly replaced by Combine/async-await.

```swift
// ✅ RxSwift for reactive patterns (if already invested)
let disposeBag = DisposeBag()

Observable.of(1, 2, 3)
    .map { $0 * 2 }
    .subscribe(onNext: { value in
        print(value)
    })
    .disposed(by: disposeBag)
```

**When to consider:**
- Large projects already using RxSwift
- Complex transformation pipelines
- Cross-platform code (RxSwift vs RxJava, RxJSRecommendation: Use Combine or async/await for new projects

### MVVM + Observation

SwiftUI's built-in observation pattern for modern architecture:

```swift
// ✅ Modern MVVM with @ObservationIgnored
@Observable
class UserViewModel {
    var users: [User] = []
    var isLoading = false
    
    @ObservationIgnored
    private let repository: UserRepository
    
    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            users = try await repository.fetchUsers()
        } catch {
            print("Failed to load users: \(error)")
        }
    }
}
```

### Redux-like State Management

For complex applications, consider Redux patterns:

```swift
// ✅ Redux-like unidirectional data flow
enum AppAction {
    case fetchUsers
    case usersLoaded([User])
    case fetchFailed(Error)
}

struct AppState {
    var users: [User] = []
    var isLoading = false
    var error: Error?
}

func appReducer(state: inout AppState, action: AppAction) {
    switch action {
    case .fetchUsers:
        state.isLoading = true
    case .usersLoaded(let users):
        state.users = users
        state.isLoading = false
    case .fetchFailed(let error):
        state.error = error
        state.isLoading = false
    }
}
```

---

## Performance & Profiling

### Instruments & Performance Monitoring

Use Xcode's Instruments for profiling:

```swift
// ✅ Log performance metrics
import os

let logger = Logger(subsystem: "com.app.performance", category: "networking")

func measureFetch() async {
    let start = Date()
    defer {
        let duration = Date().timeIntervalSince(start)
        logger.info("Fetch took \(duration)ms")
    }
    
    let data = try? await fetchData()
}
```

### Memory Leak Detection

```swift
// ✅ Prevent memory leaks with weak references in closures
class NetworkManager {
    func fetchData(completion: @escaping ([Data]) -> Void) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            completion(data)
        }.resume()
    }
}
```

---

## ✅ Best Practices

### 1. Use Built-in Frameworks First
**DO:**
```swift
// ✅ URLSession + async/await covers 90% of networking needs
let (data, _) = try await URLSession.shared.data(from: url)
```

### 2. Embrace Structured Concurrency
**DO:**
```swift
// ✅ Use async/await instead of callbacks
func loadData() async throws -> Data {
    return try await fetchFromNetwork()
}
```

### 3. Design for Testability
**DO:**
```swift
// ✅ Dependency injection for easy testing
class Repository {
    init(networkClient: NetworkClient = URLSessionClient()) {
        self.networkClient = networkClient
    }
}
```

### 4. Handle Errors Explicitly
**DO:**
```swift
// ✅ Define custom error types
enum NetworkError: LocalizedError {
    case invalidResponse
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .decodingFailed(let error):
            return "Failed to decode: \(error)"
        }
    }
}
```

### 5. Avoid Framework Overload
**DO:**
```swift
// ✅ Know what frameworks are necessary
// Most projects: URLSession, Codable, XCTest
// Complex UI: Combine or SwiftUI
// Large apps: Redux patterns or MVVM
```

---

## ❌ Common Mistakes

### Mistake 1: Using Alamofire When URLSession Suffices

**WRONG:**
```swift
// ❌ Extra dependency for simple requests
AF.request("https://api.example.com/data")
    .responseJSON { response in
        // ...
    }
```

**CORRECT:**
```swift
// ✅ Native URLSession is cleaner now
async {
    let (data, _) = try await URLSession.shared.data(from: url)
}
```

### Mistake 2: Blocking UI Thread with Network Calls

**WRONG:**
```swift
// ❌ Blocks main thread
let data = try Data(contentsOf: url)
updateUI(with: data)
```

**CORRECT:**
```swift
// ✅ Network on background, UI on main
DispatchQueue.global(qos: .userInitiated).async {
    let (data, _) = try await URLSession.shared.data(from: url)
    
    DispatchQueue.main.async {
        self.updateUI(with: data)
    }
}
```

### Mistake 3: Not Handling Errors from Frameworks

**WRONG:**
```swift
// ❌ Silent failures
let data = try? Data(contentsOf: url)
// User has no idea why request failed
```

**CORRECT:**
```swift
// ✅ Explicit error handling
do {
    let (data, _) = try await URLSession.shared.data(from: url)
} catch URLError.notConnectedToInternet {
    showError("No internet connection")
} catch URLError.timedOut {
    showError("Request timed out")
} catch {
    showError("Network error: \(error)")
}
```

### Mistake 4: Mixing Old and New Concurrency Models

**WRONG:**
```swift
// ❌ Mixing callbacks and async/await
func oldStyle(completion: @escaping (Data) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        async {
            // ❌ Confusing mix of patterns
        }
    }.resume()
}
```

**CORRECT:**
```swift
// ✅ Consistent async/await throughout
func newStyle() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

### Mistake 5: Creating Unnecessary Wrappers

**WRONG:**
```swift
// ❌ Over-abstraction
struct NetworkService {
    func makeRequest(url: URL) async -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
```

**CORRECT:**
```swift
// ✅ Use URLSession directly or minimal wrapper for dependency injection
protocol NetworkClient {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkClient {}
```

---

## 🔗 Related Topics
- [Networking and APIs](../03-networking/networking-and-apis.md)
- [Async Patterns](../07-advanced/async-patterns.md)
- [Testing Best Practices](../03-testing/testing-best-practices.md)
- [Architecture Patterns](../02-architecture/design-patterns.md)
