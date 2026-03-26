# Design Patterns in Swift

## Overview

Design patterns are proven solutions to common problems in software design. Understanding and applying patterns improves code organization, reusability, and maintainability.

## Main Topics

- [Creational Patterns](#creational-patterns)
- [Structural Patterns](#structural-patterns)
- [Behavioral Patterns](#behavioral-patterns)
- [Patterns Comparison](#patterns-comparison)
- [When to Use Each](#when-to-use-each)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Design Patterns: Elements of Reusable Object-Oriented Software](https://en.wikipedia.org/wiki/Design_Patterns)

---

## Creational Patterns

### Singleton

```swift
// Single instance throughout app lifecycle
class UserDefaults {
    static let standard = UserDefaults()
    
    private init() { }
    
    var lastLogin: Date?
}

// Usage
UserDefaults.standard.lastLogin = Date()

// Problem: Hard to test, global state
// Solution: Use dependency injection instead
```

### Factory

```swift
// Creates objects without specifying exact classes
protocol Shape {
    func draw()
}

class Circle: Shape {
    func draw() { print("Drawing circle") }
}

class Square: Shape {
    func draw() { print("Drawing square") }
}

class ShapeFactory {
    static func createShape(_ type: String) -> Shape {
        switch type {
        case "circle":
            return Circle()
        case "square":
            return Square()
        default:
            fatalError("Unknown shape")
        }
    }
}

// Usage
let circle = ShapeFactory.createShape("circle")
circle.draw()
```

### Builder

```swift
// Construct complex objects step by step
class URLBuilder {
    var scheme = "https"
    var host = ""
    var path = ""
    var queryItems: [String: String] = [:]
    
    func withScheme(_ scheme: String) -> URLBuilder {
        self.scheme = scheme
        return self
    }
    
    func withHost(_ host: String) -> URLBuilder {
        self.host = host
        return self
    }
    
    func withPath(_ path: String) -> URLBuilder {
        self.path = path
        return self
    }
    
    func addQueryItem(_ key: String, _ value: String) -> URLBuilder {
        queryItems[key] = value
        return self
    }
    
    func build() -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = queryItems.map { URLQueryItem(name: $0, value: $1) }
        return components.url!
    }
}

// Usage with fluent interface
let url = URLBuilder()
    .withScheme("https")
    .withHost("api.example.com")
    .withPath("/users")
    .addQueryItem("page", "1")
    .build()
```

### Prototype

```swift
// Clone existing objects
protocol Cloneable {
    func clone() -> Self
}

class User: Cloneable {
    var name: String
    var email: String
    
    init(name: String, email: String) {
        self.name = name
        self.email = email
    }
    
    func clone() -> User {
        return User(name: self.name, email: self.email)
    }
}

// Usage
let original = User(name: "John", email: "john@example.com")
let clone = original.clone()
clone.name = "John Copy"
```

---

## Structural Patterns

### Adapter

```swift
// Convert interface of one class to another
protocol NewPaymentProcessor {
    func processPayment(amount: Double)
}

// Old-style processor
class LegacyPaymentProcessor {
    func makePayment(cents: Int) {
        print("Processing \(cents) cents")
    }
}

// Adapter
class PaymentAdapter: NewPaymentProcessor {
    let legacyProcessor = LegacyPaymentProcessor()
    
    func processPayment(amount: Double) {
        let cents = Int(amount * 100)
        legacyProcessor.makePayment(cents: cents)
    }
}

// Usage
let processor: NewPaymentProcessor = PaymentAdapter()
processor.processPayment(amount: 99.99)
```

### Decorator

```swift
// Add behavior to objects dynamically
protocol Coffee {
    func cost() -> Double
    func description() -> String
}

class SimpleCoffee: Coffee {
    func cost() -> Double { 2.0 }
    func description() -> String { "Coffee" }
}

class CoffeeDecorator: Coffee {
    let coffee: Coffee
    
    init(_ coffee: Coffee) {
        self.coffee = coffee
    }
    
    func cost() -> Double { coffee.cost() }
    func description() -> String { coffee.description() }
}

class MilkDecorator: CoffeeDecorator {
    override func cost() -> Double {
        return coffee.cost() + 0.5
    }
    
    override func description() -> String {
        return coffee.description() + " with milk"
    }
}

class SugarDecorator: CoffeeDecorator {
    override func cost() -> Double {
        return coffee.cost() + 0.2
    }
    
    override func description() -> String {
        return coffee.description() + " with sugar"
    }
}

// Usage with stacking
var coffee: Coffee = SimpleCoffee()
coffee = MilkDecorator(coffee)
coffee = SugarDecorator(coffee)
print(coffee.description())  // "Coffee with milk with sugar"
print(coffee.cost())          // 2.7
```

### Facade

```swift
// Provide unified interface to subsystem
// Complex subsystem
class PaymentGateway {
    func authorizeCard(_ card: String) -> Bool { true }
    func createTransaction(_ amount: Double) -> String { UUID().uuidString }
    func captureTransaction(_ id: String) -> Bool { true }
}

class FraudDetection {
    func checkFraud(_ amount: Double) -> Bool { false }
}

class Accounting {
    func recordTransaction(_ id: String, _ amount: Double) {
        print("Recorded: $\(amount)")
    }
}

// Facade
class PaymentProcessor {
    let gateway = PaymentGateway()
    let fraud = FraudDetection()
    let accounting = Accounting()
    
    func processPayment(card: String, amount: Double) -> Bool {
        guard !fraud.checkFraud(amount) else { return false }
        guard gateway.authorizeCard(card) else { return false }
        
        let transactionID = gateway.createTransaction(amount)
        guard gateway.captureTransaction(transactionID) else { return false }
        
        accounting.recordTransaction(transactionID, amount)
        return true
    }
}

// Usage - simple interface
let processor = PaymentProcessor()
processor.processPayment(card: "4111111111111111", amount: 99.99)
```

### Proxy

```swift
// Control access to another object
protocol DataService {
    func fetch(id: Int) -> String
}

class RealDataService: DataService {
    func fetch(id: Int) -> String {
        print("Fetching from database...")
        return "Data for \(id)"
    }
}

class CachedDataService: DataService {
    let realService = RealDataService()
    var cache: [Int: String] = [:]
    
    func fetch(id: Int) -> String {
        if let cached = cache[id] {
            print("Returning cached data")
            return cached
        }
        
        let data = realService.fetch(id: id)
        cache[id] = data
        return data
    }
}

// Usage
let service: DataService = CachedDataService()
print(service.fetch(id: 1))  // Fetches
print(service.fetch(id: 1))  // Cached
```

---

## Behavioral Patterns

### Observer

```swift
// Notify multiple objects about state changes
protocol Observer: AnyObject {
    func update(_ notification: String)
}

class Subject {
    private var observers: [Observer] = []
    
    func attach(_ observer: Observer) {
        observers.append(observer)
    }
    
    func notifyObservers(_ message: String) {
        observers.forEach { $0.update(message) }
    }
}

class ConcreteObserver: Observer {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    func update(_ notification: String) {
        print("\(name) received: \(notification)")
    }
}

// Usage
let subject = Subject()
subject.attach(ConcreteObserver(name: "Observer1"))
subject.attach(ConcreteObserver(name: "Observer2"))
subject.notifyObservers("State changed!")
```

### Strategy

```swift
// Encapsulate interchangeable algorithms
protocol PaymentStrategy {
    func pay(amount: Double)
}

class CreditCardPayment: PaymentStrategy {
    let cardNumber: String
    
    init(cardNumber: String) {
        self.cardNumber = cardNumber
    }
    
    func pay(amount: Double) {
        print("Paying $\(amount) with card \(cardNumber)")
    }
}

class PayPalPayment: PaymentStrategy {
    let email: String
    
    init(email: String) {
        self.email = email
    }
    
    func pay(amount: Double) {
        print("Paying $\(amount) via PayPal (\(email))")
    }
}

class ShoppingCart {
    var items: [Double] = []
    private var paymentStrategy: PaymentStrategy?
    
    func setPaymentStrategy(_ strategy: PaymentStrategy) {
        self.paymentStrategy = strategy
    }
    
    func checkout() {
        let total = items.reduce(0, +)
        paymentStrategy?.pay(amount: total)
    }
}

// Usage
let cart = ShoppingCart()
cart.items = [10.0, 20.0, 30.0]

cart.setPaymentStrategy(CreditCardPayment(cardNumber: "4111"))
cart.checkout()

cart.setPaymentStrategy(PayPalPayment(email: "user@example.com"))
cart.checkout()
```

### State

```swift
// Allow object to change behavior based on state
protocol TrafficLightState {
    func next() -> TrafficLightState
    func description() -> String
}

class RedLight: TrafficLightState {
    func next() -> TrafficLightState { GreenLight() }
    func description() -> String { "🔴 Red" }
}

class GreenLight: TrafficLightState {
    func next() -> TrafficLightState { YellowLight() }
    func description() -> String { "🟢 Green" }
}

class YellowLight: TrafficLightState {
    func next() -> TrafficLightState { RedLight() }
    func description() -> String { "🟡 Yellow" }
}

class TrafficLight {
    var state: TrafficLightState = RedLight()
    
    func change() {
        state = state.next()
        print(state.description())
    }
}

// Usage
let light = TrafficLight()
light.change()  // Green
light.change()  // Yellow
light.change()  // Red
```

### Command

```swift
// Encapsulate requests as objects
protocol Command {
    func execute()
    func undo()
}

class Light {
    var isOn = false
    
    func turnOn() {
        isOn = true
        print("Light on")
    }
    
    func turnOff() {
        isOn = false
        print("Light off")
    }
}

class LightOnCommand: Command {
    let light: Light
    
    init(_ light: Light) {
        self.light = light
    }
    
    func execute() { light.turnOn() }
    func undo() { light.turnOff() }
}

class LightOffCommand: Command {
    let light: Light
    
    init(_ light: Light) {
        self.light = light
    }
    
    func execute() { light.turnOff() }
    func undo() { light.turnOn() }
}

class RemoteControl {
    var commands: [Command] = []
    
    func pressButton(_ command: Command) {
        command.execute()
        commands.append(command)
    }
    
    func pressUndo() {
        commands.popLast()?.undo()
    }
}

// Usage
let light = Light()
let remote = RemoteControl()
remote.pressButton(LightOnCommand(light))
remote.pressButton(LightOffCommand(light))
remote.pressUndo()  // Turn on again
```

---

## 🎯 Best Practices

### 1. Know the Problem Before Pattern
```swift
// ✅ Apply pattern to solve real problem
// ❌ Apply pattern just because it's a pattern
```

### 2. Start Simple
```swift
// ✅ Begin without pattern
// ❌ Over-engineer from start
```

### 3. Use Swift Features
```swift
// ✅ Leverage Swift's protocol-oriented design
// ❌ Force traditional OOP patterns
```

---

## ❌ Common Mistakes

### Mistake 1: Wrong Pattern for Problem

**WRONG:**
```swift
// ❌ Using Singleton for testability
class Database {
    static let shared = Database()
}
```

**CORRECT:**
```swift
// ✅ Inject dependency
class UserViewModel {
    let database: Database
    init(database: Database) {
        self.database = database
    }
}
```

---

### Mistake 2: Over-patterning

**WRONG:**
```swift
// ❌ Too many patterns for simple code
// Factory, Builder, Adapter, Decorator all mixed
```

**CORRECT:**
```swift
// ✅ Simple and clear
let user = User(name: "John")
```

---

## Related Topics

- [VIPER](viper.md)
- [MVC](mvc.md)
- [Dependency Injection](dependency-injection.md)

---

**Use patterns wisely to solve real problems!**
