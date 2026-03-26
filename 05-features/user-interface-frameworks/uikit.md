# UIKit Fundamentals

## Overview

UIKit is the primary framework for building iOS user interfaces using imperative programming. While SwiftUI is gaining adoption, UIKit remains essential knowledge due to legacy codebases and powerful capabilities.

## Main Topics

- [UIView Basics](#uiview-basics)
- [UIViewController Lifecycle](#uiviewcontroller-lifecycle)
- [Auto Layout](#auto-layout)
- [View Hierarchy](#view-hierarchy)
- [UIControl Events](#uicontrol-events)
- [Navigation](#navigation)
- [Table Views](#table-views)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [UIKit Documentation](https://developer.apple.com/documentation/uikit)
- [Developing for iOS](https://developer.apple.com/ios/)

---

## UIView Basics

### Creating UIViews

```swift
// Simple custom UIView
class CustomView: UIView {
    let label = UILabel()
    let button = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }
    
    private func setupSubviews() {
        backgroundColor = .white
        
        label.text = "Hello"
        label.textAlignment = .center
        addSubview(label)
        
        button.setTitle("Tap Me", for: .normal)
        button.configuration = .filled()
        addSubview(button)
    }
}

// Usage
let customView = CustomView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
view.addSubview(customView)
```

### Common UIView Components

```swift
// UILabel
let label = UILabel()
label.text = "Hello World"
label.font = UIFont.systemFont(ofSize: 16)
label.textColor = .black

// UIButton
let button = UIButton(type: .system)
button.setTitle("Press Me", for: .normal)
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

// UITextField
let textField = UITextField()
textField.placeholder = "Enter text"
textField.borderStyle = .roundedRect

// UIImageView
let imageView = UIImageView(image: UIImage(named: "photo"))
imageView.contentMode = .scaleAspectFill

// UIProgressView
let progressView = UIProgressView(progressViewStyle: .default)
progressView.progress = 0.5

// UISwitch
let toggle = UISwitch()
toggle.isOn = true
toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
```

---

## UIViewController Lifecycle

### View Lifecycle

```swift
class MyViewController: UIViewController {
    // 1. View loaded from nib/created programmatically
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup views, fetch initial data
        print("1. viewDidLoad")
        title = "My Screen"
        view.backgroundColor = .white
    }
    
    // 2. View about to appear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("2. viewWillAppear")
        // Prepare UI before visible
    }
    
    // 3. View appeared (fully visible)
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("3. viewDidAppear")
        // Start animations, begin fetching
    }
    
    // 4. View about to disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("4. viewWillDisappear")
        // Stop animations, cleanup
    }
    
    // 5. View disappeared
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("5. viewDidDisappear")
        // Final cleanup
    }
}

// Order: viewDidLoad → viewWillAppear → viewDidAppear → viewWillDisappear → viewDidDisappear
```

### Safe Area

```swift
class SafeAreaViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let label = UILabel()
        label.text = "Safe area respects notch"
        view.addSubview(label)
        
        // Add constraints to safe area
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        ])
    }
}
```

---

## Auto Layout

### Layout Constraints

```swift
// Programmatic constraints
let button = UIButton()
view.addSubview(button)

button.translatesAutoresizingMaskIntoConstraints = false

NSLayoutConstraint.activate([
    // Position
    button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
    button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
    
    // Size
    button.widthAnchor.constraint(equalToConstant: 100),
    button.heightAnchor.constraint(equalToConstant: 50)
])
```

### Stack Views

```swift
// UIStackView simplifies layout
let stackView = UIStackView()
stackView.axis = .vertical
stackView.spacing = 10

let label1 = UILabel()
label1.text = "Item 1"

let label2 = UILabel()
label2.text = "Item 2"

let label3 = UILabel()
label3.text = "Item 3"

stackView.addArrangedSubview(label1)
stackView.addArrangedSubview(label2)
stackView.addArrangedSubview(label3)

view.addSubview(stackView)
```

### Safe Area Constraints

```swift
// Always use safeAreaLayoutGuide
label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true

// Not view.topAnchor (ignores notch/safe area)
```

---

## View Hierarchy

### Adding Subviews

```swift
// Parent-child relationship
let container = UIView()
let childView = UILabel()

view.addSubview(container)        // container is child of view
container.addSubview(childView)   // childView is child of container

// Z-ordering
container.bringSubviewToFront(childView)   // Bring to front
container.sendSubviewToBack(childView)     // Send to back

// Check hierarchy
view.subviews.count     // Number of direct children
container.superview?.backgroundColor = .red
```

### View Properties

```swift
// Visibility
view.isHidden = true
view.alpha = 0.5

// Interaction
view.isUserInteractionEnabled = false

// Tag identification
view.tag = 101
let found = view.viewWithTag(101)

// Content mode
imageView.contentMode = .scaleAspectFill
```

---

## UIControl Events

### Button Actions

```swift
class EventViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .system)
        button.setTitle("Tap Me", for: .normal)
        
        // Add target-action
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func buttonTapped() {
        print("Button tapped!")
    }
}
```

### Touch Events

```swift
// UIControl events
view.addTarget(self, action: #selector(touchDown), for: .touchDown)
view.addTarget(self, action: #selector(touchUp), for: .touchUpInside)
view.addTarget(self, action: #selector(touchCancel), for: .touchCancel)

// UIGestureRecognizer
let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
view.addGestureRecognizer(tap)

let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
swipe.direction = .left
view.addGestureRecognizer(swipe)

let pan = UIPanGestureRecognizer(target: self, action: #selector(panned))
view.addGestureRecognizer(pan)

@objc func tapped() { print("Tapped") }
@objc func swiped() { print("Swiped") }
@objc func panned() { print("Panned") }
```

---

## Navigation

### Push Navigation

```swift
// NavigationController stack
let nextViewController = DetailViewController()
navigationController?.pushViewController(nextViewController, animated: true)

// Pop back
navigationController?.popViewController(animated: true)
navigationController?.popToRootViewController(animated: true)
```

### Modal Presentation

```swift
let modalViewController = ModalViewController()
let navController = UINavigationController(rootViewController: modalViewController)
navController.modalPresentationStyle = .formSheet

present(navController, animated: true)

// Dismiss
dismiss(animated: true)
```

### Passing Data

```swift
// Push with data
let detail = DetailViewController()
detail.userID = 123
navigationController?.pushViewController(detail, animated: true)

// Modal with data
let modal = ModalViewController()
modal.delegate = self
present(modal, animated: true)
```

---

## Table Views

### Basic Table View

```swift
class TableViewController: UITableViewController {
    var items: [String] = ["Item 1", "Item 2", "Item 3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected: \(items[indexPath.row])")
    }
}
```

### Custom Cells

```swift
class CustomCell: UITableViewCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    func configure(with item: Item) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}
```

---

## 🎯 Best Practices

### 1. Always Use Safe Area
```swift
// ✅ Respects notch
label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)

// ❌ Ignores notch
label.topAnchor.constraint(equalTo: view.topAnchor)
```

### 2. Manage View Lifecycle Properly
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    // Setup UI
}

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Refresh data
}

override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    // Cleanup
}
```

### 3. Use Stack Views for Layout
```swift
// ✅ Flexible and maintainable
let stack = UIStackView()
stack.axis = .vertical

// ❌ Lots of constraints
NSLayoutConstraint.activate([...])
```

---

## ❌ Common Mistakes

### Mistake 1: Forgetting translatesAutoresizingMaskIntoConstraints

**WRONG:**
```swift
// ❌ Will be ignored
label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
```

**CORRECT:**
```swift
// ✅ Constraints work
label.translatesAutoresizingMaskIntoConstraints = false
label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
```

---

### Mistake 2: Not Retaining View Controllers

**WRONG:**
```swift
// ❌ Will be deallocated immediately
func openDetail() {
    let detail = DetailViewController()
    present(detail, animated: true)
}
```

**CORRECT:**
```swift
// ✅ Safe if retained elsewhere (usually by navigation)
let detail = DetailViewController()
navigationController?.pushViewController(detail, animated: true)
```

---

## Related Topics

- [SwiftUI Basics](../../05-features/siri-and-app-intents/swiftui-basics.md)
- [MVC Pattern](../../02-architecture/software-architecture/mvc.md)
- [View Controllers](../../04-app-lifecycle/debug-and-development-tools/testing.md)

---

**Master UIKit for powerful iOS development!**
