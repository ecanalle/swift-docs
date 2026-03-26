# Unit Testing - App Testing Strategy

## Overview

Unit testing validates individual components in isolation. XCTest provides the foundation for iOS testing with XCTestCase and expectations.

## Main Topics

- [Basic Testing](#basic-testing)
- [Async Testing](#async-testing)
- [Mocking](#mocking)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [XCTest](https://developer.apple.com/documentation/xctest)

---

## Basic Testing

### Simple Unit Tests

```swift
import XCTest

class CalculatorService {
    func add(_ a: Int, _ b: Int) -> Int {
        return a + b
    }
    
    func divide(_ a: Int, _ b: Int) -> Int? {
        guard b != 0 else { return nil }
        return a / b
    }
}

class CalculatorTests: XCTestCase {
    var calculator: CalculatorService!
    
    override func setUp() {
        super.setUp()
        calculator = CalculatorService()
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    func testAddition() {
        let result = calculator.add(2, 3)
        XCTAssertEqual(result, 5)
    }
    
    func testAdditionNegative() {
        let result = calculator.add(-2, -3)
        XCTAssertEqual(result, -5)
    }
    
    func testDivideSuccess() {
        let result = calculator.divide(10, 2)
        XCTAssertEqual(result, 5)
    }
    
    func testDivideByZero() {
        let result = calculator.divide(10, 0)
        XCTAssertNil(result)
    }
}
```

### Testing ViewModels

```swift
import XCTest

@testable import MyApp

class UserViewModelTests: XCTestCase {
    var viewModel: UserViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = UserViewModel()
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isLoggedIn)
        XCTAssertNil(viewModel.user)
    }
    
    func testLoginSuccess() {
        viewModel.login(email: "test@example.com", password: "password123")
        
        XCTAssertTrue(viewModel.isLoggedIn)
        XCTAssertNotNil(viewModel.user)
        XCTAssertEqual(viewModel.user?.email, "test@example.com")
    }
    
    func testLoginFailure() {
        viewModel.login(email: "", password: "")
        
        XCTAssertFalse(viewModel.isLoggedIn)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testLogout() {
        viewModel.login(email: "test@example.com", password: "password123")
        viewModel.logout()
        
        XCTAssertFalse(viewModel.isLoggedIn)
        XCTAssertNil(viewModel.user)
    }
}
```

---

## Async Testing

### Testing Async Functions

```swift
import XCTest

class AsyncServiceTests: XCTestCase {
    var service: AsyncService!
    
    override func setUp() {
        super.setUp()
        service = AsyncService()
    }
    
    func testFetchDataAsync() async throws {
        let data = try await service.fetchData()
        
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data.count, 0)
    }
    
    func testFetchDataWithTimeout() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let data = try await service.fetchData()
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// Test runner with timeout
class TimeoutTests: XCTestCase {
    func testWithTimeout() async throws {
        let timeoutExpectation = expectation(description: "Timeout")
        timeoutExpectation.expectedFulfillmentCount = 1
        
        let task = Task {
            // Long operation
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        // Wait with timeout
        wait(for: [timeoutExpectation], timeout: 5.0)
        
        task.cancel()
    }
}
```

---

## Mocking

### Simple Mock Objects

```swift
import XCTest

protocol NetworkService {
    func fetchUser(_ id: Int) async throws -> User
    func saveUser(_ user: User) async throws
}

class MockNetworkService: NetworkService {
    var fetchUserCalled = false
    var saveUserCalled = false
    var fetchUserError: Error?
    
    func fetchUser(_ id: Int) async throws -> User {
        fetchUserCalled = true
        
        if let error = fetchUserError {
            throw error
        }
        
        return User(id: id, name: "Mock User", email: "mock@example.com")
    }
    
    func saveUser(_ user: User) async throws {
        saveUserCalled = true
    }
}

class UserRepositoryTests: XCTestCase {
    var repository: UserRepository!
    var mockService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        mockService = MockNetworkService()
        repository = UserRepository(service: mockService)
    }
    
    func testFetchUserCallsService() async throws {
        _ = try await repository.getUser(id: 1)
        
        XCTAssertTrue(mockService.fetchUserCalled)
    }
    
    func testFetchUserHandlesError() async throws {
        mockService.fetchUserError = NSError(domain: "Network", code: -1)
        
        do {
            _ = try await repository.getUser(id: 1)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(mockService.fetchUserCalled)
        }
    }
}
```

### Advanced Mock with Capture

```swift
import XCTest

class AdvancedMockService: NetworkService {
    var capturedRequests: [String] = []
    
    func fetchUser(_ id: Int) async throws -> User {
        capturedRequests.append("fetchUser(\(id))")
        return User(id: id, name: "Test", email: "test@test.com")
    }
    
    func saveUser(_ user: User) async throws {
        capturedRequests.append("saveUser(\(user.id))")
    }
}

class CaptureTests: XCTestCase {
    func testCapturesCalls() async throws {
        let mock = AdvancedMockService()
        
        _ = try await mock.fetchUser(1)
        try await mock.saveUser(User(id: 1, name: "Test", email: "test@test.com"))
        
        XCTAssertEqual(mock.capturedRequests.count, 2)
        XCTAssertEqual(mock.capturedRequests[0], "fetchUser(1)")
    }
}
```

---

## 🎯 Best Practices

### 1. Test One Thing Per Test
```swift
// ✅ Single assertion per test
func testLoginSuccess() {
    viewModel.login(email: "test@example.com", password: "password123")
    XCTAssertTrue(viewModel.isLoggedIn)
}

// ❌ Multiple concerns
func testLoginAndFetch() {
    viewModel.login(...)
    viewModel.fetchData()
    XCTAssertTrue(viewModel.isLoggedIn)
    XCTAssertNotNil(viewModel.data)
}
```

### 2. Use Setup and Teardown
```swift
// ✅ Clean state for each test
override func setUp() {
    super.setUp()
    service = MockService()
}

override func tearDown() {
    service = nil
    super.tearDown()
}

// ❌ Reuse state between tests
var service = MockService()  // Shared state
```

### 3. Name Tests Clearly
```swift
// ✅ Descriptive names
func testLoginWithValidCredentialsSucceeds() { }
func testLoginWithEmptyPasswordFails() { }

// ❌ Vague names
func testLogin() { }
func test1() { }
```

---

## ❌ Common Mistakes

### Mistake 1: Not Isolating Tests

**WRONG:**
```swift
// ❌ Tests depend on each other
var data: [String] = []

func testAddItem() {
    data.append("item")
    XCTAssertEqual(data.count, 1)
}

func testRemoveItem() {
    data.removeLast()  // Fails if testAddItem didn't run
}
```

**CORRECT:**
```swift
// ✅ Each test is independent
func testAddItem() {
    var data: [String] = []
    data.append("item")
    XCTAssertEqual(data.count, 1)
}

func testRemoveItem() {
    var data = ["item"]
    data.removeLast()
    XCTAssertEqual(data.count, 0)
}
```

---

### Mistake 2: Not Testing Error Cases

**WRONG:**
```swift
// ❌ Only happy path
func testFetchData() async throws {
    let data = try await service.fetchData()
    XCTAssertNotNil(data)
}
```

**CORRECT:**
```swift
// ✅ Test error cases too
func testFetchDataSuccess() async throws {
    let data = try await service.fetchData()
    XCTAssertNotNil(data)
}

func testFetchDataError() async throws {
    mockService.shouldFail = true
    
    do {
        _ = try await service.fetchData()
        XCTFail("Should throw")
    } catch {
        XCTAssertNotNil(error)
    }
}
```

---

## Related Topics

- [Async/Await](../02-concurrency/async-await.md)
- [Error Handling](../01-fundamentals/error-handling.md)
- [SwiftUI Testing](../05-features/swiftui-basics.md)

---

**Test your code thoroughly!**
