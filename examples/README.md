# Swift Documentation Examples

This folder contains **runnable code examples** that complement the documentation in the main repo. Each example is a structured playground or mini-app that demonstrates key concepts from the corresponding documentation file.

## 📁 Structure

Examples are organized by section to match the main documentation:

```
examples/
├── 01-fundamentals/          → Swift basics, functions, OOP
├── 02-architecture/          → Design patterns, DI
├── 03-networking/            → API patterns, networking
├── 04-app-lifecycle/         → App lifecycle, CI/CD
├── 05-features/              → iOS-specific features
├── 06-data/                  → Data persistence
├── 07-advanced/              → Performance, security
├── 08-resources/             → External references
```

## 🎮 How to Use

### Running Playgrounds

Playgrounds are the primary example format for code-only concepts.

**In Xcode:**
1. Open `/Users/ecanalle/Documents/projects/swift-docs/examples/`
2. Double-click any `.playground` file to open
3. Press **⌘ + ↵** (Cmd + Enter) to run the code
4. View results in the right sidebar

**Example playgrounds:**
- `01-fundamentals/optionals.playground` - Optional types, unwrapping, best practices
- `01-fundamentals/error-handling.playground` - Throwing functions, do-catch, error types
- `01-fundamentals/closures.playground` - Closures, trailing syntax, capturing
- `01-fundamentals/protocols.playground` - Protocol basics, composition, extensions

### Running Mini-Apps

Some topics require UI or interactive demonstrations. These are marked with a note in the examples folder.

**Status:** Currently all 01-fundamentals examples are playgrounds (no UI needed).

## ✅ Example Quality Standards

Every example follows these requirements:

- ✅ **Complete & runnable** - No dependencies, copy-paste ready
- ✅ **Well-commented** - Explains what, why, and how
- ✅ **Shows patterns** - Demonstrates both correct ✅ and incorrect ❌ approaches
- ✅ **Practical** - Real-world applicable, not just tutorials
- ✅ **Output included** - Shows expected results in print statements

## 📚 01-Fundamentals Examples (Phase 1 ✅ Complete)

### 1. Optionals (`optionals.playground`)
**Covers:** Optional basics, unwrapping methods, binding, nil-coalescing, chaining

**Includes:**
- Creating and checking optionals
- if-let, guard-let, nil-coalescing operator
- Optional chaining with classes/structs
- Map and flatMap on optionals
- Common pitfalls and best practices

**Related doc:** `../01-fundamentals/fundamentals/optionals.md`

### 2. Error Handling (`error-handling.playground`)
**Covers:** Custom errors, throwing functions, do-catch, try/try?/try!

**Includes:**
- Defining error enums
- Creating throwing functions
- Error propagation and handling
- Using defer for cleanup
- Comparing errors vs optionals
- Error chaining and documentation

**Related doc:** `../01-fundamentals/fundamentals/error-handling.md`

### 3. Closures (`closures.playground`)
**Covers:** Closure syntax, shorthand, capturing, escaping, memory safety

**Includes:**
- Basic closure declarations
- Trailing closures and argument shortcuts
- Working with array methods (map, filter, reduce, sorted)
- Variable capturing (by reference and value)
- Escaping closures with @escaping
- Avoiding retain cycles with [weak self]
- Common mistakes and best practices

**Related doc:** `../01-fundamentals/functions-and-closures/closures.md`

### 4. Protocols (`protocols.playground`)
**Covers:** Protocol basics, inheritance, composition, associated types

**Includes:**
- Defining and conforming to protocols
- Property requirements (get, get set)
- Protocol inheritance and composition
- Default implementations with extensions
- Associated types and generics
- Retroactive conformance
- Protocol-oriented design patterns

**Related doc:** `../01-fundamentals/object-oriented-programming/protocols.md`

---

## 📚 02-Architecture Examples (Phase 2 ✅ Complete)

### 5. Design Patterns (`design-patterns.playground`)
**Covers:** 8 essential design patterns for Swift applications

**Patterns included:**
- **Singleton** - Single shared instance with thread-safe initialization
- **Factory** - Creating objects without specifying exact classes
- **Builder** - Complex object construction with fluent API
- **Observer** - Decoupled event handling and notifications
- **Strategy** - Interchangeable algorithms (e.g., payment methods)
- **Decorator** - Adding behavior without modifying original (e.g., coffee orders)
- **Adapter** - Making incompatible interfaces work together
- **Repository** - Data access abstraction layer

**Key features:**
- WRONG ❌ vs CORRECT ✅ patterns throughout
- Anti-patterns and how to avoid them
- Real-world examples for each pattern
- When to use each pattern

**Related doc:** `../02-architecture/software-architecture/design-patterns.md`

### 6. Dependency Injection (`dependency-injection.playground`)
**Covers:** Breaking tight coupling and enabling testability

**Includes:**
- Problems with tight coupling
- **Constructor Injection** (recommended approach)
- **Property Injection** (selective use)
- **Method Injection** (context-specific)
- Service Locator pattern (anti-pattern)
- **Dependency Container** (Inversion of Control)
- Factory pattern with DI
- Testing with fake implementations
- Best practices for DI

**Key features:**
- Shows progression from bad to good patterns
- Practical IOC container implementation
- Examples of circular dependencies and solutions
- Over-injection anti-pattern

**Related doc:** `../02-architecture/dependency-injection-and-advanced-patterns/dependency-injection.md`

### 7. MVVM Architecture (`mvvm.playground`)
**Covers:** Model-View-ViewModel architectural pattern

**Components demonstrated:**
- **Model** - Data and business logic
- **ViewModel** - Transforms data, handles logic, no UI references
- **View** - UI display, no direct model access
- **Binding** - View observes ViewModel changes

**Includes:**
- Complete MVVM example with User list
- Display models vs domain models
- Observable pattern for reactive binding
- Simulated async operations
- Common MVVM mistakes and anti-patterns
- Testing strategies
- Best practices (testability, DI, separation of concerns)

**Key features:**
- Two implementations: callback-based and reactive
- Clear separation of concerns
- Examples of how to test ViewModel
- Anti-patterns: View accessing Model, ViewModel with UI imports

**Related doc:** `../02-architecture/software-architecture/mvvm.md`

## 🚀 Coming Soon

These sections will have examples added:

- **02-architecture/** - Design patterns, dependency injection, SOLID principles
- **03-networking/** - URL session, API clients, Codable examples
- **07-advanced/** - Async-await, actors, performance optimization
- **Other sections** - As documentation expands

## 🔗 Links Back to Docs

Each playground file includes a header comment with the corresponding documentation file path. For example:

```swift
// Corresponds to: 01-fundamentals/fundamentals/optionals.md
```

Use these links to dive deeper into each topic.

## ⚙️ Requirements

- **Xcode 15.0+** (or latest stable version)
- **Swift 5.9+**
- **macOS 13.0+** (to run playgrounds)

## 📝 Contributing New Examples

To add a new example:

1. Create a `.playground` folder in the appropriate section directory
2. Follow the naming convention: `topic-name.playground`
3. Include a `Contents.swift` file with:
   - Clear section headers
   - WRONG ❌ and CORRECT ✅ patterns
   - Best practices section
   - Related topics section
   - Thorough comments

4. Add metadata file: `contents.xcplayground` (copy from existing)
5. Update this README with a new subsection

Example structure:
```
examples/
└── 01-fundamentals/
    └── my-topic.playground/
        ├── Contents.swift          (main code)
        ├── contents.xcplayground   (metadata)
        ├── Sources/                (shared code)
        └── Resources/              (assets if needed)
```

## 🐛 Issues or Questions?

If you find an error in the examples or have suggestions:

1. Check that the example still works with the latest Swift version
2. Verify it matches the corresponding documentation
3. Test thoroughly before reporting

---

**Last Updated:** May 10, 2026  
**Examples Status:** Phase 1-2 Complete (01-fundamentals + 02-architecture)  
**Total Playgrounds:** 7  
**Total Lines of Code:** ~2,930  

**Phase Progress:**
- ✅ Phase 1 (01-fundamentals): 4 playgrounds, 1,349 lines
- ✅ Phase 2 (02-architecture): 3 playgrounds, 1,581 lines
- 🔄 Phase 3 (03-networking) and beyond: Ready to start
