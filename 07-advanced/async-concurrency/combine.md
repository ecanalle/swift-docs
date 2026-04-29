# Combine Framework - Reactive Programming

## Overview

Combine provides reactive programming capabilities for handling asynchronous events and data streams. It uses Publishers, Subscribers, and Operators.

## Main Topics

- [Publishers and Subscribers](#publishers-and-subscribers)
- [Operators](#operators)
- [Practical Examples](#practical-examples)
- [Error Handling](#error-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Combine](https://developer.apple.com/documentation/combine)

---

## Publishers and Subscribers

### Creating Publishers

```swift
import Combine

class CombineBasics {
    // Timer publisher
    func timerExample() {
        let timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { date in
                print("Timer fired: \(date)")
            }
    }
    
    // Just publisher - Single value
    func justExample() {
        Just("Hello")
            .sink { value in
                print("Value: \(value)")
            }
    }
    
    // Future publisher - Async value
    func futureExample() {
        let future = Future<String, Error> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(.success("Delayed value"))
            }
        }
        
        future
            .sink(receiveCompletion: { _ in }, receiveValue: { print($0) })
    }
    
    // PassthroughSubject - Manual value emission
    var subject = PassthroughSubject<String, Never>()
    
    func subjectExample() {
        subject
            .sink { value in
                print("Received: \(value)")
            }
        
        subject.send("Hello")
        subject.send("World")
    }
}
```

### Managing Subscriptions

```swift
import Combine

class SubscriptionManagement {
    var cancellables = Set<AnyCancellable>()
    
    func manageSubscription() {
        let publisher = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
        
        // Store cancellable
        publisher
            .sink { print($0) }
            .store(in: &cancellables)
    }
    
    func multipleSubscriptions() {
        let publisher = PassthroughSubject<Int, Never>()
        
        // Subscribe multiple times
        publisher
            .sink { print("Sub1: \($0)") }
            .store(in: &cancellables)
        
        publisher
            .sink { print("Sub2: \($0)") }
            .store(in: &cancellables)
        
        publisher.send(42)
    }
}
```

---

## Operators

### Common Operators

```swift
import Combine

class CombineOperators {
    var cancellables = Set<AnyCancellable>()
    
    func mapOperator() {
        Just(5)
            .map { $0 * 2 }
            .sink { print("Result: \($0)") }  // Output: 10
            .store(in: &cancellables)
    }
    
    func filterOperator() {
        [1, 2, 3, 4, 5].publisher
            .filter { $0 > 3 }
            .sink { print("Value: \($0)") }
            .store(in: &cancellables)
    }
    
    func dropOperator() {
        [1, 2, 3, 4, 5].publisher
            .dropFirst(2)  // Skip first 2
            .sink { print($0) }
            .store(in: &cancellables)
    }
    
    func collectOperator() {
        [1, 2, 3, 4, 5].publisher
            .collect(2)  // Group by 2
            .sink { print("Group: \($0)") }
            .store(in: &cancellables)
    }
    
    func combineLatestOperator() {
        let subject1 = PassthroughSubject<String, Never>()
        let subject2 = PassthroughSubject<Int, Never>()
        
        Publishers.CombineLatest(subject1, subject2)
            .sink { name, age in
                print("\(name) is \(age) years old")
            }
            .store(in: &cancellables)
        
        subject1.send("Alice")
        subject2.send(30)
    }
    
    func flatMapOperator() {
        Just("Hello")
            .flatMap { value in
                Just(value + " World")
            }
            .sink { print($0) }
            .store(in: &cancellables)
    }
    
    func debounceOperator() {
        let subject = PassthroughSubject<String, Never>()
        
        subject
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { print("Debounced: \($0)") }
            .store(in: &cancellables)
    }
}
```

### Advanced Operators

```swift
import Combine

class AdvancedOperators {
    var cancellables = Set<AnyCancellable>()
    
    func switchToLatestOperator() {
        let subject = PassthroughSubject<PassthroughSubject<String, Never>, Never>()
        
        subject
            .switchToLatest()
            .sink { print("Value: \($0)") }
            .store(in: &cancellables)
    }
    
    func mergeOperator() {
        let subject1 = PassthroughSubject<String, Never>()
        let subject2 = PassthroughSubject<String, Never>()
        
        Publishers.Merge(subject1, subject2)
            .sink { print("Merged: \($0)") }
            .store(in: &cancellables)
        
        subject1.send("From subject1")
        subject2.send("From subject2")
    }
    
    func zipOperator() {
        let subject1 = PassthroughSubject<String, Never>()
        let subject2 = PassthroughSubject<Int, Never>()
        
        Publishers.Zip(subject1, subject2)
            .sink { name, age in
                print("\(name), \(age)")
            }
            .store(in: &cancellables)
    }
}
```

---

## Practical Examples

### Search with Combine

```swift
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var results: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { self.search(query: $0) }
            .switchToLatest()
            .assign(to: &$results)
    }
    
    private func search(query: String) -> AnyPublisher<[String], Never> {
        if query.isEmpty {
            return Just([]).eraseToAnyPublisher()
        }
        
        return Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let results = ["Swift", "SwiftUI", "Swift Concurrency"]
                    .filter { $0.lowercased().contains(query.lowercased()) }
                promise(.success(results))
            }
        }
        .eraseToAnyPublisher()
    }
}
```

---

## Error Handling

### Handling Errors in Combine

```swift
import Combine

enum APIError: Error {
    case invalidURL
    case networkError
}

class CombineErrorHandling {
    var cancellables = Set<AnyCancellable>()
    
    func fetchDataWithErrorHandling() {
        URLSession.shared.dataTaskPublisher(for: URL(string: "https://api.example.com")!)
            .mapError { _ in APIError.networkError }
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .catch { error -> Just<[String: String]> in
                print("Error: \(error)")
                return Just([:])
            }
            .sink { print("Data: \($0)") }
            .store(in: &cancellables)
    }
    
    func retryOperator() {
        Just(())
            .map { _ in throw APIError.networkError }
            .retry(3)
            .catch { error in
                Just(())
            }
            .sink { print("Completed") }
            .store(in: &cancellables)
    }
}
```

---

## 🎯 Best Practices

### 1. Always Manage Subscriptions
```swift
// ✅ Store cancellables
var cancellables = Set<AnyCancellable>()
publisher.sink { }.store(in: &cancellables)

// ❌ Memory leak - subscription lost
publisher.sink { }
```

### 2. Use Proper Operators
```swift
// ✅ Debounce for input
$searchText
    .debounce(for: 0.5, scheduler: DispatchQueue.main)
    .removeDuplicates()

// ❌ No debounce - spams requests
$searchText.map { search($0) }
```

### 3. Test Combine Code
```swift
// ✅ Use testing operators
let subject = PassthroughSubject<String, Never>()
var results: [String] = []
subject.sink { results.append($0) }.store(in: &cancellables)

// ❌ Complex untested chains
```

---

## ❌ Common Mistakes

### Mistake 1: Memory Leaks

**WRONG:**
```swift
// ❌ Subscription is lost
publisher.sink { print($0) }
// Immediately deallocates
```

**CORRECT:**
```swift
// ✅ Store subscription
publisher
    .sink { print($0) }
    .store(in: &cancellables)
```

---

## Related Topics

- [Async/Await](../02-concurrency/async-await.md)
- [GCD and Dispatch](../07-advanced/gcd-and-dispatch.md)
- [Networking](../03-networking/rest-api.md)

---

**Master reactive programming with Combine!**
