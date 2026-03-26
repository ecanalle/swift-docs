# UIViewController Lifecycle - State Management

## Overview

UIViewController lifecycle methods allow you to respond to state changes as it loads, appears, and disappears. Understanding these methods is crucial for memory management, data loading, and UI updates.

## Main Topics

- [Lifecycle Overview](#lifecycle-overview)
- [Lifecycle Methods](#lifecycle-methods)
- [Common Patterns](#common-patterns)
- [View State Transitions](#view-state-transitions)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [UIViewController Lifecycle](https://developer.apple.com/documentation/uikit/uiviewcontroller)

---

## Lifecycle Overview

### Lifecycle Sequence

```
1. init/initWithCoder
2. loadView
3. viewDidLoad        ← Load initial UI
4. viewWillAppear     ← Prepare to show
5. viewDidAppear      ← Shown on screen
6. viewWillDisappear  ← About to hide
7. viewDidDisappear   ← Hidden from screen
8. deinit             ← Memory cleanup
```

### Visual Timeline

```swift
// Initialization
┌─────────────────┐
│ init/initCoder  │  Object created
└────────┬────────┘
         │
┌────────▼────────┐
│  loadView       │  View hierarchy created
└────────┬────────┘
         │
┌────────▼────────┐
│ viewDidLoad     │  UI fully loaded, configure once
└────────┬────────┘
         │
┌────────▼────────┐
│ viewWillAppear  │  About to appear, refresh data
└────────┬────────┘
         │
┌────────▼────────┐
│ viewDidAppear   │  On screen, can animate
└────────┬────────┘
         │
    [USER INTERACTS]
         │
┌────────▼────────┐
│viewWillDisappear│  About to hide, save state
└────────┬────────┘
         │
┌────────▼────────┐
│viewDidDisappear │  Hidden, cleanup
└────────┬────────┘
         │
┌────────▼────────┐
│  deinit         │  Memory released
└─────────────────┘
```

---

## Lifecycle Methods

### Initialization Phase

```swift
import UIKit

class UserViewController: UIViewController {
    var userID: Int?
    var userName: String?
    
    // 1. Initialize view controller
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("1. init - View controller created")
    }
    
    init(userID: Int) {
        super.init(nibName: nil, bundle: nil)
        self.userID = userID
    }
    
    // 2. Create view hierarchy
    override func loadView() {
        super.loadView()
        print("2. loadView - View structure created")
        
        // Don't set frame, already set
        view.backgroundColor = .white
    }
    
    // 3. Configure after view is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        print("3. viewDidLoad - Configure UI once")
        
        title = "User Details"
        setupUI()
        setupConstraints()
        
        // Good time for: initial setup, load static data
        // Bad time for: animate views, access API ❌
    }
}
```

### Appearance Phase

```swift
class UserViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("4. viewWillAppear - Preparing to show")
        
        // Good time for:
        // - Load dynamic data
        // - Refresh from API
        // - Update UI
        // - Subscribe to notifications
        loadUserData()
        subscribeToUpdates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("5. viewDidAppear - On screen")
        
        // Good time for:
        // - Start animations
        // - Begin live streams
        // - Track analytics
        startAnimation()
        trackScreenView()
    }
    
    func loadUserData() {
        guard let userID = userID else { return }
        
        Task {
            do {
                userName = try await fetchUser(userID)
                updateUI()
            } catch {
                showError(error)
            }
        }
    }
    
    func updateUI() {
        // Update label, image, etc
    }
}
```

### Disappearance Phase

```swift
class UserViewController: UIViewController {
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("6. viewWillDisappear - About to hide")
        
        // Good time for:
        // - Save state
        // - Stop animations
        // - Pause streams
        // - Save to UserDefaults
        saveUserState()
        stopAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("7. viewDidDisappear - Hidden")
        
        // Good time for:
        // - Unsubscribe from notifications
        // - Stop timers
        // - Cancel API requests
        // - Release heavy resources
        unsubscribeFromUpdates()
        cancelPendingRequests()
    }
    
    deinit {
        print("8. deinit - Memory released")
        // Cleanup if needed
        // Usually automatic with ARC
    }
}
```

---

## Common Patterns

### Load Data Pattern

```swift
class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var data: [Item] = []
    var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }
    
    func refreshData() {
        guard !isLoading else { return }
        
        isLoading = true
        Task {
            do {
                data = try await fetchData()
                tableView.reloadData()
            } catch {
                showError(error)
            }
            isLoading = false
        }
    }
    
    func fetchData() async throws -> [Item] {
        // Fetch from API
        return []
    }
}
```

### Navigation Pattern

```swift
class DetailViewController: UIViewController {
    var itemID: Int
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI once
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Load item data each time shown
        loadItem(itemID)
    }
    
    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
    }
    
    func loadItem(_ id: Int) {
        Task {
            do {
                let item = try await fetchItem(id)
                displayItem(item)
            } catch {
                showError(error)
            }
        }
    }
    
    @objc func closeButtonTapped() {
        dismiss(animated: true)
    }
}
```

### Memory Management Pattern

```swift
class LiveDataViewController: UIViewController {
    var timer: Timer?
    var observer: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Don't start streams here
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startStreams()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopStreams()
    }
    
    func startStreams() {
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateData()
        }
        
        // Subscribe to notifications
        observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DataChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshUI()
        }
    }
    
    func stopStreams() {
        timer?.invalidate()
        timer = nil
        
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    deinit {
        stopStreams()  // Safety net
    }
}
```

---

## View State Transitions

### Modal Presentation

```swift
// Presenting view controller
class MainViewController: UIViewController {
    @IBAction func showDetailTapped() {
        let detailVC = DetailViewController()
        detailVC.modalPresentationStyle = .automatic
        present(detailVC, animated: true)
    }
    
    // viewDidAppear called again when modal dismissed
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("MainVC appeared (or modal dismissed)")
    }
}

// Presented view controller
class DetailViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DetailVC loaded")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("DetailVC appeared")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("DetailVC will disappear")
    }
}
```

### Navigation Controller Push

```swift
// Pushing new view controller
let detailVC = DetailViewController()
navigationController?.pushViewController(detailVC, animated: true)

// Lifecycle when pushing:
// DetailVC: loadView → viewDidLoad → viewWillAppear → viewDidAppear
// MainVC: viewWillDisappear → viewDidDisappear (stays in memory)

// When popping back:
// DetailVC: viewWillDisappear → viewDidDisappear → deinit
// MainVC: viewWillAppear → viewDidAppear
```

---

## 🎯 Best Practices

### 1. Place Code in Right Phase
```swift
// ✅ Static setup
override func viewDidLoad() {
    setupUI()
    setupConstraints()
}

// ✅ Dynamic refresh
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    refreshData()
}

// ❌ Wrong place
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setupUI()  // Too late, UI might flicker
}
```

### 2. Manage Resources Properly
```swift
// ✅ Start when visible
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    startTimer()
    subscribeToNotifications()
}

// ✅ Stop when hidden
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopTimer()
    unsubscribeFromNotifications()
}

// ❌ Resource leak
override func viewDidLoad() {
    super.viewDidLoad()
    startTimer()  // Continues after leaving screen
}
```

### 3. Use Weak References
```swift
// ✅ Prevent retain cycles
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    Task { [weak self] in
        let data = try await fetchData()
        self?.updateUI(with: data)
    }
}

// ❌ Retain cycle
Task {
    let data = try await fetchData()
    self.updateUI(with: data)
}
```

---

## ❌ Common Mistakes

### Mistake 1: Loading Data in viewDidLoad

**WRONG:**
```swift
// ❌ Data stale if reusing view controller
override func viewDidLoad() {
    super.viewDidLoad()
    loadUserData()  // Only called once
}
```

**CORRECT:**
```swift
// ✅ Load each time shown
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadUserData()
}
```

---

### Mistake 2: Animating in viewWillAppear

**WRONG:**
```swift
// ❌ Animation may not complete before view hidden
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    UIView.animate(withDuration: 3.0) {
        self.label.alpha = 1
    }
}
```

**CORRECT:**
```swift
// ✅ Animate after visible
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    UIView.animate(withDuration: 0.5) {
        self.label.alpha = 1
    }
}
```

---

### Mistake 3: Timer Not Stopped

**WRONG:**
```swift
// ❌ Timer keeps running after leaving screen
class LiveViewController: UIViewController {
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateData()
        }
    }
}
```

**CORRECT:**
```swift
// ✅ Stop when hidden
class LiveViewController: UIViewController {
    var timer: Timer?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
}
```

---

## Related Topics

- [App Lifecycle](app-lifecycle.md)
- [Memory Management](../07-advanced/memory-management.md)
- [Navigation](navigation.md)

---

**Master UIViewController lifecycle for responsive, efficient apps!**
