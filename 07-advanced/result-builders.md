# Result Builders - Declarative Syntax

## Overview

Result Builders (iOS 13+, formerly Function Builders) enable declarative domain-specific languages (DSLs). They transform sequences of expressions into aggregated values, powering SwiftUI's block syntax.

## Main Topics

- [Basic Concepts](#basic-concepts)
- [SwiftUI Example](#swiftui-example)
- [Custom Builders](#custom-builders)
- [Advanced Patterns](#advanced-patterns)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Result Builders](https://developer.apple.com/documentation/swift/resultbuilder)

---

## Basic Concepts

### Traditional vs Result Builder

```swift
// Traditional Approach
func buildArray() -> [Int] {
    var result: [Int] = []
    result.append(1)
    result.append(2)
    result.append(3)
    return result
}

// Result Builder Approach
@resultBuilder
struct ArrayBuilder {
    static func buildBlock(_ components: Int...) -> [Int] {
        Array(components)
    }
}

@ArrayBuilder
func buildArrayDeclarative() -> [Int] {
    1
    2
    3
}
```

### Required Methods

```swift
@resultBuilder
struct MyBuilder {
    // Combines multiple expressions into one value
    static func buildBlock(_ components: Int...) -> Int {
        components.reduce(0, +)
    }
    
    // Handles if statements
    static func buildEither(first: Int) -> Int {
        first
    }
    
    static func buildEither(second: Int) -> Int {
        second
    }
    
    // Handles loops
    static func buildArray(_ components: [Int]) -> Int {
        components.reduce(0, +)
    }
    
    // Builds optional values
    static func buildOptional(_ component: Int?) -> Int {
        component ?? 0
    }
}
```

---

## SwiftUI Example

### How SwiftUI Uses Result Builders

```swift
// SwiftUI uses ViewBuilder internally
struct VStack<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        // Render stacked views
    }
}

// Usage - looks declarative
VStack {
    Text("Hello")      // View 1
    Text("World")      // View 2
    Divider()         // View 3
}

// Under the hood: ViewBuilder combines all three views
```

### Custom ViewBuilder Pattern

```swift
struct VerticalStack: View {
    let views: [AnyView]
    
    init(@ViewBuilder _ views: () -> some View) {
        self.views = [AnyView(views())]
    }
    
    var body: some View {
        VStack {
            ForEach(Array(views.enumerated()), id: \.offset) { _, view in
                view
            }
        }
    }
}

// Usage
VerticalStack {
    Text("Item 1")
    Text("Item 2")
}
```

---

## Custom Builders

### Simple List Builder

```swift
@resultBuilder
struct ListBuilder {
    typealias Component = ListItem
    
    static func buildBlock(_ components: Component...) -> [Component] {
        components
    }
    
    static func buildOptional(_ component: Component?) -> [Component] {
        component.map { [$0] } ?? []
    }
    
    static func buildEither(first: [Component]) -> [Component] {
        first
    }
    
    static func buildEither(second: [Component]) -> [Component] {
        second
    }
    
    static func buildArray(_ components: [[Component]]) -> [Component] {
        components.flatMap { $0 }
    }
}

struct ListItem {
    let title: String
}

@ListBuilder
func createMenuItems(showAdvanced: Bool) -> [ListItem] {
    ListItem(title: "Home")
    ListItem(title: "Settings")
    
    if showAdvanced {
        ListItem(title: "Developer")
        ListItem(title: "Debug")
    }
}

let items = createMenuItems(showAdvanced: true)
```

### Menu Builder

```swift
protocol MenuItem {
    var label: String { get }
}

struct Menu: MenuItem {
    let label: String
    let items: [MenuItem]
}

struct Action: MenuItem {
    let label: String
    let action: () -> Void
}

@resultBuilder
struct MenuBuilder {
    static func buildBlock(_ components: MenuItem...) -> [MenuItem] {
        Array(components)
    }
    
    static func buildOptional(_ component: [MenuItem]?) -> [MenuItem] {
        component ?? []
    }
    
    static func buildEither(first: [MenuItem]) -> [MenuItem] {
        first
    }
    
    static func buildEither(second: [MenuItem]) -> [MenuItem] {
        second
    }
}

func createContextMenu(
    isAdmin: Bool,
    @MenuBuilder builder: () -> [MenuItem]
) -> Menu {
    Menu(label: "Options", items: builder())
}

let menu = createContextMenu(isAdmin: true) {
    Action(label: "Copy", action: { })
    Action(label: "Cut", action: { })
    
    if isAdmin {
        Action(label: "Delete", action: { })
    }
}
```

### SQL Query Builder

```swift
protocol QueryComponent {
    var sql: String { get }
}

struct SelectClause: QueryComponent {
    let columns: [String]
    var sql: String {
        "SELECT \(columns.joined(separator: ", "))"
    }
}

struct FromClause: QueryComponent {
    let table: String
    var sql: String {
        "FROM \(table)"
    }
}

struct WhereClause: QueryComponent {
    let condition: String
    var sql: String {
        "WHERE \(condition)"
    }
}

@resultBuilder
struct QueryBuilder {
    static func buildBlock(_ components: QueryComponent...) -> String {
        components.map { $0.sql }.joined(separator: " ")
    }
}

@QueryBuilder
func buildQuery() -> String {
    SelectClause(columns: ["id", "name"])
    FromClause(table: "users")
    WhereClause(condition: "age > 18")
}

let query = buildQuery()
// "SELECT id, name FROM users WHERE age > 18"
```

---

## Advanced Patterns

### Conditional Building

```swift
@resultBuilder
struct ConfigBuilder {
    typealias Component = ConfigItem
    
    static func buildBlock(_ components: Component...) -> [Component] {
        components
    }
    
    static func buildIf(_ component: Component?) -> [Component] {
        component.map { [$0] } ?? []
    }
    
    static func buildEither(first: [Component]) -> [Component] {
        first
    }
    
    static func buildEither(second: [Component]) -> [Component] {
        second
    }
}

struct ConfigItem {
    let key: String
    let value: String
}

@ConfigBuilder
func buildConfig(debug: Bool) -> [ConfigItem] {
    ConfigItem(key: "app_name", value: "MyApp")
    
    if debug {
        ConfigItem(key: "log_level", value: "debug")
        ConfigItem(key: "verbose", value: "true")
    } else {
        ConfigItem(key: "log_level", value: "info")
    }
}
```

### Limited Availability

```swift
@resultBuilder
struct ResponsiveBuilder {
    typealias Component = ResponsiveView
    
    static func buildBlock(_ components: Component...) -> ResponsiveView {
        ResponsiveView(children: Array(components))
    }
    
    // Only on iOS 15+
    @available(iOS 15, *)
    static func buildLimitedAvailability(_ component: Component) -> Component {
        component
    }
}

struct ResponsiveView {
    let children: [ResponsiveView]
}
```

### Partial Result Transformation

```swift
@resultBuilder
struct FormBuilder {
    typealias Component = FormField
    
    static func buildBlock(_ components: Component...) -> [Component] {
        Array(components)
    }
    
    // Transform before aggregation
    static func buildExpression(_ expression: String) -> Component {
        FormField(label: expression, type: .text)
    }
    
    static func buildExpression(_ expression: Component) -> Component {
        expression
    }
}

struct FormField {
    let label: String
    let type: FieldType
    
    enum FieldType {
        case text, number, email
    }
}

func createForm(@FormBuilder fields: () -> [FormField]) {
    // Use fields
}

createForm {
    "Enter name"
    "Enter email"
    FormField(label: "Age", type: .number)
}
```

---

## 🎯 Best Practices

### 1. Clear Purpose
```swift
// ✅ Builder purpose is obvious
@resultBuilder
struct MenuBuilder {
    // Builds menus declaratively
}

// ❌ Unclear what builder does
@resultBuilder
struct Builder {
    // What am I building?
}
```

### 2. Implement Standard Methods
```swift
// ✅ Support common patterns
@resultBuilder
struct ConfigBuilder {
    static func buildBlock(_ components: ConfigItem...) -> [ConfigItem]
    static func buildOptional(_ component: ConfigItem?) -> [ConfigItem]
    static func buildEither(first: [ConfigItem]) -> [ConfigItem]
    static func buildEither(second: [ConfigItem]) -> [ConfigItem]
}

// ❌ Missing support for if statements
@resultBuilder
struct IncompleteBuilder {
    static func buildBlock(_ components: Item...) -> [Item]
    // No buildEither!
}
```

### 3. Type Safety
```swift
// ✅ Enforce type safety
@resultBuilder
struct TypedBuilder {
    static func buildBlock(_ components: ConfigItem...) -> [ConfigItem]
    // Only ConfigItem allowed
}

// ❌ Too permissive
@resultBuilder
struct UntypedBuilder {
    static func buildBlock(_ components: Any...) -> [Any]
    // Anything goes - confuses users
}
```

---

## ❌ Common Mistakes

### Mistake 1: Missing buildBlock

**WRONG:**
```swift
// ❌ No buildBlock method
@resultBuilder
struct MyBuilder {
    static func buildOptional(_ component: Int?) -> Int { }
}
```

**CORRECT:**
```swift
// ✅ buildBlock handles multiple expressions
@resultBuilder
struct MyBuilder {
    static func buildBlock(_ components: Int...) -> Int {
        components.reduce(0, +)
    }
}
```

---

### Mistake 2: Ignoring Type Requirements

**WRONG:**
```swift
// ❌ Inconsistent return types
@resultBuilder
struct Builder {
    static func buildBlock(_ components: Int...) -> String {
        "Done"  // Doesn't match component type
    }
}
```

**CORRECT:**
```swift
// ✅ Consistent types
@resultBuilder
struct Builder {
    static func buildBlock(_ components: Int...) -> [Int] {
        Array(components)
    }
}
```

---

### Mistake 3: Incomplete Conditional Support

**WRONG:**
```swift
// ❌ Can't use if statements
@resultBuilder
struct Builder {
    static func buildBlock(_ components: Item...) -> [Item]
    
    // Missing buildEither for if/else
}
```

**CORRECT:**
```swift
// ✅ Full conditional support
@resultBuilder
struct Builder {
    static func buildBlock(_ components: Item...) -> [Item]
    
    static func buildEither(first: [Item]) -> [Item] { first }
    static func buildEither(second: [Item]) -> [Item] { second }
}
```

---

## Related Topics

- [Generics](generics.md)
- [Protocol-Oriented Programming](protocols.md)
- [SwiftUI Basics](../../05-features/swiftui-basics.md)
- [Domain-Specific Languages (DSLs)](design-patterns.md)

---

**Master Result Builders to create elegant, declarative APIs!**
