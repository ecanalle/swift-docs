# Clean Code and Refactoring - Best Practices for Maintainability

## Overview

Clean code prioritizes readability, maintainability, and simplicity. Good refactoring practices improve code quality while preserving functionality.

## Main Topics

- [Clean Code Principles](#clean-code-principles)
- [Naming Conventions](#naming-conventions)
- [Function Design](#function-design)
- [Refactoring Techniques](#refactoring-techniques)
- [Code Organization](#code-organization)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Swift Code Style](https://www.swift.org/documentation/api-design-guidelines/)

---

## Clean Code Principles

### DRY (Don't Repeat Yourself)

```swift
// ❌ Repeated code
func validateEmail(_ email: String) -> Bool {
    let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let regex = try? NSRegularExpression(pattern: emailPattern)
    let range = NSRange(email.startIndex..<email.endIndex, in: email)
    return regex?.firstMatch(in: email, range: range) != nil
}

func validatePhone(_ phone: String) -> Bool {
    let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"  // REPEATED!
    let regex = try? NSRegularExpression(pattern: emailPattern)
    let range = NSRange(phone.startIndex..<phone.endIndex, in: phone)
    return regex?.firstMatch(in: phone, range: range) != nil
}

// ✅ Extract common logic
func matches(text: String, pattern: String) -> Bool {
    let regex = try? NSRegularExpression(pattern: pattern)
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex?.firstMatch(in: text, range: range) != nil
}

func validateEmail(_ email: String) -> Bool {
    let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    return matches(text: email, pattern: pattern)
}
```

### SOLID Principles

```swift
// ✅ Single Responsibility
class UserRepository {
    func fetchUser(id: Int) -> User? { /* ... */ }
    func saveUser(_ user: User) { /* ... */ }
}

// ❌ Multiple responsibilities
class User {
    var name: String
    
    func fetchFromDatabase() { /* ... */ }
    func saveToDatabase() { /* ... */ }
    func sendEmail() { /* ... */ }
    func validateData() { /* ... */ }
}
```

---

## Naming Conventions

### Clear Variable Names

```swift
// ❌ Unclear names
let d = 5
let u = fetchUser()
let x = 10

// ✅ Descriptive names
let maxRetryCount = 5
let currentUser = fetchUser()
let screenWidth = 10

// ✅ Boolean names start with is/has/should
let isLoggedIn = true
let hasPermission = false
let shouldRefresh = true
```

### Function Naming

```swift
// ❌ Vague names
func process() { }
func handle(_ data: String) { }
func get() -> [Int] { }

// ✅ Clear intent
func parseJSONResponse(_ json: Data) throws -> User { }
func handleNetworkError(_ error: NetworkError) { }
func fetchAllUsers() async throws -> [User] { }

// ✅ Action verbs
func loadData()
func saveConfiguration()
func validateInput()
func updateUI()
```

---

## Function Design

### Single Responsibility

```swift
// ❌ Does too much
func loginUser(_ username: String, _ password: String) {
    let user = authenticate(username, password)
    
    let request = URLRequest(url: URL(string: "https://api.example.com/login")!)
    let session = URLSession.shared
    let (data, _) = try? session.data(for: request)
    
    let token = parseToken(data)
    UserDefaults.standard.set(token, forKey: "token")
    
    PostNotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: user)
}

// ✅ Break into focused functions
func loginUser(_ username: String, _ password: String) async throws {
    let user = try await authenticate(username, password)
    try await loginAndCacheUser(user)
}

func loginAndCacheUser(_ user: User) async throws {
    let token = try await fetchLoginToken(for: user)
    cacheToken(token)
    notifyUserLoggedIn(user)
}

func authenticate(_ username: String, _ password: String) async throws -> User {
    // Authentication logic
    return User()
}
```

### Function Length

```swift
// ❌ Long function (50+ lines)
func processData(_ data: [String]) -> [Int] {
    // 50 lines of mixed logic
}

// ✅ Shorter, focused functions (≤20 lines)
func processData(_ data: [String]) -> [Int] {
    let cleaned = cleanInput(data)
    let parsed = parseValues(cleaned)
    let validated = validateData(parsed)
    return validated
}

func cleanInput(_ data: [String]) -> [String] {
    return data.map { $0.trimmingCharacters(in: .whitespaces) }
}

func parseValues(_ data: [String]) -> [Int] {
    return data.compactMap { Int($0) }
}

func validateData(_ data: [Int]) -> [Int] {
    return data.filter { $0 > 0 }
}
```

### Error Handling

```swift
// ❌ Silent failures
func fetchData() -> [String]? {
    // No error information
    return nil
}

// ✅ Explicit errors
enum DataError: Error {
    case networkError
    case invalidJSON
    case noData
}

func fetchData() async throws -> [String] {
    // Specific error types
}
```

---

## Refactoring Techniques

### Extract Method

```swift
// Before
func processOrder(_ order: Order) {
    print("Order started")
    
    let subtotal = order.items.reduce(0) { $0 + $1.price }
    let tax = subtotal * 0.1
    let total = subtotal + tax
    
    print("Total: \(total)")
    
    if total > 1000 {
        print("Applying discount")
        // discount logic
    }
}

// After
func processOrder(_ order: Order) {
    let total = calculateTotal(for: order)
    print("Total: \(total)")
    
    applyDiscountIfNeeded(for: total)
}

func calculateTotal(for order: Order) -> Double {
    let subtotal = order.items.reduce(0) { $0 + $1.price }
    let tax = subtotal * 0.1
    return subtotal + tax
}

func applyDiscountIfNeeded(for total: Double) {
    if total > 1000 {
        print("Applying discount")
        // discount logic
    }
}
```

### Replace Magic Numbers

```swift
// ❌ Magic numbers
func validatePassword(_ password: String) -> Bool {
    return password.count >= 8 && password.count <= 128
}

func calculateFinalPrice(_ price: Double) -> Double {
    return price * 1.1  // What's 1.1?
}

// ✅ Named constants
let minPasswordLength = 8
let maxPasswordLength = 128
let taxRate = 0.1

func validatePassword(_ password: String) -> Bool {
    return password.count >= minPasswordLength && 
           password.count <= maxPasswordLength
}

func calculateFinalPrice(_ price: Double) -> Double {
    return price * (1 + taxRate)
}
```

### Simplify Conditionals

```swift
// ❌ Complex condition
if user.age >= 18 && user.country == "USA" && user.hasAgreedToTerms {
    allowAccess()
}

// ✅ Extract to method
func canAccessContent(user: User) -> Bool {
    return user.isAdult && user.isInUSA && user.hasAgreedToTerms
}

if canAccessContent(user: user) {
    allowAccess()
}
```

---

## Code Organization

### File Organization

```swift
// ✅ Organized structure
class UserViewController: UIViewController {
    // MARK: - Properties
    var viewModel: UserViewModel?
    var dataSource: UITableViewDataSource?
    
    // MARK: - Lifecycle
    override func viewDidLoad() { }
    override func viewWillAppear(_ animated: Bool) { }
    
    // MARK: - IBActions
    @IBAction func saveTapped(_ sender: Any) { }
    
    // MARK: - Private Methods
    private func setupUI() { }
    private func loadData() { }
}
```

### Type Organization

```swift
// ✅ Group related types
struct User {
    let id: Int
    let name: String
    
    enum Role {
        case admin
        case user
        case guest
    }
    
    enum Error: Swift.Error {
        case invalidName
        case invalidID
    }
}
```

---

## 🎯 Best Practices

### 1. Write Tests While Refactoring
```swift
// ✅ Tests ensure correctness after refactoring
class UserValidatorTests: XCTestCase {
    func testValidPassword() {
        XCTAssertTrue(validator.isValidPassword("SecurePass123"))
    }
    
    func testInvalidPassword() {
        XCTAssertFalse(validator.isValidPassword("short"))
    }
}
```

### 2. Refactor Small Changes
```swift
// ✅ Small, incremental refactors
// Commit after each safe change

// ❌ Large refactor
// Multiple changes at once increase risk
```

### 3. Use Version Control
```bash
# ✅ Track progress
git commit -m "Extract calculateTotal method"

# ❌ Don't refactor without checkpoints
```

---

## ❌ Common Mistakes

### Mistake 1: Premature Optimization

**WRONG:**
```swift
// ❌ Over-engineered for hypothetical performance
struct ComplexCache<T: Hashable> {
    // 200 lines of advanced logic
}

// For simple use case
var userCache: [Int: User] = [:]
```

**CORRECT:**
```swift
// ✅ Start simple
var userCache: [Int: User] = [:]

// Optimize only if profiling shows bottleneck
```

---

### Mistake 2: Over-Abstraction

**WRONG:**
```swift
// ❌ Too many layers
protocol Validator { }
protocol ValidatorFactory { }
class ConcreteValidatorFactory: ValidatorFactory { }
// 5 more abstraction layers...
```

**CORRECT:**
```swift
// ✅ Straightforward
class Validator {
    func validate(_ input: String) -> Bool { }
}
```

---

### Mistake 3: Ignoring Code Smells

**WRONG:**
```swift
// ❌ Methods growing
func handleUserAction() {
    // 150 lines
}

// Long parameter lists
func configure(a: Int, b: String, c: Bool, d: Double, e: [Int]) { }
```

**CORRECT:**
```swift
// ✅ Break into smaller methods
func handleUserTap() { }
func handleUserSwipe() { }

// Group parameters
struct Configuration {
    let maxRetries: Int
    let endpoint: String
}
```

---

## Related Topics

- [Design Patterns](./02-architecture/software-architecture/design-patterns.md)
- [VIPER Architecture](./02-architecture/software-architecture/viper.md)
- [Testing](./04-app-lifecycle/testing.md)

---

**Master clean code for sustainable, professional software development!**
