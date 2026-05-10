import Foundation

// ============================================================================
// CLOSURES IN SWIFT - Complete Playground Guide
// Corresponds to: 01-fundamentals/functions-and-closures/closures.md
// ============================================================================

// SECTION 1: Closure Basics
// ============================================================================

print("=== CLOSURE BASICS ===\n")

// Simple closure stored in a variable
let greet: (String) -> String = { name in
    return "Hello, \(name)!"
}

print(greet("Swift Developer"))
// Output: Hello, Swift Developer!

// Closure without explicit return type annotation
let add: (Int, Int) -> Int = { a, b in
    a + b
}

print("5 + 3 = \(add(5, 3))")
// Output: 5 + 3 = 8

// Closure with no parameters and no return value
let printMessage: () -> Void = {
    print("This is a parameterless closure")
}
printMessage()


// SECTION 2: Trailing Closures & Shorthand
// ============================================================================

print("\n=== TRAILING CLOSURES ===\n")

// ✅ Function accepting a closure
func performCalculation(a: Int, b: Int, operation: (Int, Int) -> Int) -> Int {
    return operation(a, b)
}

// ❌ WRONG: Explicit closure syntax (verbose)
print("❌ WRONG: Explicit closure")
let result1 = performCalculation(a: 10, b: 5, operation: { (x, y) in
    return x * y
})

// ✅ CORRECT 1: Trailing closure
print("✅ CORRECT 1: Trailing closure")
let result2 = performCalculation(a: 10, b: 5) { x, y in
    x * y
}
print("Result: \(result2)")

// ✅ CORRECT 2: Shorthand arguments ($0, $1, etc.)
print("✅ CORRECT 2: Shorthand arguments")
let result3 = performCalculation(a: 10, b: 5) { $0 * $1 }
print("Result: \(result3)")

// ✅ CORRECT 3: Method reference (when applicable)
print("✅ CORRECT 3: Method reference")
let numbers = [1, 2, 3, 4, 5]
let doubled = numbers.map { $0 * 2 }
print("Doubled: \(doubled)")


// SECTION 3: Closures with Arrays
// ============================================================================

print("\n=== CLOSURES WITH COLLECTIONS ===\n")

let scores = [85, 92, 78, 95, 88]

// ✅ map: Transform each element
let gradeLetters = scores.map { score -> String in
    if score >= 90 {
        return "A"
    } else if score >= 80 {
        return "B"
    } else {
        return "C"
    }
}
print("Grades: \(gradeLetters)")

// ✅ filter: Keep only elements matching condition
let highScores = scores.filter { $0 >= 90 }
print("High scores (90+): \(highScores)")

// ✅ reduce: Combine all elements into single value
let totalScore = scores.reduce(0) { $0 + $1 }
let averageScore = Double(totalScore) / Double(scores.count)
print("Total: \(totalScore), Average: \(averageScore)")

// ✅ sorted: Sort with custom logic
let sortedDescending = scores.sorted { $0 > $1 }
print("Sorted (descending): \(sortedDescending)")

// ✅ compactMap: Map and filter nils
let maybeNumbers: [String?] = ["1", "2", nil, "4"]
let validNumbers = maybeNumbers.compactMap { $0.flatMap(Int.init) }
print("Valid numbers: \(validNumbers)")


// SECTION 4: Capturing Variables
// ============================================================================

print("\n=== VARIABLE CAPTURING ===\n")

var counter = 0

// ✅ Closure captures counter by reference (can modify original)
let increment: () -> Int = {
    counter += 1
    return counter
}

print("First call: \(increment())")      // Output: 1
print("Second call: \(increment())")     // Output: 2
print("Original counter: \(counter)")    // Output: 2

// ✅ Capturing by value (creates a copy)
let capturedValue = 100
let addToCapture: (Int) -> Int = { addAmount in
    return capturedValue + addAmount
}

print("Added to captured value: \(addToCapture(50))")  // Output: 150
print("Original captured value unchanged: \(capturedValue)")


// SECTION 5: Escaping vs Non-Escaping Closures
// ============================================================================

print("\n=== ESCAPING CLOSURES ===\n")

// ✅ Non-escaping closure (default) - completes before function returns
func processArray(_ array: [Int], with operation: (Int) -> Int) -> [Int] {
    return array.map(operation)
}

let result = processArray([1, 2, 3]) { $0 * 2 }
print("Non-escaping result: \(result)")

// ✅ Escaping closure - stored for later use
var completionHandlers: [(String) -> Void] = []

func storeCompletion(handler: @escaping (String) -> Void) {
    completionHandlers.append(handler)
    print("Handler stored")
}

storeCompletion { message in
    print("Completion: \(message)")
}

// Execute stored closures later
for handler in completionHandlers {
    handler("Task completed!")
}


// SECTION 6: Common Mistakes (Anti-patterns)
// ============================================================================

print("\n=== COMMON MISTAKES ===\n")

// ❌ MISTAKE 1: Forgetting @escaping decorator
print("❌ MISTAKE 1: @escaping")
// This would cause compiler error:
// func storeCallback(handler: (String) -> Void) {  // ⚠️ Error! Need @escaping
//     completionHandlers.append(handler)
// }

print("(Shown correctly in previous example with @escaping)")

// ❌ MISTAKE 2: Strong reference cycles (memory leak)
print("\n❌ MISTAKE 2: Strong reference cycles")
class NetworkManager {
    var name = "API"
    
    // ⚠️ This creates a strong cycle if closure is retained
    let badCallback: (() -> Void)? = {
        print("Callback")
    }
}

// ✅ FIX: Use [weak self] to avoid retain cycles
print("✅ FIX: Using [weak self]")
class APIClient {
    var name = "Client"
    
    func fetchData(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            print("Data fetched from \(self?.name ?? "unknown")")
            completion()
        }
    }
}

let client = APIClient()
client.fetchData {
    print("Completion handler called")
}

// ❌ MISTAKE 3: Using [unowned self] incorrectly
print("\n❌ MISTAKE 3: Wrong reference handling")
// [unowned self] should only be used when you're SURE self will exist
// Use [weak self] by default for safety

// ✅ FIX: Prefer [weak self]
class DataManager {
    var data = "Important"
    
    func load(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }  // Safe unwrapping
            print("Loaded: \(self.data)")
            completion()
        }
    }
}

// ❌ MISTAKE 4: Mutating captured values incorrectly
print("\n❌ MISTAKE 4: Unintended value capture")
var multiplier = 2
let multiplyNumbers = { (num: Int) -> Int in
    num * multiplier  // Captures by reference
}

print("Multiply 5: \(multiplyNumbers(5))")  // 10
multiplier = 3
print("Multiply 5 again: \(multiplyNumbers(5))")  // 15 (changed!)

// ✅ FIX: Capture explicitly if you need a fixed value
var factor = 2
let multiply2 = { [capturedFactor = factor] (num: Int) -> Int in
    num * capturedFactor  // Uses captured value, not reference
}

print("Multiply 5 with captured: \(multiply2(5))")  // 10
factor = 3
print("Multiply 5 again: \(multiply2(5))")  // Still 10


// SECTION 7: Best Practices
// ============================================================================

print("\n=== BEST PRACTICES ===\n")

// ✅ PRACTICE 1: Use trailing closures for readability
print("✅ PRACTICE 1: Trailing closures")
func filterUsers(users: [String], condition: (String) -> Bool) -> [String] {
    users.filter(condition)
}

let result7 = filterUsers(users: ["Alice", "Bob", "Charlie"]) { name in
    name.count > 3
}
print("Long names: \(result7)")

// ✅ PRACTICE 2: Use descriptive closure parameter names
print("\n✅ PRACTICE 2: Descriptive parameter names")
let calculateDiscount: (originalPrice: Double, discountPercent: Double) -> Double = 
    { originalPrice, discountPercent in
        originalPrice * (1 - discountPercent / 100)
    }

print("$100 with 20% discount: $\(calculateDiscount(100, 20))")

// ✅ PRACTICE 3: Document closure behavior
print("\n✅ PRACTICE 3: Documented closure")
/// Performs an operation on two integers
/// - Parameters:
///   - a: First integer
///   - b: Second integer
///   - operation: Closure that takes two ints and returns an int
/// - Returns: Result of the operation
func compute(a: Int, b: Int, operation: (Int, Int) -> Int) -> Int {
    operation(a, b)
}

let multiplication = compute(a: 6, b: 7) { $0 * $1 }
print("6 × 7 = \(multiplication)")

// ✅ PRACTICE 4: Use @escaping wisely
print("\n✅ PRACTICE 4: Escaping closure example")
func fetchUserData(userId: Int, completion: @escaping (String) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
        completion("User-\(userId) Data")
    }
}

fetchUserData(userId: 42) { userData in
    print("Received: \(userData)")
}

// ✅ PRACTICE 5: Combine closures for complex operations
print("\n✅ PRACTICE 5: Combining operations")
let numbers2 = [1, 2, 3, 4, 5]
let transformed = numbers2
    .filter { $0 > 2 }           // Keep: 3, 4, 5
    .map { $0 * $0 }             // Square: 9, 16, 25
    .reduce(0) { $0 + $1 }       // Sum: 50

print("Complex pipeline result: \(transformed)")


print("\n=== END OF CLOSURES PLAYGROUND ===")
