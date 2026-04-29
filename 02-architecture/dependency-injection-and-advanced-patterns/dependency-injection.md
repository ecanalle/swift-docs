# Dependency Injection (DI) - Architecture Pattern

## Overview

Dependency Injection is an architectural pattern that promotes loose coupling by providing dependencies from outside rather than creating them internally. It enables testability, flexibility, and maintainability.

## Main Topics

- [DI Concepts](#di-concepts)
- [Injection Methods](#injection-methods)
- [Service Locator Pattern](#service-locator-pattern)
- [DI Containers](#di-containers)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Dependency Injection in Swift](https://www.swift.org)

---

## DI Concepts

### Tight Coupling (❌ Avoid)

```swift
// ❌ Direct dependency - hard to test
class UserService {
    private let database = DatabaseManager()  // Creates its own
    
    func getUser(id: Int) -> User? {
        return database.query("SELECT * FROM users WHERE id = ?", id)
    }
}

// Problem: Can't test without real database
let service = UserService()
// Must use actual database
```

### Loose Coupling (✅ Prefer)

```swift
// ✅ Dependency injected - easy to test
protocol UserRepository {
    func getUser(id: Int) -> User?
}

class UserService {
    private let repository: UserRepository  // Injected dependency
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func getUser(id: Int) -> User? {
        return repository.getUser(id: id)
    }
}

// In production
let database = DatabaseManager()
let service = UserService(repository: database)

// In testing
let mockRepo = MockUserRepository()
let testService = UserService(repository: mockRepo)
```

---

## Injection Methods

### Constructor Injection (Recommended)

```swift
protocol Logger {
    func log(_ message: String)
}

class UserViewController: UIViewController {
    private let logger: Logger
    
    // ✅ Dependency provided via constructor
    init(logger: Logger) {
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.log("View loaded")
    }
}

// Usage
let logger = ConsoleLogger()
let viewController = UserViewController(logger: logger)
```

### Property Injection

```swift
class UserViewController: UIViewController {
    var logger: Logger?  // ⚠️ Optional - may not be set
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger?.log("View loaded")
    }
}

// Usage
let vc = UserViewController()
vc.logger = ConsoleLogger()
```

### Method Injection

```swift
class ReportGenerator {
    func generate(data: [String], using logger: Logger) -> Report {
        logger.log("Generating report")
        return Report(data: data)
    }
}

// Usage - dependency passed per method call
let generator = ReportGenerator()
let report = generator.generate(data: data, using: logger)
```

### Closure Injection

```swift
class NetworkService {
    let onError: (Error) -> Void
    
    init(onError: @escaping (Error) -> Void) {
        self.onError = onError
    }
    
    func fetchData() {
        // On error, call injected closure
        onError(NetworkError.timeout)
    }
}

// Usage
let service = NetworkService { error in
    print("Error occurred: \(error)")
}
```

---

## Service Locator Pattern

### Simple Service Locator

```swift
class ServiceLocator {
    private static var services: [String: Any] = [:]
    
    static func register<T>(_ service: T, for key: String) {
        services[key] = service
    }
    
    static func resolve<T>(_ key: String) -> T? {
        return services[key] as? T
    }
}

protocol APIClient {
    func fetch(_ url: String) -> Data?
}

class NetworkAPIClient: APIClient {
    func fetch(_ url: String) -> Data? {
        // Network request
        return nil
    }
}

// Register
ServiceLocator.register(NetworkAPIClient(), for: "APIClient")

// Use
if let client: APIClient = ServiceLocator.resolve("APIClient") {
    client.fetch("https://api.example.com")
}
```

### ⚠️ Service Locator Drawbacks

```swift
// ❌ Hard to test - unclear dependencies
class UserViewModel {
    func loadUsers() {
        let api: APIClient = ServiceLocator.resolve("APIClient") ?? MockClient()
        // Where does APIClient come from? Not obvious
    }
}

// ✅ Constructor injection - clear dependencies
class UserViewModel {
    let api: APIClient
    
    init(api: APIClient) {
        self.api = api  // Clear where it comes from
    }
}
```

---

## DI Containers

### Manual Container

```swift
class DIContainer {
    // Lazy initialization
    private var _userService: UserService?
    private var _authService: AuthService?
    
    var userService: UserService {
        if _userService == nil {
            _userService = UserService(
                repository: UserRepository()
            )
        }
        return _userService!
    }
    
    var authService: AuthService {
        if _authService == nil {
            _authService = AuthService(
                tokenManager: TokenManager()
            )
        }
        return _authService!
    }
}

// Usage
let container = DIContainer()
let userService = container.userService
```

### Factory Pattern Container

```swift
class ServiceFactory {
    // Factories create instances
    static func makeUserService() -> UserService {
        let database = DatabaseManager()
        let repository = UserRepository(database: database)
        return UserService(repository: repository)
    }
    
    static func makeAuthService() -> AuthService {
        let tokenManager = TokenManager()
        let cache = TokenCache()
        return AuthService(
            tokenManager: tokenManager,
            cache: cache
        )
    }
}

// Usage
let userService = ServiceFactory.makeUserService()
let authService = ServiceFactory.makeAuthService()
```

### Generic Container

```swift
class Container {
    private var factories: [String: () -> Any] = [:]
    
    func register<T>(_ key: String, factory: @escaping () -> T) {
        factories[key] = factory
    }
    
    func resolve<T>(_ key: String) -> T? {
        return factories[key]?() as? T
    }
}

// Setup
let container = Container()

container.register("UserRepository") {
    UserRepository(database: DatabaseManager())
}

container.register("UserService") {
    let repo: UserRepository = container.resolve("UserRepository")!
    return UserService(repository: repo)
}

// Usage
let service: UserService = container.resolve("UserService")!
```

---

## Advanced Patterns

### Scoped Dependencies

```swift
class ScopedContainer {
    typealias Scope = [String: Any]
    
    private var scopes: [String: Scope] = [:]
    
    func createScope(_ name: String) {
        scopes[name] = [:]
    }
    
    func register<T>(_ key: String, in scope: String, factory: @escaping () -> T) {
        scopes[scope]?[key] = factory
    }
    
    func resolve<T>(_ key: String, from scope: String) -> T? {
        if let factory = scopes[scope]?[key] as? () -> T {
            return factory()
        }
        return nil
    }
}

// Application scope
let container = ScopedContainer()
container.createScope("app")
container.register("AppService", in: "app") {
    AppService()
}

// View controller scope
container.createScope("user_detail")
container.resolve("AppService", from: "user_detail")
```

### Thread-Safe Container

```swift
class ThreadSafeContainer {
    private let lock = NSLock()
    private var factories: [String: () -> Any] = [:]
    
    func register<T>(_ key: String, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        factories[key] = factory
    }
    
    func resolve<T>(_ key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return factories[key]?() as? T
    }
}
```

### Constructor Auto-Wiring

```swift
class SmartContainer {
    private var singletons: [String: Any] = [:]
    
    func resolve<T>(for type: T.Type) -> T? {
        // Attempt to find in cache
        let key = String(describing: type)
        if let cached = singletons[key] as? T {
            return cached
        }
        
        // Create new instance
        // In real implementation, use Mirror for introspection
        let instance = type.init() as? T  // Simplified
        
        // Cache for reuse
        if let instance = instance {
            singletons[key] = instance
        }
        return instance
    }
}
```

---

## 🎯 Best Practices

### 1. Prefer Constructor Injection
```swift
// ✅ Clear dependencies
class UserViewController: UIViewController {
    let userService: UserService
    
    init(userService: UserService) {
        self.userService = userService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

// ❌ Hidden dependencies
class UserViewController: UIViewController {
    func viewDidLoad() {
        let service = UserService()  // Where from?
    }
}
```

### 2. Define Clear Protocols
```swift
// ✅ Protocol contract
protocol UserRepository {
    func getUser(id: Int) -> User?
    func saveUser(_ user: User)
}

class UserService {
    let repository: UserRepository
    init(repository: UserRepository) {
        self.repository = repository
    }
}

// ❌ Concrete dependencies
class UserService {
    let repository: SQLiteRepository  // Tightly coupled
}
```

### 3. Separate Configuration from Usage
```swift
// ✅ Setup once
let container = setupDependencies()

// Use throughout app
let userService: UserService = container.resolve()

// ❌ Scattered setup
class UserViewController {
    let service = UserService(
        repository: UserRepository()
    )
}
```

---

## ❌ Common Mistakes

### Mistake 1: Hidden Dependencies

**WRONG:**
```swift
// ❌ Dependency created internally
class PaymentService {
    private let gateway = StripeGateway()  // Hidden!
    
    func processPayment(_ amount: Double) {
        gateway.charge(amount)
    }
}

// Can't test with fake gateway
```

**CORRECT:**
```swift
// ✅ Dependency injected
protocol PaymentGateway {
    func charge(_ amount: Double)
}

class PaymentService {
    let gateway: PaymentGateway
    
    init(gateway: PaymentGateway) {
        self.gateway = gateway
    }
    
    func processPayment(_ amount: Double) {
        gateway.charge(amount)
    }
}
```

---

### Mistake 2: Optional Dependencies

**WRONG:**
```swift
// ❌ Optional suggests missing setup
class APIClient {
    var logger: Logger?  // May not be set
    
    func request(_ url: String) {
        logger?.log(url)  // May exist or not
    }
}
```

**CORRECT:**
```swift
// ✅ Clear requirement
class APIClient {
    let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func request(_ url: String) {
        logger.log(url)  // Always exists
    }
}
```

---

### Mistake 3: Circular Dependencies

**WRONG:**
```swift
// ❌ Circular dependency
class ServiceA {
    let serviceB: ServiceB
    init(serviceB: ServiceB) { self.serviceB = serviceB }
}

class ServiceB {
    let serviceA: ServiceA
    init(serviceA: ServiceA) { self.serviceA = serviceA }
}

// Can't create either!
```

**CORRECT:**
```swift
// ✅ Break cycle with protocol
protocol EventEmitter {
    func emit(_ event: String)
}

class ServiceA {
    let dispatcher: EventEmitter
    init(dispatcher: EventEmitter) { self.dispatcher = dispatcher }
}

class ServiceB: EventEmitter {
    func emit(_ event: String) { }
}
```

---

## Related Topics

- [Design Patterns](design-patterns.md)
- [VIPER Architecture](viper.md)
- [Testing](../../04-app-lifecycle/testing.md)
- [Architecture](software-architecture.md)

---

**Master Dependency Injection for flexible, testable architecture!**
