import Foundation

// ============================================================================
// PROTOCOLS IN SWIFT - Complete Playground Guide
// Corresponds to: 01-fundamentals/object-oriented-programming/protocols.md
// ============================================================================

// SECTION 1: Protocol Basics
// ============================================================================

print("=== PROTOCOL BASICS ===\n")

// ✅ Define a protocol
protocol Vehicle {
    var brand: String { get }
    var maxSpeed: Int { get set }
    
    func start()
    func stop()
    func accelerate() -> String
}

// ✅ Conform to protocol
class Car: Vehicle {
    let brand: String
    var maxSpeed: Int
    
    init(brand: String, maxSpeed: Int) {
        self.brand = brand
        self.maxSpeed = maxSpeed
    }
    
    func start() {
        print("🚗 \(brand) car is starting")
    }
    
    func stop() {
        print("🚗 \(brand) car is stopping")
    }
    
    func accelerate() -> String {
        return "🏎️ \(brand) accelerates to \(maxSpeed) km/h"
    }
}

// ✅ Use protocol
let myCar: Vehicle = Car(brand: "Tesla", maxSpeed: 250)
myCar.start()
print(myCar.accelerate())
print("Brand: \(myCar.brand), Max Speed: \(myCar.maxSpeed)")
myCar.stop()


// SECTION 2: Protocol Methods & Properties
// ============================================================================

print("\n=== PROTOCOL REQUIREMENTS ===\n")

protocol Drawable {
    var fillColor: String { get }
    var borderWidth: Double { get set }
    
    func draw()
    mutating func rotate(degrees: Int)
}

struct Circle: Drawable {
    let fillColor: String
    var borderWidth: Double
    let radius: Double
    
    func draw() {
        print("Drawing circle with color: \(fillColor)")
    }
    
    mutating func rotate(degrees: Int) {
        print("Circle rotated by \(degrees)° (no visual change)")
    }
}

var myCircle = Circle(fillColor: "Blue", borderWidth: 2.0, radius: 10)
myCircle.draw()
myCircle.rotate(degrees: 45)


// SECTION 3: Protocol Inheritance
// ============================================================================

print("\n=== PROTOCOL INHERITANCE ===\n")

// ✅ Protocol inheriting from another protocol
protocol Animal {
    func makeSound()
}

protocol Pet: Animal {
    var owner: String { get }
    func play()
}

class Dog: Pet {
    let owner: String
    let name: String
    
    init(name: String, owner: String) {
        self.name = name
        self.owner = owner
    }
    
    func makeSound() {
        print("🐕 \(name) barks: Woof!")
    }
    
    func play() {
        print("🐕 \(name) is playing fetch")
    }
}

let myDog = Dog(name: "Rex", owner: "John")
myDog.makeSound()
myDog.play()


// SECTION 4: Protocol Composition - WRONG vs CORRECT
// ============================================================================

print("\n=== PROTOCOL COMPOSITION ===\n")

protocol Runnable {
    func run()
}

protocol Jumpable {
    func jump()
}

// ✅ CORRECT: Implement multiple protocols
class Athlete: Runnable, Jumpable {
    func run() {
        print("🏃 Running at full speed")
    }
    
    func jump() {
        print("🦘 Jumping high")
    }
}

let athlete = Athlete()
athlete.run()
athlete.jump()

// ✅ Use protocol composition for type constraints
func exerciseAthlete(_ athlete: some Runnable & Jumpable) {
    athlete.run()
    athlete.jump()
}

exerciseAthlete(athlete)


// SECTION 5: Protocol with Default Implementations
// ============================================================================

print("\n=== PROTOCOL EXTENSIONS (DEFAULTS) ===\n")

protocol Nameable {
    var name: String { get }
    func introduce()
}

// ✅ Provide default implementation
extension Nameable {
    func introduce() {
        print("Hello, my name is \(name)")
    }
}

class Person: Nameable {
    let name: String
    init(name: String) {
        self.name = name
    }
    // introduce() is automatically available from extension
}

let person = Person(name: "Alice")
person.introduce()  // Uses default implementation


// SECTION 6: Associated Types
// ============================================================================

print("\n=== ASSOCIATED TYPES ===\n")

protocol Container {
    associatedtype Item
    mutating func add(_ item: Item)
    mutating func remove() -> Item?
    var count: Int { get }
}

// ✅ Implement protocol with associated type
class Stack<Element>: Container {
    private var items: [Element] = []
    
    mutating func add(_ item: Element) {
        items.append(item)
    }
    
    mutating func remove() -> Element? {
        return items.popLast()
    }
    
    var count: Int {
        items.count
    }
}

var stringStack = Stack<String>()
stringStack.add("First")
stringStack.add("Second")
stringStack.add("Third")
print("Stack count: \(stringStack.count)")
print("Removed: \(stringStack.remove() ?? "nothing")")

var intStack = Stack<Int>()
intStack.add(10)
intStack.add(20)


// SECTION 7: Generic Protocols
// ============================================================================

print("\n=== GENERIC PROTOCOLS ===\n")

protocol Comparable2 {
    func isGreater(than other: Self) -> Bool
}

struct Temperature: Comparable2 {
    let celsius: Double
    
    func isGreater(than other: Temperature) -> Bool {
        self.celsius > other.celsius
    }
}

let temp1 = Temperature(celsius: 25)
let temp2 = Temperature(celsius: 20)
print("25°C > 20°C: \(temp1.isGreater(than: temp2))")


// SECTION 8: Protocol Conformance - WRONG vs CORRECT
// ============================================================================

print("\n=== PROTOCOL CONFORMANCE ===\n")

protocol Logger {
    func log(_ message: String)
}

// ❌ WRONG: Protocol not explicitly conformed
class DebugPrinter {
    func log(_ message: String) {
        print("DEBUG: \(message)")
    }
}

// ✅ CORRECT: Explicit conformance
class ConsoleLogger: Logger {
    func log(_ message: String) {
        print("[LOG] \(message)")
    }
}

let logger: Logger = ConsoleLogger()
logger.log("Application started")

// ✅ CORRECT: Retroactive conformance with extension
extension String: Logger {
    func log(_ message: String) {
        print("String Logger: \(self) - \(message)")
    }
}

let loggerString: Logger = "CustomLog"
loggerString.log("Extended conformance")


// SECTION 9: Common Mistakes (Anti-patterns)
// ============================================================================

print("\n=== COMMON MISTAKES ===\n")

// ❌ MISTAKE 1: Not implementing required protocol methods
print("❌ MISTAKE 1: Missing protocol methods")
protocol Transportable {
    func transport()
}
// class BrokenCar: Transportable {  // ⚠️ Error: Missing transport()
//     // Incomplete
// }
print("(Compiler prevents this - shown as example)")

// ✅ FIX: Implement all required methods
class GoodCar: Transportable {
    func transport() {
        print("🚗 Transporting passengers")
    }
}

// ❌ MISTAKE 2: Confusing property requirements
print("\n❌ MISTAKE 2: Property getter/setter confusion")
protocol Configurable {
    var value: Int { get set }  // Requires both getter AND setter
}

// ✅ CORRECT: Match the requirement exactly
class Configuration: Configurable {
    var value: Int = 0
}

let config = Configuration()
config.value = 42
print("Configuration value: \(config.value)")

// ❌ MISTAKE 3: Over-complicating with unnecessary protocols
print("\n❌ MISTAKE 3: Protocol over-engineering")
// Don't create protocols for everything - use them when you need:
// - Multiple types with same behavior
// - Polymorphism
// - Dependency injection

// ✅ CORRECT: Use protocols judiciously
protocol DataRepository {
    func fetch<T>(id: Int) -> T?
    func save<T>(_ data: T)
}


// SECTION 10: Best Practices
// ============================================================================

print("\n=== BEST PRACTICES ===\n")

// ✅ PRACTICE 1: Keep protocols focused (Single Responsibility)
print("✅ PRACTICE 1: Single-purpose protocols")
protocol Saveable {
    func save()
}

protocol Loadable {
    func load()
}

class Document: Saveable, Loadable {
    func save() {
        print("📄 Document saved")
    }
    
    func load() {
        print("📄 Document loaded")
    }
}

// ✅ PRACTICE 2: Use protocol-oriented design
print("\n✅ PRACTICE 2: Protocol-oriented design")
protocol DataSource {
    func getData() -> [String]
}

class APIDataSource: DataSource {
    func getData() -> [String] {
        return ["API Data 1", "API Data 2"]
    }
}

class LocalDataSource: DataSource {
    func getData() -> [String] {
        return ["Local Data 1", "Local Data 2"]
    }
}

func displayData(_ source: DataSource) {
    for data in source.getData() {
        print("- \(data)")
    }
}

displayData(APIDataSource())
displayData(LocalDataSource())

// ✅ PRACTICE 3: Document protocol requirements
print("\n✅ PRACTICE 3: Well-documented protocol")
/// Represents an object that can be serialized
protocol Serializable {
    /// Converts object to JSON string
    /// - Returns: JSON representation of the object
    func toJSON() -> String
    
    /// Creates object from JSON string
    /// - Parameter json: JSON representation
    /// - Throws: DecodingError if JSON is invalid
    static func fromJSON(_ json: String) throws -> Self
}

// ✅ PRACTICE 4: Use associated types for flexibility
print("\n✅ PRACTICE 4: Associated types")
protocol Repository {
    associatedtype T
    func create(_ item: T)
    func read(id: Int) -> T?
}

class UserRepository: Repository {
    typealias T = String
    func create(_ item: String) {
        print("Creating user: \(item)")
    }
    func read(id: Int) -> String? {
        return "User-\(id)"
    }
}

let userRepo = UserRepository()
userRepo.create("John Doe")


print("\n=== END OF PROTOCOLS PLAYGROUND ===")
