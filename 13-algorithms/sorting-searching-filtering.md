# Sorting, Searching, and Filtering

## Overview

Sorting, searching, and filtering enable efficient data management. Swift provides powerful APIs for arranging and querying collections.

## Main Topics

- [Sorting](#sorting)
- [Searching](#searching)
- [Filtering](#filtering)
- [Performance Considerations](#performance-considerations)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

---

## Sorting

### Basic Sorting

```swift
import Foundation

class SortingExample {
    struct User {
        let id: Int
        let name: String
        let age: Int
        let email: String
    }
    
    let users: [User] = [
        User(id: 1, name: "Alice", age: 30, email: "alice@example.com"),
        User(id: 2, name: "Bob", age: 25, email: "bob@example.com"),
        User(id: 3, name: "Charlie", age: 35, email: "charlie@example.com")
    ]
    
    func sortByName() -> [User] {
        return users.sorted { $0.name < $1.name }
    }
    
    func sortByAge() -> [User] {
        return users.sorted { $0.age < $1.age }
    }
    
    func sortDescending() -> [User] {
        return users.sorted { $0.age > $1.age }
    }
    
    func sortMultipleCriteria() -> [User] {
        return users.sorted { user1, user2 in
            if user1.age != user2.age {
                return user1.age < user2.age
            }
            return user1.name < user2.name
        }
    }
    
    func sortWithComparator() -> [User] {
        return users.sorted { user1, user2 in
            let nameComparison = user1.name.localizedCaseInsensitiveCompare(user2.name)
            return nameComparison == .orderedAscending
        }
    }
}
```

### Comparable and Equatable

```swift
import Foundation

struct Product: Comparable, Equatable {
    let id: Int
    let name: String
    let price: Double
    
    static func < (lhs: Product, rhs: Product) -> Bool {
        return lhs.price < rhs.price
    }
    
    static func == (lhs: Product, rhs: Product) -> Bool {
        return lhs.id == rhs.id
    }
}

let products = [
    Product(id: 1, name: "Laptop", price: 999.99),
    Product(id: 2, name: "Phone", price: 699.99),
    Product(id: 3, name: "Tablet", price: 399.99)
]

let sorted = products.sorted()  // Uses < operator
// Result: Tablet, Phone, Laptop
```

---

## Searching

### Linear Search

```swift
import Foundation

class SearchingExample {
    struct Book {
        let id: Int
        let title: String
        let author: String
    }
    
    let books: [Book] = [
        Book(id: 1, title: "Swift Guide", author: "John"),
        Book(id: 2, title: "iOS Development", author: "Jane"),
        Book(id: 3, title: "Advanced Swift", author: "Bob")
    ]
    
    func findBook(byTitle title: String) -> Book? {
        return books.first { $0.title.localizedCaseInsensitiveContains(title) }
    }
    
    func findBooks(byAuthor author: String) -> [Book] {
        return books.filter { $0.author.localizedCaseInsensitiveCompare(author) == .orderedSame }
    }
    
    func searchBooks(query: String) -> [Book] {
        return books.filter { book in
            book.title.localizedCaseInsensitiveContains(query) ||
            book.author.localizedCaseInsensitiveContains(query)
        }
    }
}
```

### Binary Search

```swift
import Foundation

class BinarySearch {
    // Requires sorted array
    static func binarySearch(_ array: [Int], target: Int) -> Int? {
        var left = 0
        var right = array.count - 1
        
        while left <= right {
            let mid = (left + right) / 2
            
            if array[mid] == target {
                return mid
            } else if array[mid] < target {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        return nil
    }
    
    // Generic binary search
    static func binarySearchGeneric<T: Comparable>(_ array: [T], target: T) -> Int? {
        var left = 0
        var right = array.count - 1
        
        while left <= right {
            let mid = (left + right) / 2
            
            if array[mid] == target {
                return mid
            } else if array[mid] < target {
                left = mid + 1
            } else {
                right = mid - 1
            }
        }
        
        return nil
    }
}

let numbers = [1, 3, 5, 7, 9, 11, 13]
if let index = BinarySearch.binarySearch(numbers, target: 7) {
    print("Found at index: \(index)")  // Index: 3
}
```

---

## Filtering

### Array Filtering

```swift
import Foundation

class FilteringExample {
    struct Task {
        let id: Int
        let title: String
        let priority: Int  // 1-3
        let completed: Bool
    }
    
    let tasks: [Task] = [
        Task(id: 1, title: "Learn Swift", priority: 3, completed: false),
        Task(id: 2, title: "Build App", priority: 2, completed: false),
        Task(id: 3, title: "Fix Bug", priority: 1, completed: true),
        Task(id: 4, title: "Deploy", priority: 3, completed: false)
    ]
    
    func incompleteTasks() -> [Task] {
        return tasks.filter { !$0.completed }
    }
    
    func highPriorityTasks() -> [Task] {
        return tasks.filter { $0.priority >= 3 }
    }
    
    func incompleteBgBatch() -> [Task] {
        return tasks.filter { !$0.completed && $0.priority >= 2 }
    }
    
    func groupByPriority() -> [Int: [Task]] {
        return Dictionary(grouping: tasks) { $0.priority }
    }
}
```

### Collection Filtering with Predicates

```swift
import Foundation

class PredicateFiltering {
    static func filterByPredicate<T>(_ array: [T], predicate: (T) -> Bool) -> [T] {
        return array.filter(predicate)
    }
    
    // Example
    let numbers = Array(1...100)
    
    func evenNumbers() -> [Int] {
        return numbers.filter { $0 % 2 == 0 }
    }
    
    func numbersGreaterThan50() -> [Int] {
        return numbers.filter { $0 > 50 }
    }
}
```

---

## Performance Considerations

### Optimizing Search Performance

```swift
import Foundation

class PerformanceExample {
    // Slow: O(n) for each search
    func slowSearch(in array: [String], query: String) -> [String] {
        return array.filter { $0.contains(query) }
    }
    
    // Fast: O(1) after setup for exact matches
    func fastSearch(in array: [String], query: String) -> [String] {
        let set = Set(array)
        return set.contains(query) ? [query] : []
    }
    
    // Dictionary for fast lookups
    var usersDictionary: [Int: String] = [:]
    
    func findUser(byID id: Int) -> String? {
        return usersDictionary[id]  // O(1)
    }
    
    // Large data sorting
    func efficientSort(_ array: inout [Int]) {
        // In-place sort is more memory efficient
        array.sort()  // Uses introsort: O(n log n)
    }
}
```

---

## 🎯 Best Practices

### 1. Use Efficient Algorithms
```swift
// ✅ Binary search for sorted data: O(log n)
let index = BinarySearch.binarySearch(sortedArray, target: 5)

// ❌ Linear search: O(n)
let index = array.firstIndex { $0 == 5 }
```

### 2. Use Appropriate Collections
```swift
// ✅ Set for uniqueness checks: O(1)
let uniqueItems = Set(items)

// ❌ Array contains: O(n)
if array.contains(item) { }
```

### 3. Sort Once
```swift
// ✅ Cache sorted results
let sorted = items.sorted()
for item in sorted { }

// ❌ Re-sort repeatedly
for item in items.sorted() { }  // Sorts each iteration
```

---

## ❌ Common Mistakes

### Mistake 1: O(n²) in Loops

**WRONG:**
```swift
// ❌ O(n²) complexity
for item in items {
    if array.contains(item) {  // O(n) each iteration
        process(item)
    }
}
```

**CORRECT:**
```swift
// ✅ O(n) complexity
let set = Set(array)
for item in items {
    if set.contains(item) {  // O(1) each iteration
        process(item)
    }
}
```

---

### Mistake 2: Sorting Unsorted Data

**WRONG:**
```swift
// ❌ Sorting adds O(n log n)
let results = allItems.sorted().filter { $0.priority > 5 }
```

**CORRECT:**
```swift
// ✅ Filter first
let results = allItems.filter { $0.priority > 5 }.sorted()
```

---

## Related Topics

- [Optionals and Error Handling](../01-fundamentals/optionals.md)
- [Collections (Arrays, Sets, Dicts)](../01-fundamentals/collections.md)
- [Algorithm Basics](algorithm-basics.md)

---

**Master searching, sorting, and filtering!**
