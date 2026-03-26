# Software Architecture Fundamentals

## Overview

Architecture is the foundation that determines how maintainable, testable, and scalable your app becomes. Understanding architectural patterns and principles helps you make better design decisions from the start.

## Main Topics

- [Architecture Goals](#architecture-goals)
- [Separation of Concerns](#separation-of-concerns)
- [Design Principles](#design-principles)
- [Layered Architecture](#layered-architecture)
- [SOLID Principles](#solid-principles)
- [Common Pitfalls](#common-pitfalls)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Apple: Architecture Guidance](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/ModelViewController/ModelViewController.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Design Patterns in Swift](https://www.raywenderlich.com/18409174-design-patterns-by-tutorials)

---

## Architecture Goals

### Why Architecture Matters

```swift
// Bad architecture - everything mixed together
class UserController: UIViewController {
    // Business logic
    func calculateDiscount(_ items: [Item]) -> Double {
        var total = 0.0
        for item in items {
            total += item.price
        }
        return total * 0.1
    }
    
    // Network request
    func fetchUser(id: Int) {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                self.parseUser(data)
            }
        }.resume()
    }
    
    // UI logic
    override func viewDidLoad() {
        super.viewDidLoad()
        // Complex UI setup
    }
    
    // Parsing logic
    func parseUser(_ data: Data) {
        // Complex parsing
    }
}
```

### Good Architecture - Separated Concerns

```swift
// Business Logic Layer
struct DiscountCalculator {
    func calculateDiscount(for items: [Item]) -> Double {
        let total = items.reduce(0) { $0 + $1.price }
        return total * 0.1
    }
}

// Network Layer
class UserService {
    func fetchUser(id: Int, completion: @escaping (User) -> Void) {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let user = try? JSONDecoder().decode(User.self, from: data) {
                completion(user)
            }
        }.resume()
    }
}

// Presentation Logic
class UserViewController: UIViewController {
    let userService: UserService
    let discountCalculator: DiscountCalculator
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Only UI setup here
    }
}
```

---

## Separation of Concerns

### UI Layer vs Business Logic

```swift
// ❌ Mixing UI and Business Logic
class ProductViewController: UIViewController {
    func addToCart() {
        var subtotal = 0.0
        for product in products {
            subtotal += product.price * Double(product.quantity)
        }
        let tax = subtotal * 0.08
        let total = subtotal + tax
        
        // Complex calculations embedded in UI code
        updateUI(with: total)
    }
}

// ✅ Separated Concerns
class ShoppingCart {
    var items: [CartItem] = []
    
    var subtotal: Double {
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var tax: Double {
        subtotal * 0.08
    }
    
    var total: Double {
        subtotal + tax
    }
}

class CartViewController: UIViewController {
    let cart = ShoppingCart()
    
    func addToCart() {
        updateUI(with: cart.total)  // Use business logic from model
    }
}
```

### Three-Tier Architecture

```swift
// DATA LAYER - Handles persistence
class UserDatabase {
    func save(user: User) {
        // Database operations
    }
    
    func fetch(id: Int) -> User? {
        // Query database
        return nil
    }
}

// BUSINESS LOGIC LAYER - Core application logic
class UserManager {
    let database: UserDatabase
    
    func registerUser(_ email: String, password: String) -> Result<User, Error> {
        guard isValidEmail(email) else {
            return .failure(.invalidEmail)
        }
        guard isStrongPassword(password) else {
            return .failure(.weakPassword)
        }
        
        let user = User(email: email)
        database.save(user: user)
        return .success(user)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Email validation logic
        return email.contains("@")
    }
    
    private func isStrongPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
}

// PRESENTATION LAYER - UI only
class RegisterViewController: UIViewController {
    let userManager: UserManager
    
    @IBAction func registerTapped() {
        let result = userManager.registerUser(emailTextField.text ?? "", 
                                              password: passwordTextField.text ?? "")
        switch result {
        case .success(let user):
            showSuccessMessage("Welcome, \(user.email)")
        case .failure(let error):
            showErrorMessage(error.description)
        }
    }
}
```

---

## Design Principles

### DRY - Don't Repeat Yourself

```swift
// ❌ Repetitive code
class UserViewController: UIViewController {
    func displayUserInfo(user: User) {
        nameLabel.text = user.name
        emailLabel.text = user.email
        ageLabel.text = "\(user.age)"
    }
    
    func displayEmployeeInfo(employee: Employee) {
        nameLabel.text = employee.name
        emailLabel.text = employee.email
        ageLabel.text = "\(employee.age)"
    }
}

// ✅ Using protocol and shared logic
protocol ProfileProvider {
    var name: String { get }
    var email: String { get }
    var age: Int { get }
}

extension ProfileProvider {
    func displayInfo(on controller: UIViewController) {
        controller.nameLabel.text = name
        controller.emailLabel.text = email
        controller.ageLabel.text = "\(age)"
    }
}

extension User: ProfileProvider {}
extension Employee: ProfileProvider {}
```

### KISS - Keep It Simple, Stupid

```swift
// ❌ Over-engineered
class ComplexCalculator {
    private var operationChain: OperationProtocol = NullOperation()
    
    func executeIfDataValid<T: Validatable>(_ data: T, 
                                           operation: (T) -> Double) -> Double? {
        guard let chain = operationChain as? AbstractOperationChain else { return nil }
        return chain.process(data, with: operation)
    }
}

// ✅ Simple and clear
func calculate(items: [Item]) -> Double {
    items.reduce(0) { $0 + $1.price }
}
```

---

## SOLID Principles

### Single Responsibility Principle

```swift
// ❌ Multiple responsibilities
class APIManager {
    // Fetching
    func fetchData(url: String) { }
    
    // Parsing
    func parseJSON(_ data: Data) { }
    
    // Caching
    func saveToCache(_ data: Data) { }
    
    // Error handling
    func handleError(_ error: Error) { }
}

// ✅ Single responsibility
class HTTPClient {
    func fetchData(from url: URL) async throws -> Data {
        // Only network requests
    }
}

class JSONDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // Only JSON parsing
    }
}

class DataCache {
    func store(_ data: Data, for key: String) {
        // Only caching
    }
}

class ErrorHandler {
    func handle(_ error: Error) -> String {
        // Only error messages
    }
}
```

### Dependency Injection

```swift
// ❌ Hard-coded dependencies
class OrderService {
    let database = Database()  // Can't test with mock
    let emailService = EmailService()  // Can't replace
    
    func processOrder(_ order: Order) {
        database.save(order)
        emailService.send(to: order.email, message: "Order placed")
    }
}

// ✅ Injected dependencies
class OrderService {
    let database: DatabaseProtocol
    let emailService: EmailServiceProtocol
    
    init(database: DatabaseProtocol, emailService: EmailServiceProtocol) {
        self.database = database
        self.emailService = emailService
    }
    
    func processOrder(_ order: Order) {
        database.save(order)
        emailService.send(to: order.email, message: "Order placed")
    }
}

// Testing with mocks
class MockDatabase: DatabaseProtocol {
    // Mock implementation
}

let testService = OrderService(database: MockDatabase(), emailService: MockEmailService())
```

---

## Layered Architecture

Typical app layers:

```
┌─────────────────────────────┐
│     Presentation Layer      │
│   (ViewControllers, Views)  │
└────────────┬────────────────┘
             │
┌────────────▼────────────────┐
│    Application Layer        │
│  (Coordinators, ViewModels) │
└────────────┬────────────────┘
             │
┌────────────▼────────────────┐
│     Domain Layer            │
│  (Business Logic, Entities) │
└────────────┬────────────────┘
             │
┌────────────▼────────────────┐
│      Data Layer             │
│  (Database, Network, Cache) │
└─────────────────────────────┘
```

---

## 🎯 Best Practices

### 1. Start with Clear Boundaries
- Define clear layers
- Each layer has specific responsibility
- Minimize dependencies between layers

### 2. Use Protocols for Abstraction
- Define interfaces
- Make testing easier
- Enable flexibility

### 3. Dependency Injection
- Inject dependencies in `init`
- Makes testing straightforward
- Increases flexibility

### 4. Keep Views Thin
- Views should only handle UI
- Business logic elsewhere
- Data preparation in view model/presenter

### 5. Plan Before Coding
- Sketch architecture
- Identify layers and responsibilities
- Prevents refactoring later

---

## ❌ Common Mistakes

### Mistake 1: Everything in UIViewController

**WRONG:**
```swift
class ProductViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Networking
        // Database
        // Business logic
        // UI setup
        // All mixed together
    }
}
```

**CORRECT:**
```swift
class ProductViewController: UIViewController {
    let viewModel: ProductViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.loadProducts()
    }
    
    private func setupUI() {
        // UI setup only
    }
}

class ProductViewModel {
    let service: ProductService
    
    func loadProducts() {
        // Business logic only
    }
}
```

---

### Mistake 2: Circular Dependencies

**WRONG:**
```swift
class ServiceA {
    let serviceB: ServiceB
}

class ServiceB {
    let serviceA: ServiceA  // Circular!
}
```

**CORRECT:**
```swift
class ServiceA {
    let serviceB: ServiceB
}

class ServiceB {
    // Don't reference ServiceA
}
```

---

### Mistake 3: God Objects

**WRONG:**
```swift
class User {
    // Properties
    var name: String
    
    // Saving
    func save() { }
    
    // Networking
    func fetchProfile() { }
    
    // Validation
    func validate() { }
    
    // Too many responsibilities!
}
```

---

## Related Topics

- [Design Patterns](design-patterns.md)
- [MVVM Pattern](../../02-architecture/mvvm.md)
- [Dependency Injection](../../02-architecture/dependency-injection.md)

---

**Good architecture is the foundation of maintainable apps!**
