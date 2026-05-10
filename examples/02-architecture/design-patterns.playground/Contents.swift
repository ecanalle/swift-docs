import Foundation

// ============================================================================
// DESIGN PATTERNS IN SWIFT - Complete Playground Guide
// Corresponds to: 02-architecture/software-architecture/design-patterns.md
// ============================================================================

// SECTION 1: Singleton Pattern
// ============================================================================

print("=== SINGLETON PATTERN ===\n")

// ❌ WRONG: Non-thread-safe singleton
class BadSingleton {
    static var shared: BadSingleton?
    
    private init() {}
    
    func doSomething() {
        print("Doing something")
    }
}

// ✅ CORRECT: Thread-safe singleton with lazy initialization
class AppConfig {
    static let shared = AppConfig()
    
    let appName = "MyApp"
    let version = "1.0"
    
    private init() {
        print("AppConfig initialized (only once)")
    }
    
    func getSettings() -> [String: String] {
        return ["name": appName, "version": version]
    }
}

// Using singleton
let config1 = AppConfig.shared
let config2 = AppConfig.shared
print("Same instance: \(config1 === config2)")
print("Settings: \(config1.getSettings())")


// SECTION 2: Factory Pattern
// ============================================================================

print("\n=== FACTORY PATTERN ===\n")

// Define protocols
protocol DataSource {
    func fetch() -> String
}

// Concrete implementations
class APIDataSource: DataSource {
    func fetch() -> String {
        return "Data from API"
    }
}

class LocalDataSource: DataSource {
    func fetch() -> String {
        return "Data from Local Storage"
    }
}

class CacheDataSource: DataSource {
    func fetch() -> String {
        return "Data from Cache"
    }
}

// ✅ Factory
class DataSourceFactory {
    enum SourceType {
        case api
        case local
        case cache
    }
    
    static func create(type: SourceType) -> DataSource {
        switch type {
        case .api:
            print("Creating API data source")
            return APIDataSource()
        case .local:
            print("Creating Local data source")
            return LocalDataSource()
        case .cache:
            print("Creating Cache data source")
            return CacheDataSource()
        }
    }
}

// Using factory
let apiSource = DataSourceFactory.create(type: .api)
print(apiSource.fetch())

let localSource = DataSourceFactory.create(type: .local)
print(localSource.fetch())


// SECTION 3: Builder Pattern
// ============================================================================

print("\n=== BUILDER PATTERN ===\n")

// ❌ WRONG: Too many initializers
class UserWrong {
    let name: String
    let email: String
    let age: Int?
    let phone: String?
    let address: String?
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
        self.age = nil
        self.phone = nil
        self.address = nil
    }
    
    init(name: String, email: String, age: Int) {
        self.name = name
        self.email = email
        self.age = age
        self.phone = nil
        self.address = nil
    }
    // ... more initializers
}

// ✅ CORRECT: Builder pattern
class User {
    let name: String
    let email: String
    var age: Int?
    var phone: String?
    var address: String?
    
    private init(name: String, email: String) {
        self.name = name
        self.email = email
    }
    
    class Builder {
        private let name: String
        private let email: String
        private var age: Int?
        private var phone: String?
        private var address: String?
        
        init(name: String, email: String) {
            self.name = name
            self.email = email
        }
        
        func withAge(_ age: Int) -> Builder {
            self.age = age
            return self
        }
        
        func withPhone(_ phone: String) -> Builder {
            self.phone = phone
            return self
        }
        
        func withAddress(_ address: String) -> Builder {
            self.address = address
            return self
        }
        
        func build() -> User {
            let user = User(name: name, email: email)
            user.age = age
            user.phone = phone
            user.address = address
            return user
        }
    }
}

// Using builder
let user = User.Builder(name: "John", email: "john@example.com")
    .withAge(30)
    .withPhone("555-1234")
    .withAddress("123 Main St")
    .build()

print("User: \(user.name), Email: \(user.email), Age: \(user.age ?? 0)")


// SECTION 4: Observer Pattern
// ============================================================================

print("\n=== OBSERVER PATTERN ===\n")

protocol Observer: AnyObject {
    func update(with value: Int)
}

class Subject {
    private var observers: [Observer] = []
    private var value: Int = 0 {
        didSet {
            notifyObservers()
        }
    }
    
    func attach(_ observer: Observer) {
        observers.append(observer)
        print("Observer attached")
    }
    
    func detach(_ observer: Observer) {
        observers.removeAll { $0 === observer }
        print("Observer detached")
    }
    
    func notifyObservers() {
        observers.forEach { $0.update(with: value) }
    }
    
    func setValue(_ newValue: Int) {
        value = newValue
    }
}

// Concrete observer
class ConsoleObserver: Observer {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    func update(with value: Int) {
        print("[\(name)] Value changed to: \(value)")
    }
}

// Using observer pattern
let subject = Subject()
let observer1 = ConsoleObserver(name: "Observer 1")
let observer2 = ConsoleObserver(name: "Observer 2")

subject.attach(observer1)
subject.attach(observer2)
subject.setValue(42)
subject.setValue(100)


// SECTION 5: Strategy Pattern
// ============================================================================

print("\n=== STRATEGY PATTERN ===\n")

protocol PaymentStrategy {
    func pay(amount: Double) -> Bool
}

class CreditCardPayment: PaymentStrategy {
    let cardNumber: String
    
    init(cardNumber: String) {
        self.cardNumber = cardNumber
    }
    
    func pay(amount: Double) -> Bool {
        print("💳 Paying $\(amount) with Credit Card ****\(cardNumber.suffix(4))")
        return true
    }
}

class PayPalPayment: PaymentStrategy {
    let email: String
    
    init(email: String) {
        self.email = email
    }
    
    func pay(amount: Double) -> Bool {
        print("🅿️ Paying $\(amount) with PayPal (\(email))")
        return true
    }
}

class ApplePayPayment: PaymentStrategy {
    func pay(amount: Double) -> Bool {
        print("🍎 Paying $\(amount) with Apple Pay")
        return true
    }
}

// Context
class ShoppingCart {
    private var strategy: PaymentStrategy?
    
    func setPaymentStrategy(_ strategy: PaymentStrategy) {
        self.strategy = strategy
    }
    
    func checkout(amount: Double) {
        guard let strategy = strategy else {
            print("No payment strategy selected")
            return
        }
        let success = strategy.pay(amount: amount)
        if success {
            print("✅ Transaction successful")
        }
    }
}

// Using strategy pattern
let cart = ShoppingCart()

cart.setPaymentStrategy(CreditCardPayment(cardNumber: "4111111111111111"))
cart.checkout(amount: 99.99)

cart.setPaymentStrategy(PayPalPayment(email: "user@example.com"))
cart.checkout(amount: 49.99)

cart.setPaymentStrategy(ApplePayPayment())
cart.checkout(amount: 29.99)


// SECTION 6: Decorator Pattern
// ============================================================================

print("\n=== DECORATOR PATTERN ===\n")

protocol Coffee {
    func getDescription() -> String
    func getCost() -> Double
}

class SimpleCoffee: Coffee {
    func getDescription() -> String {
        return "Simple Coffee"
    }
    
    func getCost() -> Double {
        return 2.0
    }
}

class CoffeeDecorator: Coffee {
    private let decoratedCoffee: Coffee
    
    init(_ coffee: Coffee) {
        decoratedCoffee = coffee
    }
    
    func getDescription() -> String {
        return decoratedCoffee.getDescription()
    }
    
    func getCost() -> Double {
        return decoratedCoffee.getCost()
    }
}

class MilkDecorator: CoffeeDecorator {
    override func getDescription() -> String {
        return super.getDescription() + ", Milk"
    }
    
    override func getCost() -> Double {
        return super.getCost() + 0.5
    }
}

class SugarDecorator: CoffeeDecorator {
    override func getDescription() -> String {
        return super.getDescription() + ", Sugar"
    }
    
    override func getCost() -> Double {
        return super.getCost() + 0.25
    }
}

class CaramelDecorator: CoffeeDecorator {
    override func getDescription() -> String {
        return super.getDescription() + ", Caramel"
    }
    
    override func getCost() -> Double {
        return super.getCost() + 0.75
    }
}

// Using decorator pattern
var coffee: Coffee = SimpleCoffee()
print("☕ \(coffee.getDescription()): $\(coffee.getCost())")

coffee = MilkDecorator(coffee)
print("☕ \(coffee.getDescription()): $\(coffee.getCost())")

coffee = SugarDecorator(coffee)
print("☕ \(coffee.getDescription()): $\(coffee.getCost())")

coffee = CaramelDecorator(coffee)
print("☕ \(coffee.getDescription()): $\(coffee.getCost())")


// SECTION 7: Adapter Pattern
// ============================================================================

print("\n=== ADAPTER PATTERN ===\n")

// Legacy system
class LegacyAPI {
    func fetchDataLegacy() -> String {
        return "Legacy Data Format"
    }
}

// Modern interface
protocol ModernDataSource {
    func getData() -> [String: Any]
}

// Adapter
class LegacyAPIAdapter: ModernDataSource {
    private let legacyAPI: LegacyAPI
    
    init(legacyAPI: LegacyAPI) {
        self.legacyAPI = legacyAPI
    }
    
    func getData() -> [String: Any] {
        let legacyData = legacyAPI.fetchDataLegacy()
        return [
            "data": legacyData,
            "timestamp": Date().timeIntervalSince1970,
            "format": "modern"
        ]
    }
}

// Using adapter
let legacy = LegacyAPI()
let adapter = LegacyAPIAdapter(legacyAPI: legacy)
let modernData = adapter.getData()
print("Adapted data: \(modernData)")


// SECTION 8: Repository Pattern (Data Layer)
// ============================================================================

print("\n=== REPOSITORY PATTERN ===\n")

protocol UserRepository {
    func getUser(id: Int) -> User?
    func saveUser(_ user: User)
    func deleteUser(id: Int)
}

class UserRepositoryImpl: UserRepository {
    private var users: [Int: User] = [:]
    
    func getUser(id: Int) -> User? {
        print("Fetching user \(id)")
        return users[id]
    }
    
    func saveUser(_ user: User) {
        print("Saving user: \(user.name)")
        // Simulate storage with hash based on email
        let id = user.email.hashValue
        users[id] = user
    }
    
    func deleteUser(id: Int) {
        print("Deleting user \(id)")
        users.removeValue(forKey: id)
    }
}

// Using repository
let userRepo = UserRepositoryImpl()
let newUser = User.Builder(name: "Alice", email: "alice@example.com")
    .withAge(25)
    .build()

userRepo.saveUser(newUser)


// SECTION 9: Common Mistakes (Anti-patterns)
// ============================================================================

print("\n=== COMMON MISTAKES ===\n")

// ❌ MISTAKE 1: God Object (doing too much)
print("❌ MISTAKE 1: God Object")
class GodObjectBad {
    // Handles everything - networking, storage, UI, business logic
    func fetchData() {}
    func saveData() {}
    func updateUI() {}
    func validateInput() {}
    func sendAnalytics() {}
}

// ✅ FIX: Separate concerns
class NetwokringService {
    func fetchData() {}
}

class StorageService {
    func saveData() {}
}

print("(Separation of concerns applied)")

// ❌ MISTAKE 2: Rigid factory (hard to extend)
print("\n❌ MISTAKE 2: Rigid factory")
class BadFactory {
    static func create(type: String) -> DataSource? {
        switch type {
        case "api": return APIDataSource()
        case "local": return LocalDataSource()
        default: return nil
        }
        // Adding new type requires modifying this class!
    }
}

// ✅ FIX: Protocol-based factory (extensible)
print("(Extensible factory pattern shown earlier)")

// ❌ MISTAKE 3: Over-engineering with patterns
print("\n❌ MISTAKE 3: Over-engineering")
print("Not every situation needs a design pattern!")
print("Simple solutions are often better")


// SECTION 10: Best Practices
// ============================================================================

print("\n=== BEST PRACTICES ===\n")

// ✅ PRACTICE 1: Use patterns when they solve real problems
print("✅ PRACTICE 1: Pattern motivation")
print("- Singleton: Shared resources (logging, config)")
print("- Factory: Complex object creation")
print("- Strategy: Interchangeable algorithms")
print("- Observer: Decoupled state management")

// ✅ PRACTICE 2: Combine patterns appropriately
print("\n✅ PRACTICE 2: Pattern combination")
class AppService {
    static let shared = AppService()  // Singleton
    private let repository: UserRepository  // Repository pattern
    
    private init() {
        repository = UserRepositoryImpl()
    }
    
    func getUserData(id: Int) -> User? {
        return repository.getUser(id: id)
    }
}

// ✅ PRACTICE 3: Document pattern usage
print("\n✅ PRACTICE 3: Clear pattern documentation")
/// Factory for creating appropriate data sources
/// Uses Factory pattern for decoupled object creation
class DataSourceFactory2 {
    /// Creates a data source based on environment
    static func createForEnvironment() -> DataSource {
        #if DEBUG
        return LocalDataSource()
        #else
        return APIDataSource()
        #endif
    }
}

// ✅ PRACTICE 4: Test with patterns
print("\n✅ PRACTICE 4: Patterns enable testing")
protocol Logger {
    func log(_ message: String)
}

class ConsoleLogger: Logger {
    func log(_ message: String) {
        print("[LOG] \(message)")
    }
}

class MockLogger: Logger {
    var lastMessage: String?
    func log(_ message: String) {
        lastMessage = message
    }
}

class ServiceWithLogger {
    let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func doWork() {
        logger.log("Work started")
    }
}

let mockLogger = MockLogger()
let service = ServiceWithLogger(logger: mockLogger)
service.doWork()
print("Mock captured: \(mockLogger.lastMessage ?? "none")")


print("\n=== END OF DESIGN PATTERNS PLAYGROUND ===")
