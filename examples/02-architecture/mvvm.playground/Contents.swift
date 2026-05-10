import Foundation

// ============================================================================
// MVVM ARCHITECTURE IN SWIFT - Complete Playground Guide
// Corresponds to: 02-architecture/software-architecture/mvvm.md
// ============================================================================

// SECTION 1: MVVM Structure Overview
// ============================================================================

print("=== MVVM ARCHITECTURE ===\n")
print("Components:")
print("- Model: Data and business logic")
print("- View: UI display (doesn't access model directly)")
print("- ViewModel: Transforms model data for view, handles user actions")
print()


// SECTION 2: Model Layer
// ============================================================================

print("=== MODEL LAYER ===\n")

// ✅ Simple, reusable model
struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let isActive: Bool
    
    func isValidEmail() -> Bool {
        return email.contains("@") && email.contains(".")
    }
}

struct UserListResponse: Codable {
    let users: [User]
    let totalCount: Int
}

// Simulated data service
class UserService {
    func fetchUsers() -> [User] {
        // Simulated API call
        return [
            User(id: 1, name: "Alice", email: "alice@example.com", isActive: true),
            User(id: 2, name: "Bob", email: "bob@example.com", isActive: true),
            User(id: 3, name: "Charlie", email: "charlie@example.com", isActive: false)
        ]
    }
}


// SECTION 3: ViewModel Layer
// ============================================================================

print("=== VIEWMODEL LAYER ===\n")

// ✅ ViewModel transforms model data for UI
class UserListViewModel {
    // MARK: - Public interface (what View observes)
    var displayedUsers: [UserDisplayItem] = [] {
        didSet {
            onUsersUpdated?()
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            onLoadingChanged?()
        }
    }
    
    var errorMessage: String? {
        didSet {
            onErrorOccurred?()
        }
    }
    
    // MARK: - Callbacks (View observes these)
    var onUsersUpdated: (() -> Void)?
    var onLoadingChanged: (() -> Void)?
    var onErrorOccurred: (() -> Void)?
    
    // MARK: - Private
    private let userService: UserService
    private var allUsers: [User] = []
    
    // MARK: - Init
    init(userService: UserService) {
        self.userService = userService
    }
    
    // MARK: - Public methods (called from View)
    func loadUsers() {
        isLoading = true
        errorMessage = nil
        
        // Simulated async operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            do {
                let users = self?.userService.fetchUsers() ?? []
                self?.allUsers = users
                self?.transformAndDisplay(users)
                self?.isLoading = false
            } catch {
                self?.errorMessage = "Failed to load users"
                self?.isLoading = false
            }
        }
    }
    
    func filterActiveUsers() {
        let active = allUsers.filter { $0.isActive }
        transformAndDisplay(active)
    }
    
    func filterAllUsers() {
        transformAndDisplay(allUsers)
    }
    
    func getUserDetail(at index: Int) -> User? {
        guard index >= 0 && index < displayedUsers.count else { return nil }
        let displayItem = displayedUsers[index]
        return allUsers.first { $0.id == displayItem.userId }
    }
    
    // MARK: - Private methods
    private func transformAndDisplay(_ users: [User]) {
        displayedUsers = users.map { user in
            UserDisplayItem(
                userId: user.id,
                displayName: user.name.uppercased(),
                displayEmail: user.email,
                statusText: user.isActive ? "✅ Active" : "❌ Inactive",
                statusColor: user.isActive ? "green" : "red"
            )
        }
    }
}

// ✅ Display model (UI-specific representation)
struct UserDisplayItem {
    let userId: Int
    let displayName: String
    let displayEmail: String
    let statusText: String
    let statusColor: String
}


// SECTION 4: View Layer
// ============================================================================

print("=== VIEW LAYER ===\n")

// Simulating a View Controller
class UserListViewController {
    private let viewModel: UserListViewModel
    
    // MARK: - Init
    init(viewModel: UserListViewModel) {
        self.viewModel = viewModel
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // ✅ View observes ViewModel changes
        viewModel.onUsersUpdated = { [weak self] in
            self?.updateUI()
        }
        
        viewModel.onLoadingChanged = { [weak self] in
            self?.updateLoadingState()
        }
        
        viewModel.onErrorOccurred = { [weak self] in
            self?.showError()
        }
    }
    
    // MARK: - User actions (called from UI)
    func onViewDidLoad() {
        print("👁️ View loaded - triggering viewModel.loadUsers()")
        viewModel.loadUsers()
    }
    
    func onFilterButtonTapped(isActive: Bool) {
        print("👆 Filter button tapped")
        if isActive {
            viewModel.filterActiveUsers()
        } else {
            viewModel.filterAllUsers()
        }
    }
    
    // MARK: - UI Updates (respond to ViewModel changes)
    private func updateUI() {
        print("🎨 Updating UI with \(viewModel.displayedUsers.count) users:")
        for (index, user) in viewModel.displayedUsers.enumerated() {
            print("  \(index + 1). \(user.displayName) (\(user.statusText))")
        }
    }
    
    private func updateLoadingState() {
        if viewModel.isLoading {
            print("⏳ Loading...")
        } else {
            print("✅ Loading complete")
        }
    }
    
    private func showError() {
        if let error = viewModel.errorMessage {
            print("⚠️ Error: \(error)")
        }
    }
}


// SECTION 5: Using MVVM
// ============================================================================

print("=== USING MVVM ===\n")

// Create dependencies
let userService = UserService()

// Create ViewModel
let viewModel = UserListViewModel(userService: userService)

// Create ViewController and pass ViewModel
let viewController = UserListViewController(viewModel: viewModel)

// Simulate user interactions
print("1️⃣ User loads view:")
viewController.onViewDidLoad()

// Wait for simulated async operation
usleep(600000)  // 0.6 seconds

print("\n2️⃣ User filters active users:")
viewController.onFilterButtonTapped(isActive: true)

print("\n3️⃣ User shows all users:")
viewController.onFilterButtonTapped(isActive: false)


// SECTION 6: MVVM with Reactive Binding
// ============================================================================

print("\n=== MVVM WITH REACTIVE BINDING ===\n")

// Simple observable wrapper
class Observable<T> {
    typealias Observer = (T) -> Void
    private var observers: [Observer] = []
    
    var value: T {
        didSet {
            notifyObservers()
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    func subscribe(_ observer: @escaping Observer) {
        observer(value)  // Notify immediately with current value
        observers.append(observer)
    }
    
    private func notifyObservers() {
        observers.forEach { $0(value) }
    }
}

// ✅ Reactive ViewModel using Observable
class ReactiveUserListViewModel {
    let users = Observable<[UserDisplayItem]>([])
    let isLoading = Observable<Bool>(false)
    let errorMessage = Observable<String?>(nil)
    
    private let userService: UserService
    
    init(userService: UserService) {
        self.userService = userService
    }
    
    func loadUsers() {
        isLoading.value = true
        errorMessage.value = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let fetchedUsers = self?.userService.fetchUsers() ?? []
            let displayItems = fetchedUsers.map { user in
                UserDisplayItem(
                    userId: user.id,
                    displayName: user.name.uppercased(),
                    displayEmail: user.email,
                    statusText: user.isActive ? "✅ Active" : "❌ Inactive",
                    statusColor: user.isActive ? "green" : "red"
                )
            }
            self?.users.value = displayItems
            self?.isLoading.value = false
        }
    }
}

// Using reactive ViewModel
let reactiveViewModel = ReactiveUserListViewModel(userService: userService)

print("Setting up observers...")
reactiveViewModel.users.subscribe { users in
    print("📋 Users updated: \(users.count) users")
}

reactiveViewModel.isLoading.subscribe { isLoading in
    print("⏳ Loading state: \(isLoading)")
}

print("\nCalling loadUsers()...")
reactiveViewModel.loadUsers()
usleep(400000)  // Wait for async operation


// SECTION 7: Common Mistakes (Anti-patterns)
// ============================================================================

print("\n=== COMMON MISTAKES ===\n")

// ❌ MISTAKE 1: ViewModel accessing UIView directly
print("❌ MISTAKE 1: ViewModel with UI imports")
class BadViewModel {
    // ⚠️ Never do this!
    // import UIKit
    // let label: UILabel? = nil
    // var textView: UITextView?
    
    print("(ViewModel should not reference UI components)")
}

// ✅ CORRECT: ViewModel is UI-agnostic
class GoodViewModel {
    // ✅ Only data and logic
    var displayText: String = ""
    var isEnabled: Bool = true
}

// ❌ MISTAKE 2: View directly accessing Model
print("\n❌ MISTAKE 2: View accessing Model")
class BadViewController {
    let user: User? = nil
    
    func displayUser() {
        // ⚠️ View should not access Model directly
        // label.text = user?.name  // BAD!
        print("(View should use ViewModel)")
    }
}

// ✅ CORRECT: View uses ViewModel
class GoodViewController {
    let viewModel: UserListViewModel
    
    init(viewModel: UserListViewModel) {
        self.viewModel = viewModel
    }
    
    func displayUser() {
        // ✅ View accesses ViewModel
        for user in viewModel.displayedUsers {
            print("Display: \(user.displayName)")
        }
    }
}

// ❌ MISTAKE 3: God ViewModel (too much responsibility)
print("\n❌ MISTAKE 3: Over-loaded ViewModel")
class GodViewModel {
    // ⚠️ Too much responsibility
    func fetchUsers() {}
    func fetchPosts() {}
    func fetchComments() {}
    func validateEmail() {}
    func sendAnalytics() {}
    func openWebView() {}
    print("(Separate into multiple ViewModels)")
}

// ✅ CORRECT: Single responsibility
class UserViewModel {
    func loadUsers() {}
    func filterUsers() {}
}

class PostViewModel {
    func loadPosts() {}
}


// SECTION 8: Best Practices
// ============================================================================

print("\n=== BEST PRACTICES ===\n")

// ✅ PRACTICE 1: ViewModel should be testable
print("✅ PRACTICE 1: Testable ViewModel")
class TestableViewModel {
    let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func loadData() {
        let users = repository.fetchUsers()
        print("Loaded: \(users.count) users")
    }
}

protocol UserRepository {
    func fetchUsers() -> [User]
}

class MockUserRepository: UserRepository {
    func fetchUsers() -> [User] {
        return [User(id: 1, name: "Test", email: "test@test.com", isActive: true)]
    }
}

// Easy to test
let testVM = TestableViewModel(repository: MockUserRepository())
testVM.loadData()

// ✅ PRACTICE 2: Use dependency injection
print("\n✅ PRACTICE 2: Dependency Injection in ViewModel")
class InjectedViewModel {
    let service: UserService
    let logger: Logger
    
    init(service: UserService, logger: Logger) {
        self.service = service
        self.logger = logger
    }
}

protocol Logger {
    func log(_ message: String)
}

// ✅ PRACTICE 3: Clear input/output interfaces
print("\n✅ PRACTICE 3: Clear interface")
class ClearViewModel {
    // Input (from View)
    func onLoadTapped() {}
    func onFilterChanged(filter: String) {}
    
    // Output (to View)
    var displayItems: Observable<[UserDisplayItem]> = Observable([])
    var isLoading: Observable<Bool> = Observable(false)
}

// ✅ PRACTICE 4: Separate presentation logic from business logic
print("\n✅ PRACTICE 4: Separated concerns")
class PresentationViewModel {
    // Business logic (could be in separate service)
    private func calculateDiscount(_ price: Double) -> Double {
        return price * 0.9
    }
    
    // Presentation logic (formatting for UI)
    func formatPrice(_ price: Double) -> String {
        let discounted = calculateDiscount(price)
        return String(format: "$%.2f", discounted)
    }
}


print("\n=== END OF MVVM PLAYGROUND ===")
