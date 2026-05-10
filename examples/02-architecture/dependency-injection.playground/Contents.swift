import Foundation

// ============================================================================
// DEPENDENCY INJECTION IN SWIFT - Complete Playground Guide
// Corresponds to: 02-architecture/dependency-injection-and-advanced-patterns/dependency-injection.md
// ============================================================================

// SECTION 1: The Problem - Tight Coupling
// ============================================================================

print("=== TIGHT COUPLING PROBLEM ===\n")

// ❌ WRONG: Direct dependency (tight coupling)
print("❌ WRONG: Tightly coupled")
class APIServiceBad {
    func fetchUser() -> String {
        return "User from API"
    }
}

class UserManagerBad {
    private let api = APIServiceBad()  // ⚠️ Hard-coded dependency
    
    func getUser() -> String {
        return api.fetchUser()
    }
}

// Problems with this approach:
// - Can't test UserManagerBad without real API calls
// - Can't swap API with mock/local implementation
// - Difficult to maintain and extend

let userManagerBad = UserManagerBad()
print("Result: \(userManagerBad.getUser())")


// SECTION 2: Constructor Injection (Recommended)
// ============================================================================

print("\n=== CONSTRUCTOR INJECTION (RECOMMENDED) ===\n")

// Define protocol for dependency
protocol UserDataProvider {
    func fetchUser() -> String
}

// Real implementation
class APIDataProvider: UserDataProvider {
    func fetchUser() -> String {
        return "User from API"
    }
}

// Mock implementation for testing
class MockDataProvider: UserDataProvider {
    func fetchUser() -> String {
        return "Mock User"
    }
}

// ✅ CORRECT: Inject dependency via constructor
class UserManager {
    private let dataProvider: UserDataProvider
    
    // Dependency is injected here
    init(dataProvider: UserDataProvider) {
        self.dataProvider = dataProvider
    }
    
    func getUser() -> String {
        return dataProvider.fetchUser()
    }
}

// Using with real implementation
let apiProvider = APIDataProvider()
let userManager = UserManager(dataProvider: apiProvider)
print("With API: \(userManager.getUser())")

// Using with mock implementation (for testing)
let mockProvider = MockDataProvider()
let userManagerForTesting = UserManager(dataProvider: mockProvider)
print("With Mock: \(userManagerForTesting.getUser())")


// SECTION 3: Property Injection
// ============================================================================

print("\n=== PROPERTY INJECTION ===\n")

protocol Logger {
    func log(_ message: String)
}

class ConsoleLogger: Logger {
    func log(_ message: String) {
        print("[LOG] \(message)")
    }
}

// ✅ Property injection - injectable after initialization
class UserService {
    var logger: Logger?
    
    func createUser(name: String) {
        logger?.log("Creating user: \(name)")
        print("User created")
    }
}

let service = UserService()
service.logger = ConsoleLogger()
service.createUser(name: "John")

// ⚠️ Property injection can lead to optional properties
// Only use when truly optional


// SECTION 4: Method Injection
// ============================================================================

print("\n=== METHOD INJECTION ===\n")

protocol NotificationService {
    func sendNotification(_ message: String)
}

class EmailNotificationService: NotificationService {
    func sendNotification(_ message: String) {
        print("📧 Email: \(message)")
    }
}

class PushNotificationService: NotificationService {
    func sendNotification(_ message: String) {
        print("🔔 Push: \(message)")
    }
}

// ✅ Method injection - dependency passed to method
class OrderService {
    func processOrder(orderId: String, with notificationService: NotificationService) {
        print("Processing order \(orderId)")
        notificationService.sendNotification("Order \(orderId) processed")
    }
}

let orderService = OrderService()
orderService.processOrder(orderId: "123", with: EmailNotificationService())
orderService.processOrder(orderId: "456", with: PushNotificationService())


// SECTION 5: Service Locator (Not Recommended)
// ============================================================================

print("\n=== SERVICE LOCATOR (ANTI-PATTERN) ===\n")

// ⚠️ Service locator pattern (hidden dependencies)
class ServiceLocator {
    static let shared = ServiceLocator()
    
    private var services: [String: Any] = [:]
    
    func register<T>(_ service: T, forKey key: String) {
        services[key] = service
    }
    
    func resolve<T>(forKey key: String) -> T? {
        return services[key] as? T
    }
}

// ❌ Using service locator (hidden dependencies)
print("❌ SERVICE LOCATOR (Hidden dependencies)")
class UserViewControllerBad {
    func loadUser() {
        guard let provider: UserDataProvider = ServiceLocator.shared.resolve(forKey: "userProvider") else {
            return
        }
        // ⚠️ Dependency is hidden - not clear from method signature
        let userData = provider.fetchUser()
        print("Loaded: \(userData)")
    }
}

ServiceLocator.shared.register(APIDataProvider(), forKey: "userProvider")
let vc = UserViewControllerBad()
vc.loadUser()

print("\n⚠️ Why service locator is problematic:")
print("- Hidden dependencies (not clear what's required)")
print("- Hard to test (need to set up service locator)")
print("- Difficult to track dependencies at compile time")


// SECTION 6: Dependency Container (Inversion of Control)
// ============================================================================

print("\n=== DEPENDENCY CONTAINER (IOC) ===\n")

// ✅ Simple IOC container
class DIContainer {
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        if let existing = singletons[key] {
            return  // Already registered
        }
        let instance = factory()
        singletons[key] = instance
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // Check singleton first
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Otherwise create new instance
        if let factory = factories[key] as? () -> T {
            return factory()
        }
        
        return nil
    }
}

// Using IOC container
let container = DIContainer()

// Register dependencies
container.registerSingleton(APIDataProvider.self) {
    APIDataProvider()
}

container.register(UserManager.self) {
    let provider = container.resolve(APIDataProvider.self)!
    return UserManager(dataProvider: provider)
}

// Resolve dependencies
if let manager = container.resolve(UserManager.self) {
    print("From container: \(manager.getUser())")
}


// SECTION 7: Factory Pattern with Injection
// ============================================================================

print("\n=== FACTORY WITH DEPENDENCY INJECTION ===\n")

protocol Repository {
    func fetchData() -> String
}

class DatabaseRepository: Repository {
    func fetchData() -> String {
        return "Data from Database"
    }
}

class CacheRepository: Repository {
    func fetchData() -> String {
        return "Data from Cache"
    }
}

// ✅ Factory that uses DI
class RepositoryFactory {
    func createRepository(type: String) -> Repository {
        switch type {
        case "database":
            return DatabaseRepository()
        case "cache":
            return CacheRepository()
        default:
            return DatabaseRepository()
        }
    }
}

class DataManager {
    private let repository: Repository
    
    init(factory: RepositoryFactory, type: String) {
        self.repository = factory.createRepository(type: type)
    }
    
    func getData() -> String {
        return repository.fetchData()
    }
}

let factory = RepositoryFactory()
let manager1 = DataManager(factory: factory, type: "database")
print("Manager 1: \(manager1.getData())")

let manager2 = DataManager(factory: factory, type: "cache")
print("Manager 2: \(manager2.getData())")


// SECTION 8: Common Mistakes (Anti-patterns)
// ============================================================================

print("\n=== COMMON MISTAKES ===\n")

// ❌ MISTAKE 1: Mixing constructor and property injection
print("❌ MISTAKE 1: Inconsistent injection")
class InconsistentService {
    let requiredProvider: UserDataProvider
    var optionalLogger: Logger?  // ⚠️ Mixing patterns
    
    init(provider: UserDataProvider) {
        self.requiredProvider = provider
    }
}
print("(Inconsistent approach makes code harder to follow)")

// ✅ FIX: Choose one injection method and stick with it
print("✅ FIX: Consistent injection strategy")

// ❌ MISTAKE 2: Circular dependencies
print("\n❌ MISTAKE 2: Circular dependencies")
class ServiceA {
    let serviceB: ServiceB?
    
    init(serviceB: ServiceB?) {
        self.serviceB = serviceB
    }
}

class ServiceB {
    let serviceA: ServiceA?
    
    init(serviceA: ServiceA?) {
        self.serviceA = serviceA
    }
    // ⚠️ Circular reference!
}

print("(Avoid circular dependencies - refactor to break cycle)")

// ✅ FIX: Use protocol separation
class ServiceAFixed {
    let dependency: SomeDependency
    
    init(dependency: SomeDependency) {
        self.dependency = dependency
    }
}

protocol SomeDependency {}

// ❌ MISTAKE 3: Over-injecting (too many dependencies)
print("\n❌ MISTAKE 3: Constructor with too many parameters")
class OverLoaded {
    init(dep1: String, dep2: String, dep3: String, 
         dep4: String, dep5: String, dep6: String) {
        // ⚠️ Too many dependencies!
    }
}

// ✅ FIX: Use a configuration object or facade
print("✅ FIX: Group related dependencies")
class Configuration {
    let databases: [String]
    let services: [String]
    let settings: [String]
}

class ProperService {
    init(config: Configuration) {
        // Single, organized dependency
    }
}


// SECTION 9: Best Practices
// ============================================================================

print("\n=== BEST PRACTICES ===\n")

// ✅ PRACTICE 1: Depend on abstractions (protocols)
print("✅ PRACTICE 1: Depend on protocols, not concrete types")
protocol DataFetcher {
    func fetch() -> String
}

class APIFetcher: DataFetcher {
    func fetch() -> String { "API Data" }
}

class GoodPresenter {
    private let fetcher: DataFetcher  // Not APIFetcher
    
    init(fetcher: DataFetcher) {
        self.fetcher = fetcher
    }
}

// ✅ PRACTICE 2: Use constructor injection by default
print("\n✅ PRACTICE 2: Default to constructor injection")
class BestPracticeService {
    let logger: Logger
    let repository: Repository
    
    init(logger: Logger, repository: Repository) {
        self.logger = logger
        self.repository = repository
    }
}

// ✅ PRACTICE 3: Use lazy loading for expensive dependencies
print("\n✅ PRACTICE 3: Lazy initialization")
class LazyService {
    private let factory: () -> ExpensiveResource
    private lazy var resource = factory()
    
    init(factory: @escaping () -> ExpensiveResource) {
        self.factory = factory
    }
    
    func use() {
        // resource is created only when first accessed
    }
}

class ExpensiveResource {}

// ✅ PRACTICE 4: Document dependencies clearly
print("\n✅ PRACTICE 4: Clear dependency documentation")
/// Service that manages user data
/// - Parameters:
///   - provider: Provides user data (can be mocked for testing)
///   - logger: Logs operations (optional, defaults to console)
class DocumentedService {
    let provider: UserDataProvider
    let logger: Logger
    
    init(provider: UserDataProvider, logger: Logger = ConsoleLogger()) {
        self.provider = provider
        self.logger = logger
    }
}

// ✅ PRACTICE 5: Test with fake implementations
print("\n✅ PRACTICE 5: Easy testing with fakes")
class FakeDataProvider: UserDataProvider {
    let testData: String
    
    init(testData: String) {
        self.testData = testData
    }
    
    func fetchUser() -> String {
        return testData
    }
}

let testManager = UserManager(dataProvider: FakeDataProvider(testData: "Test User"))
print("Test result: \(testManager.getUser())")


print("\n=== END OF DEPENDENCY INJECTION PLAYGROUND ===")
