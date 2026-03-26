# Testing in Swift

## Overview

Testing is essential for building reliable apps. Swift provides powerful testing frameworks including XCTest for unit and UI testing, and snapshot testing libraries for visual regression detection. Comprehensive testing catches bugs early and enables confident refactoring.

## Main Topics

- [Unit Testing Basics](#unit-testing-basics)
- [XCTest Framework](#xctest-framework)
- [Mocking and Stubs](#mocking-and-stubs)
- [UI Testing](#ui-testing)
- [Test Organization](#test-organization)
- [Coverage and Best Practices](#coverage-and-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Best Practices - Apple](https://developer.apple.com/videos/play/wwdc2023/10147/)

---

## Unit Testing Basics

### Simple Unit Test

```swift
import XCTest

class CalculatorTests: XCTestCase {
    
    var calculator: Calculator!
    
    override func setUp() {
        super.setUp()
        calculator = Calculator()
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    func testAddition() {
        let result = calculator.add(2, 3)
        XCTAssertEqual(result, 5)
    }
    
    func testSubtraction() {
        let result = calculator.subtract(10, 3)
        XCTAssertEqual(result, 7)
    }
    
    func testMultiplication() {
        let result = calculator.multiply(4, 5)
        XCTAssertEqual(result, 20)
    }
}

// Implementation to test
class Calculator {
    func add(_ a: Int, _ b: Int) -> Int {
        return a + b
    }
    
    func subtract(_ a: Int, _ b: Int) -> Int {
        return a - b
    }
    
    func multiply(_ a: Int, _ b: Int) -> Int {
        return a * b
    }
}
```

### Async Test

```swift
class AsyncCalculatorTests: XCTestCase {
    
    var asyncCalculator: AsyncCalculator!
    
    override func setUp() {
        super.setUp()
        asyncCalculator = AsyncCalculator()
    }
    
    func testAsyncAddition() async throws {
        let result = try await asyncCalculator.asyncAdd(2, 3)
        XCTAssertEqual(result, 5)
    }
    
    func testAsyncResult() async {
        let expectation = expectation(description: "Async operation completes")
        
        Task {
            do {
                let result = try await asyncCalculator.asyncAdd(2, 3)
                XCTAssertEqual(result, 5)
                expectation.fulfill()
            } catch {
                XCTFail("Should not throw")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5)
    }
}
```

---

## XCTest Framework

### Assertion Methods

```swift
class AssertionTests: XCTestCase {
    
    func testAssertEqual() {
        let result = 2 + 2
        XCTAssertEqual(result, 4, "Addition should be correct")
    }
    
    func testAssertNotEqual() {
        XCTAssertNotEqual(5, 3)
    }
    
    func testAssertTrue() {
        let isValid = true
        XCTAssertTrue(isValid)
    }
    
    func testAssertFalse() {
        let isEmpty = false
        XCTAssertFalse(isEmpty)
    }
    
    func testAssertNil() {
        let optional: String? = nil
        XCTAssertNil(optional)
    }
    
    func testAssertNotNil() {
        let optional: String? = "value"
        XCTAssertNotNil(optional)
    }
    
    func testAssertGreaterThan() {
        XCTAssertGreaterThan(10, 5)
    }
    
    func testAssertThrows() {
        XCTAssertThrowsError(try riskyFunction())
    }
    
    func testAssertNoThrows() {
        XCTAssertNoThrow(try safeFunction())
    }
    
    private func riskyFunction() throws {
        throw NSError(domain: "test", code: -1)
    }
    
    private func safeFunction() throws {
        return
    }
}
```

---

## Mocking and Stubs

### Protocol-Based Mocking

```swift
protocol NetworkService {
    func fetchUser(id: Int) async throws -> User
}

class MockNetworkService: NetworkService {
    var mockUser: User?
    var shouldThrowError = false
    
    func fetchUser(id: Int) async throws -> User {
        if shouldThrowError {
            throw NSError(domain: "mock", code: -1)
        }
        
        if let user = mockUser {
            return user
        }
        
        throw NSError(domain: "mock", code: -2)
    }
}

class UserViewModelTests: XCTestCase {
    
    var viewModel: UserViewModel!
    var mockService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        mockService = MockNetworkService()
        viewModel = UserViewModel(service: mockService)
    }
    
    func testLoadUserSuccess() async throws {
        let expectedUser = User(id: 1, name: "John")
        mockService.mockUser = expectedUser
        
        let user = try await viewModel.loadUser(id: 1)
        XCTAssertEqual(user.name, "John")
    }
    
    func testLoadUserError() async {
        mockService.shouldThrowError = true
        
        do {
            _ = try await viewModel.loadUser(id: 1)
            XCTFail("Should throw error")
        } catch {
            // Expected
        }
    }
}

class UserViewModel {
    let service: NetworkService
    
    init(service: NetworkService) {
        self.service = service
    }
    
    func loadUser(id: Int) async throws -> User {
        return try await service.fetchUser(id: id)
    }
}
```

---

## UI Testing

### Basic UI Test

```swift
class AppUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }
    
    func testLoginFlow() {
        // Find elements
        let emailField = app.textFields["email"]
        let passwordField = app.secureTextFields["password"]
        let loginButton = app.buttons["Login"]
        
        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(passwordField.exists)
        XCTAssertTrue(loginButton.exists)
        
        // Interact with elements
        emailField.tap()
        emailField.typeText("user@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Verify button state
        XCTAssertTrue(loginButton.isEnabled)
        
        // Tap button
        loginButton.tap()
        
        // Wait for next screen
        let welcomeLabel = app.staticTexts["Welcome"]
        XCTAssertTrue(welcomeLabel.waitForExistence(timeout: 5))
    }
    
    func testTableViewInteraction() {
        let table = app.tables.firstMatch
        
        XCTAssertTrue(table.exists)
        
        let cells = table.cells
        XCTAssertGreaterThan(cells.count, 0)
        
        // Tap first cell
        cells.element(boundBy: 0).tap()
        
        // Verify navigation
        let detailLabel = app.staticTexts["DetailView"]
        XCTAssertTrue(detailLabel.waitForExistence(timeout: 5))
    }
}
```

---

## Test Organization

### Test Structure

```swift
class UserServiceTests: XCTestCase {
    
    var sut: UserService!  // System Under Test
    var mockRepository: MockUserRepository!
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = UserService(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - User Creation Tests
    
    func testCreateUserSuccess() throws {
        let user = try sut.createUser(name: "John", email: "john@example.com")
        XCTAssertEqual(user.name, "John")
    }
    
    func testCreateUserWithInvalidEmail() {
        XCTAssertThrowsError(
            try sut.createUser(name: "John", email: "invalid")
        )
    }
    
    // MARK: - User Fetching Tests
    
    func testFetchUser() throws {
        let user = User(id: 1, name: "John")
        mockRepository.mockUser = user
        
        let fetched = try sut.fetchUser(id: 1)
        XCTAssertEqual(fetched.id, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser(name: String = "Test") -> User {
        return User(id: 1, name: name)
    }
}
```

---

## Coverage and Best Practices

### Code Coverage

```swift
// XCTest automatically tracks coverage
// View coverage in Xcode:
// 1. Product > Scheme > Edit Scheme
// 2. Test > Code Coverage: ON
// 3. Run tests
// 4. View in Report Navigator

// Target 80%+ code coverage
// Focus on critical paths, not 100%

class CoverageExample {
    func importantFunction(value: Int) throws -> Int {
        guard value > 0 else {
            throw ValidationError.negativeValue
        }
        
        return value * 2
    }
    
    // Should test:
    // - Success case
    // - Negative value error
    // - Return value correctness
}
```

### Naming Conventions

```swift
class TestNameingExample: XCTestCase {
    
    // Good: _MethodName_Scenario_ExpectedResult
    func testFetchUsers_WithValidID_ReturnsUser() { }
    
    func testFetchUsers_WithInvalidID_ThrowsError() { }
    
    func testFetchUsers_WithNetworkError_ThrowsNetworkError() { }
    
    // Bad: vague names
    func testFetchUsers() { }
    func testError() { }
}
```

---

## 🎯 Best Practices

### 1. Follow AAA Pattern
- Arrange (setup)
- Act (execute)
- Assert (verify)

### 2. One Assertion Per Test (Usually)
- Makes failures clear
- Each test should verify one thing

### 3. Use Descriptive Names
- Test name should describe what is tested
- Easy to understand from test runner output

### 4. Test Behavior, Not Implementation
- Test what the code does, not how
- Don't test private methods directly

### 5. Keep Tests Fast
- Mock external dependencies
- Don't hit real APIs
- Use test data efficiently

---

## ❌ Common Mistakes

### Mistake 1: Testing Implementation

**WRONG:**
```swift
func testAdd() {
    let result = calculator.a + calculator.b  // Testing internals
    XCTAssertEqual(result, 5)
}
```

**CORRECT:**
```swift
func testAdd() {
    let result = calculator.add(2, 3)  // Testing behavior
    XCTAssertEqual(result, 5)
}
```

---

### Mistake 2: Multiple Assertions

**WRONG:**
```swift
func testUserCreation() {
    let user = createUser(name: "John")
    XCTAssertEqual(user.name, "John")
    XCTAssertEqual(user.id, 1)
    XCTAssertNotNil(user.email)  // Which failed?
}
```

**CORRECT:**
```swift
func testUserName() {
    let user = createUser(name: "John")
    XCTAssertEqual(user.name, "John")
}

func testUserID() {
    let user = createUser(name: "John")
    XCTAssertEqual(user.id, 1)
}
```

---

### Mistake 3: Testing Private Methods

**WRONG:**
```swift
func testPrivateLogic() {
    sut.privateMethod()  // Can't test private
}
```

**CORRECT:**
```swift
func testPublicBehavior() {
    sut.publicMethod()  // Tests private indirectly
    XCTAssertEqual(sut.result, expected)
}
```

---

## Related Topics

- [CI/CD and Testing](../../04-app-lifecycle/ci-cd-and-deployment.md)
- [Debugging and Tools](../../04-app-lifecycle/debug-tools.md)
- [Performance Testing](performance-testing.md)

---

**Comprehensive testing ensures robust, reliable applications!**
