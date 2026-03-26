# Classes and Structures

## Overview

Classes and structures are fundamental building blocks in Swift. Understanding when to use each, and how they differ in memory management and behavior, is crucial for writing efficient and correct Swift code.

## Main Topics

- [Structures Basics](#structures-basics)
- [Classes Basics](#classes-basics)
- [Key Differences](#key-differences)
- [Choosing Between Class and Struct](#choosing-between-class-and-struct)
- [Initialization](#initialization)
- [Methods and Properties](#methods-and-properties)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Structures and Classes](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/classesandstructures)
- [WWDC: Modernizing Grand Central Dispatch](https://developer.apple.com/videos/play/wwdc2017/702/)

---

## Structures Basics

### Defining Structures

```swift
// Basic struct
struct Point {
    var x: Int
    var y: Int
}

// Creating instances
var origin = Point(x: 0, y: 0)
var firstPoint = Point(x: 10, y: 20)

// Accessing properties
print(origin.x)  // 0
print(firstPoint.y)  // 20

// Modifying properties
origin.x = 5
origin.y = 10
```

### Structs with Methods

```swift
struct Rectangle {
    var width: Int
    var height: Int
    
    // Computed property
    var area: Int {
        return width * height
    }
    
    var perimeter: Int {
        return 2 * (width + height)
    }
    
    // Regular method
    func description() -> String {
        return "\(width)x\(height)"
    }
    
    // Mutating method
    mutating func scaleBy(factor: Int) {
        width *= factor
        height *= factor
    }
}

var rect = Rectangle(width: 10, height: 20)
print(rect.area)              // 200
print(rect.perimeter)         // 60
print(rect.description())     // "10x20"

rect.scaleBy(factor: 2)
print(rect.area)              // 800 (now 20x40)
```

### Struct Types as Value Types

```swift
// Structs are value types - they're copied
struct Color {
    var red: Int
    var green: Int
    var blue: Int
}

var color1 = Color(red: 255, green: 0, blue: 0)
var color2 = color1           // color1 is copied to color2

color2.green = 255            // Modifying color2
print(color1.green)           // 0 (color1 unchanged - they're separate)
print(color2.green)           // 255

// Function parameters are copies
func modifyColor(_ color: inout Color) {
    color.blue = 255
}

var myColor = Color(red: 100, green: 100, blue: 100)
modifyColor(&myColor)
print(myColor.blue)           // 255 (modified)
```

---

## Classes Basics

### Defining Classes

```swift
// Basic class
class Animal {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    func makeSound() {
        print("Generic animal sound")
    }
}

// Creating instances
let dog = Animal(name: "Buddy", age: 5)
let cat = Animal(name: "Whiskers", age: 3)

// Accessing properties
print(dog.name)   // "Buddy"
print(cat.age)    // 3

// Modifying properties
dog.name = "Max"  // Works even if dog is constant
```

### Class Inheritance

```swift
// Parent class
class Animal {
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func makeSound() {
        print("Generic sound")
    }
}

// Child class
class Dog: Animal {
    var breed: String
    
    init(name: String, breed: String) {
        self.breed = breed
        super.init(name: name)
    }
    
    override func makeSound() {
        print("Woof!")
    }
    
    func fetch() {
        print("\(name) fetches the ball")
    }
}

// Using inheritance
let myDog = Dog(name: "Buddy", breed: "Golden Retriever")
myDog.makeSound()             // "Woof!"
myDog.fetch()                 // "Buddy fetches the ball"
```

### Class Types as Reference Types

```swift
// Classes are reference types - they share references
class Person {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

let person1 = Person(name: "Alice")
let person2 = person1         // person2 references same object as person1

person2.name = "Bob"
print(person1.name)           // "Bob" (person1 changed too - same reference)
print(person2.name)           // "Bob"

// Comparing identity
if person1 === person2 {
    print("Same object")      // This prints - same reference
}

if person1 == person2 {
    print("Equal")            // Doesn't print - == not implemented
}
```

---

## Key Differences

| Feature | Struct | Class |
|---------|--------|-------|
| Type | Value type | Reference type |
| Copy | Copied when assigned | Shared reference |
| Memory | Stack | Heap |
| Inheritance | No | Yes |
| Deinit | No | Yes |
| Mutability | Need `mutating` | Can modify with `let` |
| Identity (`===`) | No | Yes |

```swift
// Value type behavior - struct
struct StructValue {
    var number = 0
}

func modifyStruct(_ value: StructValue) {
    var mutableValue = value
    mutableValue.number = 100
    print(mutableValue.number)  // 100
}

var s = StructValue()
modifyStruct(s)
print(s.number)  // 0 (unchanged - copy was modified)

// Reference type behavior - class
class ClassValue {
    var number = 0
}

func modifyClass(_ value: ClassValue) {
    value.number = 100
    print(value.number)  // 100
}

var c = ClassValue()
modifyClass(c)
print(c.number)  // 100 (changed - shared reference was modified)
```

---

## Choosing Between Class and Struct

### Use Struct When:
- Representing simple data types
- No need for inheritance
- No reference semantics needed
- Lightweight objects

```swift
struct Address {
    var street: String
    var city: String
    var zipCode: String
}

struct Person {
    var name: String
    var age: Int
    var address: Address
}
```

### Use Class When:
- Need inheritance hierarchy
- Object identity matters
- Sharing state between references
- Resource management (deinit needed)

```swift
class UIViewController {
    var title: String?
    var view: UIView?
    
    func viewDidLoad() {
        // Initialization logic
    }
    
    deinit {
        // Cleanup
    }
}
```

---

## Initialization

### Struct Initialization

```swift
struct Size {
    var width: Int
    var height: Int
}

// Automatic memberwise initializer
let defaultSize = Size(width: 100, height: 200)

// Custom initializer
extension Size {
    init(square side: Int) {
        self.width = side
        self.height = side
    }
}

let square = Size(square: 50)
```

### Class Initialization

```swift
class Person {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    // Convenience initializer
    convenience init(name: String) {
        self.init(name: name, age: 0)
    }
}

let person1 = Person(name: "Alice", age: 30)
let person2 = Person(name: "Bob")  // age defaults to 0
```

---

## Methods and Properties

### Stored vs Computed Properties

```swift
class Circle {
    // Stored property
    var radius: Double
    
    // Computed property
    var diameter: Double {
        get {
            return radius * 2
        }
        set {
            radius = newValue / 2
        }
    }
    
    var area: Double {
        return Double.pi * radius * radius
    }
    
    init(radius: Double) {
        self.radius = radius
    }
}

var circle = Circle(radius: 5)
print(circle.diameter)   // 10 (computed)
circle.diameter = 20
print(circle.radius)     // 10 (modified through computed property)
```

### Property Observers

```swift
class Temperature {
    var celcius: Double {
        didSet {
            print("Temperature changed to \(celcius)°C")
        }
        willSet {
            print("Temperature will change from \(celcius)°C to \(newValue)°C")
        }
    }
    
    init(_ value: Double) {
        self.celcius = value
    }
}

var temp = Temperature(20)
temp.celcius = 25  // Prints both messages
```

---

## 🎯 Best Practices

### 1. Default to Structs
- Prefer structs unless you need class features
- Simpler, safer, better for value semantics

### 2. Use Mutating for State Changes
- Mark methods that change struct state as `mutating`
- Makes intent clear

### 3. Implement Value Semantics
- If using classes, be explicit about reference vs value behavior
- Consider copy methods for value semantics

### 4. Avoid Deep Inheritance Hierarchies
- Limit to 2-3 levels when possible
- Prefer composition to inheritance

### 5. Use Proper Initialization
- Provide convenient initializers
- Document initialization requirements

---

## ❌ Common Mistakes

### Mistake 1: Classes Instead of Structs

**WRONG:**
```swift
class Point {
    var x: Double
    var y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}
```

**CORRECT:**
```swift
struct Point {
    var x: Double
    var y: Double
}  // Simpler, faster, safer
```

---

### Mistake 2: Forgetting Mutating

**WRONG:**
```swift
struct Counter {
    var count = 0
    
    func increment() {  // ❌ Error - cannot modify
        count += 1
    }
}
```

**CORRECT:**
```swift
struct Counter {
    var count = 0
    
    mutating func increment() {  // ✅ Correct
        count += 1
    }
}
```

---

### Mistake 3: Overusing Inheritance

**WRONG:**
```swift
class Animal { }
class Mammal: Animal { }
class Canine: Mammal { }
class Dog: Canine { }
```

**CORRECT:**
```swift
protocol Animal { }
struct Dog: Animal { }  // Composition over inheritance
```

---

## Related Topics

- [Protocols](protocols.md)
- [Memory Management](memory-management.md)
- [Extensions](extensions.md)

---

**Understand when to use structs vs classes for better architecture!**
