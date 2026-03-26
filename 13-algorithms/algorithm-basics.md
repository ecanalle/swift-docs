# Algorithm Basics - Common Patterns

## Overview

Understanding algorithms and data structure patterns is crucial for writing efficient Swift code. This covers common algorithms useful for iOS development.

## Main Topics

- [Time and Space Complexity](#time-and-space-complexity)
- [Common Patterns](#common-patterns)
- [Recursion](#recursion)
- [Dynamic Programming](#dynamic-programming)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

---

## Time and Space Complexity

### Big O Notation

```swift
import Foundation

enum ComplexityExamples {
    // O(1) - Constant
    static func constantTime(_ array: [Int]) -> Int? {
        return array.first
    }
    
    // O(log n) - Logarithmic  
    static func logarithmicTime(_ array: [Int], target: Int) -> Bool {
        var low = 0
        var high = array.count - 1
        
        while low <= high {
            let mid = (low + high) / 2
            if array[mid] == target { return true }
            else if array[mid] < target { low = mid + 1 }
            else { high = mid - 1 }
        }
        
        return false
    }
    
    // O(n) - Linear
    static func linearTime(_ array: [Int]) -> Int {
        var sum = 0
        for num in array {
            sum += num
        }
        return sum
    }
    
    // O(n log n) - Linearithmic
    static func linearithmicTime(_ array: inout [Int]) -> [Int] {
        array.sort()  // Default sort: O(n log n)
        return array
    }
    
    // O(n²) - Quadratic
    static func quadraticTime(_ array: [Int]) -> [[Int]] {
        var result: [[Int]] = []
        for i in array {
            for j in array {
                result.append([i, j])
            }
        }
        return result
    }
    
    // O(2^n) - Exponential
    static func exponentialTime(_ n: Int) -> Int {
        if n <= 1 { return n }
        return exponentialTime(n - 1) + exponentialTime(n - 2)  // Fibonacci
    }
}
```

---

## Common Patterns

### Two Pointer Technique

```swift
import Foundation

class TwoPointerExample {
    // Find pair with target sum in sorted array
    static func findPair(in array: [Int], targetSum: Int) -> (Int, Int)? {
        var left = 0
        var right = array.count - 1
        
        while left < right {
            let sum = array[left] + array[right]
            
            if sum == targetSum {
                return (array[left], array[right])
            } else if sum < targetSum {
                left += 1
            } else {
                right -= 1
            }
        }
        
        return nil
    }
    
    // Remove duplicates from array
    static func removeDuplicates(_ array: inout [Int]) {
        guard array.count > 1 else { return }
        
        var left = 0
        
        for right in 1..<array.count {
            if array[right] != array[left] {
                left += 1
                array[left] = array[right]
            }
        }
        
        array = Array(array[0...left])
    }
}
```

### Sliding Window

```swift
import Foundation

class SlidingWindowExample {
    // Find longest substring without repeating characters
    static func longestSubstring(_ s: String) -> Int {
        var charIndexMap: [Character: Int] = [:]
        var maxLength = 0
        var windowStart = 0
        
        for (index, char) in s.enumerated() {
            if let lastIndex = charIndexMap[char], lastIndex >= windowStart {
                windowStart = lastIndex + 1
            }
            
            charIndexMap[char] = index
            maxLength = max(maxLength, index - windowStart + 1)
        }
        
        return maxLength
    }
    
    // Maximum sum of window of size k
    static func maxWindowSum(_ array: [Int], k: Int) -> Int {
        guard k <= array.count else { return Int.min }
        
        var windowSum = array[0..<k].reduce(0, +)
        var maxSum = windowSum
        
        for i in k..<array.count {
            windowSum = windowSum - array[i - k] + array[i]
            maxSum = max(maxSum, windowSum)
        }
        
        return maxSum
    }
}
```

---

## Recursion

### Basic Recursion

```swift
import Foundation

class RecursionExample {
    // Factorial: n! = n * (n-1)!
    static func factorial(_ n: Int) -> Int {
        guard n > 1 else { return 1 }
        return n * factorial(n - 1)
    }
    
    // Fibonacci
    static func fibonacci(_ n: Int) -> Int {
        guard n > 1 else { return n }
        return fibonacci(n - 1) + fibonacci(n - 2)
    }
    
    // Power: a^b
    static func power(_ a: Int, _ b: Int) -> Int {
        guard b > 0 else { return 1 }
        return a * power(a, b - 1)
    }
    
    // Reverse string
    static func reverse(_ s: String) -> String {
        guard s.count > 0 else { return s }
        return String(s.last!) + reverse(String(s.dropLast()))
    }
}
```

### Tree Traversal with Recursion

```swift
import Foundation

class TreeNode {
    var value: Int
    var left: TreeNode?
    var right: TreeNode?
    
    init(_ value: Int) {
        self.value = value
    }
}

class TreeTraversal {
    // In-order: Left, Root, Right
    static func inOrder(_ node: TreeNode?, result: inout [Int]) {
        guard let node = node else { return }
        
        inOrder(node.left, result: &result)
        result.append(node.value)
        inOrder(node.right, result: &result)
    }
    
    // Pre-order: Root, Left, Right
    static func preOrder(_ node: TreeNode?, result: inout [Int]) {
        guard let node = node else { return }
        
        result.append(node.value)
        preOrder(node.left, result: &result)
        preOrder(node.right, result: &result)
    }
    
    // Post-order: Left, Right, Root
    static func postOrder(_ node: TreeNode?, result: inout [Int]) {
        guard let node = node else { return }
        
        postOrder(node.left, result: &result)
        postOrder(node.right, result: &result)
        result.append(node.value)
    }
}
```

---

## Dynamic Programming

### Memoized Fibonacci

```swift
import Foundation

class DynamicProgramming {
    static var memo: [Int: Int] = [:]
    
    // Fibonacci with memoization: O(n) instead of O(2^n)
    static func fibonacciMemo(_ n: Int) -> Int {
        if n <= 1 { return n }
        
        if let cached = memo[n] {
            return cached
        }
        
        let result = fibonacciMemo(n - 1) + fibonacciMemo(n - 2)
        memo[n] = result
        return result
    }
    
    // Coin change problem
    static func minCoins(_ coins: [Int], _ amount: Int) -> Int {
        var dp = Array(repeating: amount + 1, count: amount + 1)
        dp[0] = 0
        
        for i in 1...amount {
            for coin in coins {
                if coin <= i {
                    dp[i] = min(dp[i], dp[i - coin] + 1)
                }
            }
        }
        
        return dp[amount] > amount ? -1 : dp[amount]
    }
}
```

---

## 🎯 Best Practices

### 1. Analyze Complexity Before Coding
```swift
// ✅ Choose efficient algorithm
// Use binary search: O(log n)
let index = binarySearch(sortedArray, target: 5)

// ❌ Don't use inefficient algorithm by default
// Linear search: O(n)
```

### 2. Cache Results When Possible
```swift
// ✅ Memoization
var cache: [Int: Int] = [:]
func compute(_ n: Int) -> Int {
    if let cached = cache[n] { return cached }
    let result = expensiveComputation(n)
    cache[n] = result
    return result
}

// ❌ Recompute every time
```

### 3. Consider Space-Time Tradeoff
```swift
// ✅ Use more memory for speed
var hashSet = Set(array)  // O(n) space, O(1) lookup

// ❌ Save space but slow lookups
array.contains(item)  // O(1) space, O(n) lookup
```

---

## ❌ Common Mistakes

### Mistake 1: Inefficient Recursion

**WRONG:**
```swift
// ❌ O(2^n) - exponential
func fibonacci(_ n: Int) -> Int {
    if n <= 1 { return n }
    return fibonacci(n - 1) + fibonacci(n - 2)
}
```

**CORRECT:**
```swift
// ✅ O(n) with memoization
var memo: [Int: Int] = [:]
func fibonacci(_ n: Int) -> Int {
    if n <= 1 { return n }
    if let cached = memo[n] { return cached }
    
    let result = fibonacci(n - 1) + fibonacci(n - 2)
    memo[n] = result
    return result
}
```

---

### Mistake 2: Nested Loops Complexity

**WRONG:**
```swift
// ❌ O(n³) complexity
for i in array {
    for j in array {
        for k in array {
            process(i, j, k)  // Too slow!
        }
    }
}
```

**CORRECT:**
```swift
// ✅ Find better algorithm
// Use hash set or two pointer technique
```

---

## Related Topics

- [Collections (Arrays, Sets, Dicts)](../01-fundamentals/collections.md)
- [Performance Optimization](../07-advanced/performance-optimization.md)
- [Sorting and Searching](sorting-searching-filtering.md)

---

**Master algorithms for efficient Swift code!**
