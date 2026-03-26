# Model-View-Controller (MVC)

## Overview

MVC is a foundational architectural pattern that separates an application into three interconnected components: Model (data/logic), View (UI presentation), and Controller (input handling). It's the default pattern in UIKit and remains effective for many applications.

## Main Topics

- [MVC Concepts](#mvc-concepts)
- [Components](#components)
- [Data Flow](#data-flow)
- [Implementation](#implementation)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Apple: MVC Architecture](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/ModelViewController/ModelViewController.html)

---

## MVC Concepts

### The Three Components

```swift
// MODEL - Data and business logic
class User {
    let id: Int
    var name: String
    var email: String
    
    func isValidEmail() -> Bool {
        return email.contains("@")
    }
}

// VIEW - UI presentation only
class UserView: UIView {
    let nameLabel = UILabel()
    let emailLabel = UILabel()
    
    func displayUser(_ user: User) {
        nameLabel.text = user.name
        emailLabel.text = user.email
    }
}

// CONTROLLER - Coordinates Model and View
class UserViewController: UIViewController {
    var user: User?
    let userView = UserView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = user {
            userView.displayUser(user)
        }
    }
}
```

### Key Principle: Separation of Concerns

```swift
// ✅ GOOD: Each component has one responsibility
class Product {
    // MODEL: Just data and business logic
    let id: Int
    let name: String
    let price: Double
    
    func applyDiscount(_ percent: Double) -> Double {
        return price * (1 - percent / 100)
    }
}

class ProductCell: UITableViewCell {
    // VIEW: Just UI
    let nameLabel = UILabel()
    let priceLabel = UILabel()
    
    func configure(with product: Product) {
        nameLabel.text = product.name
        priceLabel.text = "$\(product.price)"
    }
}

class ProductViewController: UIViewController, UITableViewDelegate {
    // CONTROLLER: Coordinates model and view
    var products: [Product] = []
    let tableView = UITableView()
    
    func loadProducts() {
        products = fetchFromAPI()
        tableView.reloadData()
    }
}

// ❌ BAD: View has business logic
class BadProductCell: UITableViewCell {
    // ❌ Business logic mixed in View
    func configureWithPrice(_ price: Double) {
        let discounted = price * 0.9  // Business logic!
        let text = String(format: "$%.2f", discounted)
        label.text = text
    }
}
```

---

## Components

### Model Layer

```swift
// Pure data structures and business logic
class Order {
    let id: String
    let items: [OrderItem]
    let customerID: String
    let createdDate: Date
    
    // Business logic
    var total: Double {
        return items.reduce(0) { $0 + $1.price * Double($1.quantity) }
    }
    
    var taxAmount: Double {
        return total * 0.1  // 10% tax
    }
    
    var grandTotal: Double {
        return total + taxAmount
    }
    
    func isExpired() -> Bool {
        return Date().timeIntervalSince(createdDate) > 3600 * 24 * 30
    }
    
    func canBeCancelled() -> Bool {
        return !isExpired() && createdDate.timeIntervalSinceNow > -3600
    }
}

struct OrderItem {
    let productID: String
    let price: Double
    let quantity: Int
}
```

### View Layer

```swift
// Pure UI - no logic
class OrderView: UIView {
    let itemsTableView = UITableView()
    let totalLabel = UILabel()
    let taxLabel = UILabel()
    let grandTotalLabel = UILabel()
    
    func displayOrder(_ order: Order) {
        totalLabel.text = String(format: "$%.2f", order.total)
        taxLabel.text = String(format: "$%.2f", order.taxAmount)
        grandTotalLabel.text = String(format: "$%.2f", order.grandTotal)
    }
}
```

### Controller Layer

```swift
// Coordinates Model and View
class OrderViewController: UIViewController {
    var order: Order?
    let orderView = OrderView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load from model
        fetchOrder { [weak self] order in
            self?.order = order
            
            // Update view
            self?.orderView.displayOrder(order)
        }
    }
    
    @IBAction func cancelButtonTapped() {
        guard let order = order, order.canBeCancelled() else {
            showError("Cannot cancel this order")
            return
        }
        
        // Update model
        cancelOrder(order)
        
        // Update view
        showSuccess("Order cancelled")
    }
    
    private func fetchOrder(completion: @escaping (Order) -> Void) {
        // Fetch from API or database
    }
    
    private func cancelOrder(_ order: Order) {
        // Make API call or update database
    }
}
```

---

## Data Flow

### Typical MVC Flow

```swift
// 1. View sends user interaction to Controller
@IBAction func submitButtonTapped() {
    // User tapped button → delegates to controller
    delegate?.didTapSubmit()
}

// 2. Controller updates Model
func didTapSubmit() {
    let user = User(
        name: nameTextField.text ?? "",
        email: emailTextField.text ?? ""
    )
    
    saveUser(user)
}

// 3. Controller queries Model
func loadUser(id: Int) {
    let user = userService.fetch(id: id)
    
    // 4. Controller updates View
    if let user = user {
        updateViewWith(user)
    }
}

// 5. View displays Model data
func updateViewWith(_ user: User) {
    nameLabel.text = user.name
    emailLabel.text = user.email
}
```

### Example: Complete User Management Flow

```swift
class UserManager {
    // MODEL: User data and business logic
    var users: [User] = []
    
    func addUser(_ user: User) {
        users.append(user)
    }
    
    func removeUser(at index: Int) {
        users.remove(at: index)
    }
}

class UserViewController: UIViewController, UITableViewDataSource {
    let userManager = UserManager()
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
    }
    
    @IBAction func addUserTapped() {
        let user = User(name: "John", email: "john@example.com")
        userManager.addUser(user)  // Update model
        tableView.reloadData()      // Update view
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userManager.users.count  // Get from model
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = userManager.users[indexPath.row]
        
        // Update view with model data
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        return cell
    }
}
```

---

## Implementation

### UIViewController + UIView

```swift
// Profile ViewController
class ProfileViewController: UIViewController {
    let profileView = ProfileView()
    let userService = UserService()
    
    var userID: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(profileView)
        loadUserProfile()
    }
    
    private func loadUserProfile() {
        guard let userID = userID else { return }
        
        userService.fetchUser(id: userID) { [weak self] user in
            DispatchQueue.main.async {
                self?.displayProfile(user)
            }
        }
    }
    
    private func displayProfile(_ user: User) {
        profileView.configure(with: user)
    }
}

// ProfileView - Pure UI
class ProfileView: UIView {
    let avatarImageView = UIImageView()
    let nameLabel = UILabel()
    let bioLabel = UILabel()
    
    func configure(with user: User) {
        nameLabel.text = user.name
        bioLabel.text = user.bio
        // Load avatar image...
    }
}
```

### UITableViewController with Custom Cells

```swift
class ProductsViewController: UITableViewController {
    var products: [Product] = []
    let productService = ProductService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProducts()
    }
    
    private func loadProducts() {
        productService.fetchAll { [weak self] products in
            self?.products = products
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductCell
        let product = products[indexPath.row]
        cell.configure(with: product)
        return cell
    }
}

class ProductCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    func configure(with product: Product) {
        nameLabel.text = product.name
        priceLabel.text = String(format: "$%.2f", product.price)
    }
}
```

---

## Advantages

### ✅ Pros

```swift
// 1. Clear separation of concerns
// - Model: Reusable across platforms
// - View: UI specific
// - Controller: Orchestration

// 2. Easy to test model independently
let user = User(name: "John", email: "john@example.com")
assert(user.isValidEmail() == true)

// 3. Familiar pattern - built into UIKit
class MyViewController: UIViewController { }

// 4. Good for simple to medium apps
// Views are tightly coupled to Controller, OK for smaller apps

// 5. Leverages UIkit's natural MVC structure
```

---

## Disadvantages

### ❌ Cons

```swift
// 1. "Massive View Controller" problem
class UserViewController: UIViewController {
    // Often ends up with 500+ lines
    // Network requests, UI logic, business logic mixed
}

// 2. View Controller is tightly coupled to View
// Hard to reuse View separately
// Hard to test View independently

// 3. Limited separation between Controller and View
// UIView updates usually require Controller changes

// 4. Difficult for complex apps
// State management becomes scattered

// 5. Testing can be tricky
// Views are hard to test without running app
```

---

## 🎯 Best Practices

### 1. Keep Controllers Lean
```swift
// Move business logic to Model
// Move UI logic to View
// Controllers only coordinate
```

### 2. Extract Reusable Views
```swift
// Create reusable UI components
class RatingView: UIView {
    // Encapsulated, testable, reusable
}
```

### 3. Use Services/Managers
```swift
// Don't put API calls directly in Controller
class UserService {
    func fetchUser(id: Int, completion: @escaping (User) -> Void) { }
}
```

### 4. Keep Models Independent
```swift
// Models should not depend on Views or Controllers
// Can be shared across platforms
```

---

## ❌ Common Mistakes

### Mistake 1: Massive View Controller

**WRONG:**
```swift
// ❌ 1000+ line ViewController
class UserViewController: UIViewController {
    // API calls, business logic, UI updates all mixed
    func viewDidLoad() {
        // Everything here
    }
}
```

**CORRECT:**
```swift
// ✅ Separate concerns
class UserService {
    func fetchUser() { }
}

class UserViewController: UIViewController {
    let userService = UserService()
    
    func viewDidLoad() {
        userService.fetchUser { [weak self] user in
            self?.updateUI(user)
        }
    }
}
```

---

## Related Topics

- [MVVM](mvvm.md)
- [VIPER](viper.md)
- [Design Patterns](design-patterns.md)

---

**Use MVC for straightforward apps with clear Model/View/Controller separation!**
