# Model-View-ViewModel (MVVM)

## Overview

MVVM separates UI from logic by introducing a ViewModel layer that transforms Model data into View-ready state. It enables better testability, cleaner code organization, and is particularly suited for reactive programming patterns like Combine and async/await.

## Main Topics

- [MVVM Concepts](#mvvm-concepts)
- [Components](#components)
- [Data Binding](#data-binding)
- [Implementation with UIKit](#implementation-with-uikit)
- [Implementation with SwiftUI](#implementation-with-swiftui)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Apple: Model-View-ViewModel Pattern](https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaCore/MVC.html)

---

## MVVM Concepts

### The Three Components

```swift
// MODEL - Data and business logic (unchanged from MVC)
class User {
    let id: Int
    let name: String
    let email: String
    
    func isValidEmail() -> Bool {
        return email.contains("@")
    }
}

// VIEWMODEL - Transforms Model for View consumption
class UserViewModel {
    let user: User
    
    var displayName: String {
        return user.name.uppercased()
    }
    
    var emailStatus: String {
        return user.isValidEmail() ? "Valid" : "Invalid"
    }
    
    var shouldShowEmailWarning: Bool {
        return !user.isValidEmail()
    }
}

// VIEW - Pure UI (controller/view combined)
class UserViewController: UIViewController {
    var viewModel: UserViewModel?
    let nameLabel = UILabel()
    let emailLabel = UILabel()
    let warningLabel = UILabel()
    
    func displayUserInfo() {
        guard let viewModel = viewModel else { return }
        
        nameLabel.text = viewModel.displayName
        emailLabel.text = viewModel.emailStatus
        warningLabel.isHidden = !viewModel.shouldShowEmailWarning
    }
}
```

### Key Principle: Testable Logic

```swift
// ✅ ViewModel is pure logic - easy to test
class LoginViewModel {
    var email: String = ""
    var password: String = ""
    
    var isFormValid: Bool {
        return !email.isEmpty && password.count >= 8
    }
    
    var emailError: String? {
        return email.contains("@") ? nil : "Invalid email"
    }
}

// Test without UI
func testFormValidation() {
    let viewModel = LoginViewModel()
    viewModel.email = "user@example.com"
    viewModel.password = "password123"
    
    assert(viewModel.isFormValid == true)
    assert(viewModel.emailError == nil)
}
```

---

## Components

### Model

```swift
// Pure data - no UI awareness
struct Product: Codable {
    let id: Int
    let name: String
    let price: Double
    let description: String
    let imageURL: URL
    
    func isAffordable(budget: Double) -> Bool {
        return price <= budget
    }
}
```

### ViewModel

```swift
// Transforms Model for UI
class ProductViewModel {
    let product: Product
    
    // UI-ready properties
    var displayTitle: String {
        return product.name
    }
    
    var displayPrice: String {
        return String(format: "$%.2f", product.price)
    }
    
    var displayDescription: String {
        return product.description.isEmpty ? "No description" : product.description
    }
    
    var shouldShowImage: Bool {
        return URLSession.shared.configuration.requestCachePolicy != .returnCacheDataDontLoad
    }
    
    // View state
    var backgroundColor: UIColor {
        return product.price > 100 ? .systemYellow : .clear
    }
    
    init(product: Product) {
        self.product = product
    }
}
```

### View

```swift
// Pure UI - delegates logic to ViewModel
class ProductViewController: UIViewController {
    var viewModel: ProductViewModel?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    func updateUI() {
        guard let viewModel = viewModel else { return }
        
        titleLabel.text = viewModel.displayTitle
        priceLabel.text = viewModel.displayPrice
        descriptionLabel.text = viewModel.displayDescription
        view.backgroundColor = viewModel.backgroundColor
    }
}
```

---

## Data Binding

### Manual Binding

```swift
class LoginViewController: UIViewController {
    var viewModel: LoginViewModel?
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
    }
    
    @objc func emailChanged() {
        viewModel?.email = emailTextField.text ?? ""
        updateUI()
    }
    
    @objc func passwordChanged() {
        viewModel?.password = passwordTextField.text ?? ""
        updateUI()
    }
    
    func updateUI() {
        guard let viewModel = viewModel else { return }
        
        loginButton.isEnabled = viewModel.isFormValid
        errorLabel.text = viewModel.emailError
        errorLabel.isHidden = viewModel.emailError == nil
    }
}
```

### Reactive Binding with Combine

```swift
import Combine

class SearchViewModel {
    @Published var searchText: String = ""
    @Published var results: [SearchResult] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let searchService: SearchService
    
    init(searchService: SearchService) {
        self.searchService = searchService
        setupBinding()
    }
    
    private func setupBinding() {
        $searchText
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .filter { !$0.isEmpty }
            .map { [weak self] text in
                self?.searchService.search(query: text) ?? Empty().eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.results = results
            }
            .store(in: &cancellables)
    }
}

class SearchViewController: UIViewController {
    var viewModel: SearchViewModel?
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bind ViewModel properties to UI
        viewModel?.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
        
        viewModel?.$results
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.tableView?.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func updateLoadingState(_ isLoading: Bool) {
        // Show/hide spinner
    }
}
```

---

## Implementation with UIKit

### Complete Example: Todo List

```swift
struct TodoItem {
    let id: String
    var title: String
    var isCompleted: Bool
    let createdDate: Date
    
    var daysOld: Int {
        return Calendar.current.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
    }
}

class TodoViewModel {
    private let todoService: TodoService
    @Published var todos: [TodoItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    init(todoService: TodoService) {
        self.todoService = todoService
    }
    
    func loadTodos() {
        isLoading = true
        todoService.fetch { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let todos):
                self?.todos = todos
            case .failure(let error):
                self?.error = error
            }
        }
    }
    
    func addTodo(title: String) {
        let todo = TodoItem(id: UUID().uuidString, title: title, isCompleted: false, createdDate: Date())
        todos.append(todo)
    }
    
    func toggleComplete(at index: Int) {
        todos[index].isCompleted.toggle()
    }
    
    func delete(at index: Int) {
        todos.remove(at: index)
    }
}

class TodoViewController: UITableViewController {
    var viewModel: TodoViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.loadTodos()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.todos.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoCell
        if let todo = viewModel?.todos[indexPath.row] {
            cell.configure(with: todo)
        }
        return cell
    }
}
```

---

## Implementation with SwiftUI

### SwiftUI MVVM Pattern

```swift
struct User {
    let id: Int
    let name: String
    let email: String
}

class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Boolean = false
    @Published var error: Error?
    
    let userService: UserService
    
    init(userService: UserService) {
        self.userService = userService
    }
    
    func loadUsers() {
        isLoading = true
        userService.fetchUsers { [weak self] result in
            self?.isLoading = false
            switch result {
            case .success(let users):
                self?.users = users
            case .failure(let error):
                self?.error = error
            }
        }
    }
}

struct UserListView: View {
    @StateObject var viewModel: UserViewModel
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
            } else {
                ForEach(viewModel.users, id: \.id) { user in
                    UserRow(user: user)
                }
            }
        }
        .onAppear {
            viewModel.loadUsers()
        }
    }
}

struct UserRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(user.name).font(.headline)
            Text(user.email).font(.caption)
        }
    }
}
```

---

## Advantages

### ✅ Pros

```swift
// 1. Highly testable - ViewModel has no UI dependencies
let viewModel = LoginViewModel()
viewModel.email = "test@example.com"
assert(viewModel.emailError == nil)

// 2. Clear separation of concerns
// - Model: Business logic
// - ViewModel: UI logic
// - View: Pure UI

// 3. Reusable ViewModels
// Can test same ViewModel across platforms

// 4. Better state management
// All state in ViewModel, easy to reason about

// 5. Enables reactive programming
// Works perfectly with Combine/SwiftUI
```

---

## Disadvantages

### ❌ Cons

```swift
// 1. More boilerplate code
// Need both View and ViewController, both ViewModel

// 2. Can be overkill for simple screens
// Too much structure for trivial UI

// 3. Data binding can be complex
// Manual updates or Combine subscription management

// 4. Learning curve steeper than MVC
// More concepts to understand

// 5. Requires clear communication between layers
// Can become complicated if not done carefully
```

---

## 🎯 Best Practices

### 1. ViewModel Should Not Reference View
```swift
// ❌ WRONG: ViewModel knows about UIViewController
class BadViewModel {
    weak var viewController: UIViewController?
}

// ✅ CORRECT: ViewModel is independent
class GoodViewModel {
    @Published var displayText: String = ""
}
```

### 2. Use Reactive Bindings
```swift
// ✅ Combine for automatic updates
@Published var text: String = ""

// ✅ SwiftUI with @Published
@StateObject var viewModel: ViewModel
```

### 3. Keep ViewModels Focused
```swift
// ✅ Single responsibility
class UserEditViewModel {
    // Only handles editing logic
}

// ❌ Too many responsibilities
class AllUserViewModel {
    // Edit, list, search, settings...
}
```

---

## ❌ Common Mistakes

### Mistake 1: ViewModel References View

**WRONG:**
```swift
class UserViewModel {
    weak var controller: UIViewController?  // ❌
}
```

**CORRECT:**
```swift
class UserViewModel {
    @Published var displayName: String = ""  // ✅
}
```

---

### Mistake 2: Complex Binding Logic

**WRONG:**
```swift
// ❌ Hard to understand binding
textField.text = viewModel.something.formatted
```

**CORRECT:**
```swift
// ✅ Clear property
var displayText: String {
    return viewModel.something.formatted
}
```

---

## Related Topics

- [MVC](mvc.md)
- [VIPER](viper.md)
- [Reactive Programming with Combine](../../07-advanced/advanced-performance/combine.md)

---

**Use MVVM for better testability and reactive programming!**
