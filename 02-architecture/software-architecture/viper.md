# VIPER Architecture

## Overview

VIPER (View-Interactor-Presenter-Entity-Router) is an enterprise-grade architectural pattern that maximizes testability, maintainability, and modularity by strictly separating concerns across five components. It's ideal for large, complex applications with multiple teams.

## Main Topics

- [VIPER Concepts](#viper-concepts)
- [Components](#components)
- [Communication Flow](#communication-flow)
- [Implementation](#implementation)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [iOS Architecture Patterns](https://medium.com/ios-os-x-development/ios-architecture-patterns-ecba4c38de52)

---

## VIPER Concepts

### The Five Layers

```swift
// VIPER separates concerns into 5 distinct layers

// 1. VIEW - Displays data, captures user input
// 2. INTERACTOR - Business logic, API calls
// 3. PRESENTER - Formats data for view
// 4. ENTITY - Models and data structures
// 5. ROUTER - Navigation and module assembly

// Typical flow:
User tap → View → Presenter → Interactor → Presenter → View
```

### Module Structure

```swift
// UserModule/
//   ├── UserViewController.swift      (VIEW)
//   ├── UserPresenter.swift            (PRESENTER)
//   ├── UserInteractor.swift           (INTERACTOR)
//   ├── UserEntity.swift               (ENTITY)
//   ├── UserRouter.swift               (ROUTER)
//   ├── UserContracts.swift            (PROTOCOLS)
//   └── UserAssembly.swift             (FACTORY)
```

---

## Components

### Entity

```swift
// Pure data models - no business logic
struct User {
    let id: Int
    let name: String
    let email: String
    let phoneNumber: String?
}

// Codable for API integration
struct UserResponse: Codable {
    let id: Int
    let name: String
    let email: String
    let phone: String?
}
```

### View (UIViewController)

```swift
class UserViewController: UIViewController {
    // MARK: - Properties
    var presenter: UserPresenterInput?
    
    // MARK: - IBOutlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter?.loadUser()
    }
    
    // MARK: - Actions
    @IBAction func editButtonTapped() {
        presenter?.navigateToEdit()
    }
}

// MARK: - Presenter Output
extension UserViewController: UserPresenterOutput {
    func displayUser(_ user: UserViewModel) {
        nameLabel.text = user.name
        emailLabel.text = user.email
    }
    
    func displayError(_ error: String) {
        showAlert(title: "Error", message: error)
    }
}
```

### Presenter

```swift
class UserPresenter {
    // MARK: - Properties
    weak var view: UserPresenterOutput?
    var interactor: UserInteractorInput?
    var router: UserRouterInput?
    
    // MARK: - User interactions
    func loadUser() {
        interactor?.fetchUser()
    }
    
    func navigateToEdit() {
        router?.navigateToEdit()
    }
}

// MARK: - Interactor Output (callback)
extension UserPresenter: UserInteractorOutput {
    func didFetchUser(_ user: User) {
        let viewModel = UserViewModel(from: user)
        view?.displayUser(viewModel)
    }
    
    func didFailWithError(_ error: Error) {
        view?.displayError(error.localizedDescription)
    }
}

// MARK: - ViewModel for View
struct UserViewModel {
    let name: String
    let email: String
    
    init(from user: User) {
        self.name = user.name
        self.email = user.email
    }
}
```

### Interactor

```swift
class UserInteractor {
    // MARK: - Dependencies
    weak var presenter: UserInteractorOutput?
    var userService: UserService?
    
    // MARK: - Public methods
    func fetchUser() {
        userService?.getUser { [weak self] result in
            switch result {
            case .success(let user):
                self?.presenter?.didFetchUser(user)
            case .failure(let error):
                self?.presenter?.didFailWithError(error)
            }
        }
    }
}
```

### Router

```swift
class UserRouter {
    weak var viewController: UserViewController?
    
    static func createModule() -> UIViewController {
        let view = UserViewController()
        let presenter = UserPresenter()
        let interactor = UserInteractor()
        let router = UserRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        interactor.userService = UserService()
        router.viewController = view
        
        return view
    }
    
    func navigateToEdit() {
        let editModule = UserEditRouter.createModule()
        viewController?.navigationController?.pushViewController(editModule, animated: true)
    }
}
```

### Contracts (Protocols)

```swift
// MARK: - Presenter → View
protocol UserPresenterOutput: AnyObject {
    func displayUser(_ user: UserViewModel)
    func displayError(_ error: String)
}

// MARK: - View → Presenter
protocol UserPresenterInput {
    func loadUser()
    func navigateToEdit()
}

// MARK: - Interactor → Presenter
protocol UserInteractorOutput: AnyObject {
    func didFetchUser(_ user: User)
    func didFailWithError(_ error: Error)
}

// MARK: - Presenter → Interactor
protocol UserInteractorInput {
    func fetchUser()
}

// MARK: - Presenter → Router
protocol UserRouterInput {
    func navigateToEdit()
}
```

---

## Communication Flow

### Complete Cycle

```swift
// 1. User taps button
@IBAction func saveButtonTapped() {
    presenter?.saveUser(name: nameField.text ?? "")
}

// 2. Presenter receives action
func saveUser(name: String) {
    let user = User(name: name, email: email)
    interactor?.saveUser(user)
}

// 3. Interactor does business logic
func saveUser(_ user: User) {
    userService?.save(user) { [weak self] result in
        if case .success = result {
            self?.presenter?.didSaveSuccessfully()
        }
    }
}

// 4. Presenter formats result
func didSaveSuccessfully() {
    view?.showSuccess("User saved")
}

// 5. View displays result
func showSuccess(_ message: String) {
    showAlert(title: "Success", message: message)
}
```

---

## Implementation

### Complete Example: User List

```swift
// MARK: - Entity
struct UserListItem {
    let id: Int
    let name: String
}

// MARK: - View
class UserListViewController: UITableViewController {
    var presenter: UserListPresenterInput?
    var users: [UserListViewModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter?.loadUsers()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        cell.textLabel?.text = users[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter?.selectUser(at: indexPath.row)
    }
}

extension UserListViewController: UserListPresenterOutput {
    func displayUsers(_ users: [UserListViewModel]) {
        self.users = users
        tableView.reloadData()
    }
    
    func displayError(_ message: String) {
        showAlert(title: "Error", message: message)
    }
}

// MARK: - Presenter
class UserListPresenter {
    weak var view: UserListPresenterOutput?
    var interactor: UserListInteractorInput?
    var router: UserListRouterInput?
    
    func loadUsers() {
        interactor?.fetchUsers()
    }
    
    func selectUser(at index: Int) {
        router?.navigateToDetail(index: index)
    }
}

extension UserListPresenter: UserListInteractorOutput {
    func didFetchUsers(_ users: [UserListItem]) {
        let viewModels = users.map { UserListViewModel(name: $0.name) }
        view?.displayUsers(viewModels)
    }
}

// MARK: - Interactor
class UserListInteractor {
    weak var presenter: UserListInteractorOutput?
    var service: UserService?
    
    func fetchUsers() {
        service?.getUsers { [weak self] result in
            switch result {
            case .success(let users):
                self?.presenter?.didFetchUsers(users)
            case .failure(let error):
                self?.presenter?.didFailWithError(error)
            }
        }
    }
}

// MARK: - Router
class UserListRouter {
    weak var viewController: UserListViewController?
    
    static func createModule() -> UIViewController {
        let view = UserListViewController()
        let presenter = UserListPresenter()
        let interactor = UserListInteractor()
        let router = UserListRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        interactor.service = UserService()
        router.viewController = view
        
        return UINavigationController(rootViewController: view)
    }
    
    func navigateToDetail(index: Int) {
        let detailModule = UserRouter.createModule()
        viewController?.navigationController?.pushViewController(detailModule, animated: true)
    }
}
```

---

## Advantages

### ✅ Pros

```swift
// 1. Maximum testability
// Each component can be tested independently
class UserPresenterTests: XCTestCase {
    func testLoadUser() {
        let presenter = UserPresenter()
        let mockView = MockUserView()
        presenter.view = mockView
        
        presenter.loadUser()
        
        XCTAssertTrue(mockView.displayUserCalled)
    }
}

// 2. Clear separation of concerns
// Easy to understand who does what

// 3. Reusable components
// Presenters/Interactors work across platforms

// 4. Scalable for large teams
// Different people can work on different components

// 5. Easy to add/modify features
// Changes isolated to specific layers
```

---

## Disadvantages

### ❌ Cons

```swift
// 1. Introduction overhead
// Lots of boilerplate code
// Assembly/wiring complex

// 2. Overkill for simple screens
// Simple form needs 5+ files

// 3. Learning curve
// Multiple layers to understand

// 4. More files to manage
// UserViewController, UserPresenter, UserInteractor, UserRouter, UserContracts...

// 5. Protocol heavy
// Every interaction needs protocol definition
```

---

## 🎯 Best Practices

### 1. One Module Per Screen
```swift
// UserDetailModule/
// EditUserModule/
// UserListModule/
// Each self-contained
```

### 2. Use Factories for Assembly
```swift
static func createModule() -> UIViewController {
    // All wiring in one place
}
```

### 3. Keep Entities Simple
```swift
// Pure data, no logic
struct User {
    let id: Int
    let name: String
}
```

### 4. Protocol Everything
```swift
// Makes testing and mocking easier
protocol UserPresenterInput { }
protocol UserPresenterOutput: AnyObject { }
```

---

## ❌ Common Mistakes

### Mistake 1: Massive Presenter

**WRONG:**
```swift
// ❌ Presenter doing too much
class UserPresenter {
    func loadUser() { }
    func formatDate() { }
    func validateEmail() { }
    func calculateAge() { }
    // ...
}
```

**CORRECT:**
```swift
// ✅ Focused responsibility
class UserPresenter {
    func loadUser() { }
    func displayUser() { }
}
```

---

## Related Topics

- [MVC](mvc.md)
- [MVVM](mvvm.md)
- [Design Patterns](design-patterns.md)

---

**Use VIPER for large, team-based, highly testable applications!**
