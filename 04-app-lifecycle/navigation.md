# Navigation and Routing - Controllers, Storyboards, and Navigation Stack

## Overview

Navigation manages transitions between screens using navigation controllers, storyboards, segues, or programmatic navigation. Understanding navigation patterns ensures smooth app flow.

## Main Topics

- [Navigation Basics](#navigation-basics)
- [Navigation Controller](#navigation-controller)
- [Segues](#segues)
- [Programmatic Navigation](#programmatic-navigation)
- [Navigation State Management](#navigation-state-management)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [UINavigationController](https://developer.apple.com/documentation/uikit/uinavigationcontroller)

---

## Navigation Basics

### Navigation Stack Concept

```swift
// Navigation is a stack of view controllers
// Root ViewController (index 0) - always present
// ViewController 2 (index 1)
// ViewController 3 (index 2) - current, on top

// Push: Adds VC to stack (go forward)
// Pop: Removes VC from stack (go back)
// Pop to root: Back to first VC

// Array visualization:
// [RootVC, VC2, VC3] ← VC3 is displayed
// After pop:
// [RootVC, VC2] ← VC2 is displayed
```

### Navigation Controller Setup

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create root view controller
        let rootVC = HomeViewController()
        
        // Wrap in navigation controller
        let navController = UINavigationController(rootViewController: rootVC)
        
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        return true
    }
}
```

---

## Navigation Controller

### Basic Navigation

```swift
import UIKit

class HomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Home"
        
        // Add button
        let button = UIButton(type: .system)
        button.setTitle("Go to Details", for: .normal)
        button.addTarget(self, action: #selector(showDetails), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func showDetails() {
        let detailVC = DetailViewController()
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

class DetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Details"
        
        // Back button added automatically
        
        let button = UIButton(type: .system)
        button.setTitle("Go Back", for: .normal)
        button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
}
```

### Customizing Navigation Bar

```swift
import UIKit

class CustomNavBarViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Title
        title = "Custom Navigation"
        
        // Navigation bar appearance
        navigationController?.navigationBar.barTintColor = .systemBlue
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        
        // Large title
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        
        // Custom buttons
        let rightButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(rightButtonTapped)
        )
        navigationItem.rightBarButtonItem = rightButton
        
        let leftButton = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(leftButtonTapped)
        )
        navigationItem.leftBarButtonItem = leftButton
    }
    
    @objc func rightButtonTapped() {
        print("Right button tapped")
    }
    
    @objc func leftButtonTapped() {
        print("Left button tapped")
    }
}
```

### Pop to Root

```swift
class DeepDetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Deep Detail"
        
        let button = UIButton(type: .system)
        button.setTitle("Back to Home", for: .normal)
        button.addTarget(self, action: #selector(backToRoot), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func backToRoot() {
        // Pop to first view controller
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func backToSpecificVC() {
        // Pop to specific view controller
        if let targetVC = navigationController?.viewControllers.first(where: { $0 is DetailViewController }) {
            navigationController?.popToViewController(targetVC, animated: true)
        }
    }
}
```

---

## Segues

### Storyboard Segues

```swift
// In Storyboard:
// 1. Control-drag from button to destination VC
// 2. Select segue type (push, modal, etc.)
// 3. Give segue an identifier: "showDetails"

class ViewController: UIViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            if let detailVC = segue.destination as? DetailViewController {
                detailVC.itemID = 123
                detailVC.itemName = "Sample Item"
            }
        }
    }
    
    @IBAction func showDetailsTapped(_ sender: Any) {
        performSegue(withIdentifier: "showDetails", sender: self)
    }
}

class DetailViewController: UIViewController {
    var itemID: Int?
    var itemName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = itemName
        print("Displaying item: \(itemID ?? 0)")
    }
}
```

### Unwind Segues

```swift
// Unwind segue allows returning without explicit reference

class DetailViewController: UIViewController {
    @IBAction func saveTapped(_ sender: Any) {
        performSegue(withIdentifier: "unwindToHome", sender: self)
    }
}

class HomeViewController: UIViewController {
    // This method receives unwind segue
    @IBAction func unwindToHome(_ unwindSegue: UIStoryboardSegue) {
        if let detailVC = unwindSegue.source as? DetailViewController {
            print("Returned from detailVC")
        }
    }
}
```

---

## Programmatic Navigation

### Navigation Without Storyboards

```swift
import UIKit

// App structure
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create navigation-based app
        let rootVC = ListViewController()
        let navController = UINavigationController(rootViewController: rootVC)
        
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        return true
    }
}

class ListViewController: UITableViewController {
    var items = ["Item 1", "Item 2", "Item 3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Items"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = DetailViewController()
        detailVC.item = items[indexPath.row]
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

class DetailViewController: UIViewController {
    var item: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = item
        view.backgroundColor = .white
    }
}
```

### Tab Bar Navigation

```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create tab bar controller
        let tabController = UITabBarController()
        
        // Create tabs
        let homeVC = UIViewController()
        homeVC.title = "Home"
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        let homeNav = UINavigationController(rootViewController: homeVC)
        
        let settingsVC = UIViewController()
        settingsVC.title = "Settings"
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 1)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        
        tabController.viewControllers = [homeNav, settingsNav]
        
        window?.rootViewController = tabController
        window?.makeKeyAndVisible()
        
        return true
    }
}
```

---

## Navigation State Management

### Passing Data Forward

```swift
class ViewController: UIViewController {
    @objc func showDetails() {
        let detailVC = DetailViewController()
        
        // Pass data
        detailVC.user = User(id: 1, name: "John")
        detailVC.delegate = self
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

class DetailViewController: UIViewController {
    var user: User?
    weak var delegate: DetailViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = user {
            title = user.name
        }
    }
}

protocol DetailViewControllerDelegate: AnyObject {
    func detailViewControllerDidSave(_ data: String)
}
```

### Using Notification for Communication

```swift
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataChanged),
            name: NSNotification.Name("DataChanged"),
            object: nil
        )
    }
    
    @objc func handleDataChanged() {
        print("Data changed from another view controller")
        refreshUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

class EditViewController: UIViewController {
    @objc func saveTapped() {
        NotificationCenter.default.post(name: NSNotification.Name("DataChanged"), object: nil)
        navigationController?.popViewController(animated: true)
    }
}
```

---

## 🎯 Best Practices

### 1. Use Navigation Controller for Hierarchical Apps
```swift
// ✅ Navigation controller for linear flow
let navController = UINavigationController(rootViewController: rootVC)

// ✅ Tab bar controller for multiple sections
let tabController = UITabBarController()
```

### 2. Pass Data Explicitly
```swift
// ✅ Clear data passing
let detailVC = DetailViewController()
detailVC.itemID = itemID
navigationController?.pushViewController(detailVC, animated: true)

// ❌ Unclear data flow
// Global variables or singletons
```

### 3. Handle Back Navigation
```swift
// ✅ Custom back behavior
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // Check if popped
    if isMovingFromParent {
        saveState()
    }
}
```

---

## ❌ Common Mistakes

### Mistake 1: Creating Navigation Controller Multiple Times

**WRONG:**
```swift
// ❌ Creates new navigation hierarchy
let navController = UINavigationController(rootViewController: newVC)
self.navigationController?.present(navController, animated: true)
```

**CORRECT:**
```swift
// ✅ Use existing navigation controller
let newVC = NewViewController()
self.navigationController?.pushViewController(newVC, animated: true)
```

---

### Mistake 2: Not Passing Data Properly

**WRONG:**
```swift
// ❌ Data lost between transitions
let detailVC = DetailViewController()
navigationController?.pushViewController(detailVC, animated: true)
// Set data after push (too late)
detailVC.data = someData
```

**CORRECT:**
```swift
// ✅ Pass data before push
let detailVC = DetailViewController()
detailVC.data = someData
navigationController?.pushViewController(detailVC, animated: true)
```

---

### Mistake 3: Memory Leak in Navigation

**WRONG:**
```swift
// ❌ Retain cycle
let detailVC = DetailViewController()
detailVC.callback = {
    self.updateUI()  // Strong reference
}
navigationController?.pushViewController(detailVC, animated: true)
```

**CORRECT:**
```swift
// ✅ Weak reference
let detailVC = DetailViewController()
detailVC.callback = { [weak self] in
    self?.updateUI()
}
navigationController?.pushViewController(detailVC, animated: true)
```

---

## Related Topics

- [UIViewController Lifecycle](uiviewcontroller-lifecycle.md)
- [UITableView](tableview.md)
- [Segues and Storyboards](storyboards.md)

---

**Master navigation to create smooth, intuitive app flows!**
