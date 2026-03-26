# Combine Framework

## Overview

Combine is Apple's reactive programming framework that helps you manage asynchronous events and dynamic values over time. It provides composable operators for transforming, filtering, and combining event streams.

## Main Topics

- [Combine Concepts](#combine-concepts)
- [Publishers](#publishers)
- [Subscribers](#subscribers)
- [Operators](#operators)
- [Subject Types](#subject-types)
- [Error Handling](#error-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Combine Framework](https://developer.apple.com/documentation/combine)
- [Using Combine](https://developer.apple.com/documentation/combine/using_combine)

---

## Combine Concepts

### Publication-Subscription Pattern

```swift
import Combine

// Publisher: Provides values over time
let publisher = Just(42)  // Emits single value

// Subscriber: Receives values
let subscription = publisher.sink { value in
    print("Received: \(value)")
}

// AnyCancellable: Manage subscription lifetime
var cancellables = Set<AnyCancellable>()

publisher.sink { value in
    print("Value: \(value)")
}
.store(in: &cancellables)
```

### Core Types

```swift
// Publisher - Emits values and completions
protocol Publisher<Output, Failure> {
    associatedtype Output
    associatedtype Failure: Error
}

// Subscriber - Receives values
protocol Subscriber<Input, Failure> {
    associatedtype Input
    associatedtype Failure: Error
}

// Subscription - Controls the stream
protocol Subscription: Cancellable {
    func request(_ demand: Subscribers.Demand)
}

// Operator - Transforms publishers
protocol Publisher {
    func map<T>(_ transform: (Output) -> T) -> Publishers.Map<Self, T>
}
```

---

## Publishers

### Common Publishers

```swift
// Just - Emits single value and completes
Just(5).sink { value in
    print(value)  // 5
}

// PassthroughSubject - Manual control
let subject = PassthroughSubject<String, Never>()
subject.send("Hello")
subject.send("World")
subject.send(completion: .finished)

// CurrentValueSubject - Stores latest value
let current = CurrentValueSubject<Int, Never>(0)
current.value = 10  // Update value
current.send(20)    // Send through publisher

// Timer
Timer.publish(every: 1.0, on: .main, in: .common)
    .autoconnect()
    .sink { date in
        print("Timer fired: \(date)")
    }
    .store(in: &cancellables)

// NotificationCenter
NotificationCenter.default
    .publisher(for: UIApplication.didBecomeActiveNotification)
    .sink { _ in
        print("App became active")
    }
    .store(in: &cancellables)

// @Published property wrapper
class User {
    @Published var name: String = "John"
}

let user = User()
user.$name  // Publisher<String, Never>
    .sink { newName in
        print("Name changed: \(newName)")
    }
    .store(in: &cancellables)

user.name = "Jane"  // Triggers publisher
```

### Future Publisher

```swift
// Future - Async operation with eventual single value
func fetchUser() -> Future<User, Error> {
    Future { promise in
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            if let user = try? fetchFromAPI() {
                promise(.success(user))
            } else {
                promise(.failure(NetworkError.failed))
            }
        }
    }
}

fetchUser()
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error: \(error)")
            }
        },
        receiveValue: { user in
            print("Got user: \(user.name)")
        }
    )
    .store(in: &cancellables)
```

---

## Subscribers

### Sink Subscriber

```swift
// Simple subscription with handlers
[1, 2, 3].publisher
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("Completed")
            case .failure(let error):
                print("Error: \(error)")
            }
        },
        receiveValue: { value in
            print("Value: \(value)")
        }
    )
    .store(in: &cancellables)
```

### Assign Subscriber

```swift
// Directly assign values to property
struct User {
    var name: String = ""
}

let user = User()
let publisher = Just("John")

publisher
    .assign(to: \.name, on: user)
    .store(in: &cancellables)

print(user.name)  // "John"
```

### Custom Subscriber

```swift
class MySubscriber: Subscriber {
    typealias Input = Int
    typealias Failure = Never
    
    func receive(subscription: Subscription) {
        subscription.request(.unlimited)
        print("Subscribed")
    }
    
    func receive(_ input: Int) -> Subscribers.Demand {
        print("Received: \(input)")
        return .none  // No backpressure
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        print("Completed")
    }
}

[1, 2, 3].publisher.subscribe(MySubscriber())
```

---

## Operators

### Transforming Operators

```swift
// map - Transform values
[1, 2, 3].publisher
    .map { $0 * 2 }
    .sink { print($0) }  // 2, 4, 6

// flatMap - Map to new publisher and flatten
URLSession.shared.dataTaskPublisher(for: url)
    .map(\.data)
    .decode(type: User.self, decoder: JSONDecoder())
    .sink { user in
        print(user)
    }
    .store(in: &cancellables)

// compactMap - Filter and transform
["1", "two", "3"].publisher
    .compactMap { Int($0) }
    .sink { print($0) }  // 1, 3

// scan - Accumulate values
[1, 2, 3].publisher
    .scan(0, +)
    .sink { print($0) }  // 1, 3, 6
```

### Filtering Operators

```swift
// filter - Keep values that pass test
[1, 2, 3, 4, 5].publisher
    .filter { $0 % 2 == 0 }
    .sink { print($0) }  // 2, 4

// removeDuplicates - Skip consecutive duplicates
[1, 1, 2, 2, 2, 3].publisher
    .removeDuplicates()
    .sink { print($0) }  // 1, 2, 3

// dropFirst - Skip first n elements
[1, 2, 3, 4].publisher
    .dropFirst(2)
    .sink { print($0) }  // 3, 4

// prefix - Take first n elements
[1, 2, 3, 4].publisher
    .prefix(2)
    .sink { print($0) }  // 1, 2
```

### Combining Operators

```swift
// combineLatest - Combine latest from multiple publishers
let pub1 = PassthroughSubject<Int, Never>()
let pub2 = PassthroughSubject<String, Never>()

Publishers.CombineLatest(pub1, pub2)
    .sink { int, string in
        print("\(int), \(string)")
    }
    .store(in: &cancellables)

pub1.send(1)
pub2.send("hello")  // Prints: 1, hello

// merge - Combine multiple publishers
pub1.merge(with: pub2)
    .sink { print($0) }
    .store(in: &cancellables)

// zipPublisher - Pair values from publishers
Publishers.Zip(pub1, pub2)
    .sink { int, string in
        print("Paired: \(int), \(string)")
    }
    .store(in: &cancellables)
```

### Timing Operators

```swift
// debounce - Wait for quiet period
textField.publisher
    .debounce(for: 0.5, scheduler: DispatchQueue.main)
    .sink { text in
        print("Searched: \(text)")
    }
    .store(in: &cancellables)

// throttle - Emit at most once per interval
timer.publisher
    .throttle(for: 1.0, scheduler: DispatchQueue.main, latest: true)
    .sink { print($0) }
    .store(in: &cancellables)

// delay - Delay emission
Just(42)
    .delay(for: 2, scheduler: DispatchQueue.main)
    .sink { print($0) }  // Prints after 2 seconds
    .store(in: &cancellables)
```

---

## Subject Types

### PassthroughSubject

```swift
// No initial value, just passes values through
let subject = PassthroughSubject<String, Never>()

subject.sink { value in
    print("Received: \(value)")
}
.store(in: &cancellables)

subject.send("Hello")  // Prints: Received: Hello
subject.send("World")  // Prints: Received: World
```

### CurrentValueSubject

```swift
// Stores and replays latest value
let subject = CurrentValueSubject<Int, Never>(0)

subject.sink { value in
    print("Value: \(value)")
}
.store(in: &cancellables)
// Immediately prints: Value: 0

subject.send(1)  // Prints: Value: 1
subject.send(2)  // Prints: Value: 2

// Access current value
print(subject.value)  // 2
```

---

## Error Handling

### Handling Errors

```swift
enum APIError: Error {
    case invalidURL
    case networkError
}

URLSession.shared.dataTaskPublisher(for: url)
    .tryMap { data, response in
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidURL
        }
        return data
    }
    .decode(type: User.self, decoder: JSONDecoder())
    .sink(
        receiveCompletion: { completion in
            switch completion {
            case .failure(let error):
                print("Error: \(error)")
            case .finished:
                print("Success")
            }
        },
        receiveValue: { user in
            print("User: \(user.name)")
        }
    )
    .store(in: &cancellables)
```

### Catch Errors

```swift
// catch - Replace error with new publisher
publisher
    .catch { error -> Just<Int> in
        print("Caught error: \(error)")
        return Just(0)  // Default value
    }
    .sink { value in
        print(value)
    }
    .store(in: &cancellables)

// tryMap - Convert to throwing operation
[1, 2, 3].publisher
    .tryMap { value in
        guard value > 0 else { throw NSError() }
        return value * 2
    }
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { print($0) }
    )
    .store(in: &cancellables)
```

---

## 🎯 Best Practices

### 1. Store Cancellables
```swift
// ✅ Retain subscriptions
var cancellables = Set<AnyCancellable>()

publisher
    .sink { value in
        print(value)
    }
    .store(in: &cancellables)

// ❌ Subscription immediately cancelled
publisher.sink { print($0) }
```

### 2. Use @Published for Reactive Properties
```swift
class ViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isLoading: Bool = false
}
```

### 3. Debounce User Input
```swift
searchTextField.textPublisher
    .debounce(for: 0.5, scheduler: DispatchQueue.main)
    .flatMap { query in
        searchService.search(query)
    }
    .sink { results in
        // Update UI
    }
    .store(in: &cancellables)
```

### 4. Compose Complex Flows
```swift
// Chain multiple operations
publisher
    .filter { $0 > 0 }
    .map { $0 * 2 }
    .compactMap { $0 as Int? }
    .removeDuplicates()
    .sink { print($0) }
    .store(in: &cancellables)
```

---

## ❌ Common Mistakes

### Mistake 1: Not Storing Cancellables

**WRONG:**
```swift
// ❌ Immediately cancelled
publisher.sink { print($0) }
```

**CORRECT:**
```swift
// ✅ Keep alive
publisher
    .sink { print($0) }
    .store(in: &cancellables)
```

---

### Mistake 2: Ignoring Errors

**WRONG:**
```swift
// ❌ Silently fails
publisher
    .sink { print($0) }
    .store(in: &cancellables)
```

**CORRECT:**
```swift
// ✅ Handle errors
publisher
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { print($0) }
    )
    .store(in: &cancellables)
```

---

## Related Topics

- [Async/Await](async-await.md)
- [SwiftUI](../../05-features/siri-and-app-intents/swiftui-basics.md)
- [Error Handling](../../01-fundamentals/fundamentals/error-handling.md)

---

**Master Combine for reactive, event-driven programming!**
