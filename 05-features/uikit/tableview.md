# UITableView - List Views and Data Display

## Overview

UITableView displays lists of data in rows. It's optimized for large datasets through cell reuse and efficient memory management, enabling smooth scrolling even with thousands of items.

## Main Topics

- [Table View Basics](#table-view-basics)
- [Data Source and Delegate](#data-source-and-delegate)
- [Cell Configuration](#cell-configuration)
- [Sections and Headers](#sections-and-headers)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [UITableView](https://developer.apple.com/documentation/uikit/uitableview)

---

## Table View Basics

### Simple List Setup

```swift
import UIKit

class ContactsViewController: UITableViewController {
    var contacts: [String] = ["Alice", "Bob", "Charlie"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Contacts"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    // Number of rows
    override func tableView(_ tableView: UITableView, 
                           numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    // Configure cell
    override func tableView(_ tableView: UITableView,
                           cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = contacts[indexPath.row]
        return cell
    }
}
```

### Table View Styles

```swift
// UITableViewStyle.plain (no grouped sections)
let tableView = UITableView(frame: .zero, style: .plain)

// UITableViewStyle.grouped (sections with separators)
let tableView = UITableView(frame: .zero, style: .grouped)

// UITableViewStyle.insetGrouped (iOS 13+, card-like)
let tableView = UITableView(frame: .zero, style: .insetGrouped)
```

---

## Data Source and Delegate

### Complete DataSource

```swift
import UIKit

class ViewController: UITableViewController {
    let sections = [
        ["Apples", "Bananas"],
        ["Carrots", "Dill"]
    ]
    let sectionTitles = ["Fruits", "Vegetables"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    // Number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    // Rows per section
    override func tableView(_ tableView: UITableView,
                           numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    // Section titles
    override func tableView(_ tableView: UITableView,
                           titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    // Cell configuration
    override func tableView(_ tableView: UITableView,
                           cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = sections[indexPath.section][indexPath.row]
        return cell
    }
}
```

### Delegate Methods

```swift
extension ViewController {
    // Selection
    override func tableView(_ tableView: UITableView,
                           didSelectRowAt indexPath: IndexPath) {
        let item = sections[indexPath.section][indexPath.row]
        print("Selected: \(item)")
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Row height
    override func tableView(_ tableView: UITableView,
                           heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // Edit actions
    override func tableView(_ tableView: UITableView,
                           trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            print("Delete \(indexPath.row)")
            completionHandler(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }
    
    // Keyboard dismissal
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}
```

---

## Cell Configuration

### Custom Table Cell

```swift
import UIKit

class ContactCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        avatarImage.layer.cornerRadius = avatarImage.bounds.width / 2
        avatarImage.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        phoneLabel.text = nil
        avatarImage.image = nil
    }
    
    func configure(name: String, phone: String, avatar: UIImage?) {
        nameLabel.text = name
        phoneLabel.text = phone
        avatarImage.image = avatar
    }
}

class ViewController: UITableViewController {
    override func tableView(_ tableView: UITableView,
                           cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        
        cell.configure(name: "John", phone: "555-1234", avatar: UIImage(named: "avatar"))
        return cell
    }
}
```

### Programmatic Cell Creation

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
    
    func setupUI() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .gray
        
        // Add constraints
    }
    
    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}
```

---

## Sections and Headers

### Custom Headers

```swift
import UIKit

class SectionHeaderView: UITableViewHeaderFooterView {
    static let identifier = "SectionHeader"
    
    let titleLabel = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(titleLabel)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .systemBlue
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
}

class ViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(
            SectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier: SectionHeaderView.identifier
        )
    }
    
    override func tableView(_ tableView: UITableView,
                           viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: SectionHeaderView.identifier
        ) as! SectionHeaderView
        
        header.configure(title: "Section \(section)")
        return header
    }
    
    override func tableView(_ tableView: UITableView,
                           heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
}
```

### Moving and Deleting Rows

```swift
class ViewController: UITableViewController {
    var items = ["Item 1", "Item 2", "Item 3"]
    
    // Enable editing
    override func tableView(_ tableView: UITableView,
                           canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Handle delete
    override func tableView(_ tableView: UITableView,
                           commit editingStyle: UITableViewCell.EditingStyle,
                           forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Enable moving
    override func tableView(_ tableView: UITableView,
                           canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Handle move
    override func tableView(_ tableView: UITableView,
                           moveRowAt sourceIndexPath: IndexPath,
                           to destinationIndexPath: IndexPath) {
        let item = items.remove(at: sourceIndexPath.row)
        items.insert(item, at: destinationIndexPath.row)
    }
}
```

---

## 🎯 Best Practices

### 1. Always Dequeue Cells
```swift
// ✅ Reuse cells efficiently
let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

// ❌ Create new cell each time
let cell = UITableViewCell()  // Memory inefficient
```

### 2. Register Cells
```swift
// ✅ Register before use
override func viewDidLoad() {
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
}

// ❌ Risk of crashes
// Cell not registered
```

### 3. Batch Updates
```swift
// ✅ Efficient updates
tableView.performBatchUpdates {
    tableView.insertRows(at: indexPaths, with: .automatic)
    tableView.deleteRows(at: deleteIndexPaths, with: .automatic)
}

// ❌ Individual updates
tableView.insertRows(at: indexPaths, with: .automatic)
tableView.deleteRows(at: deleteIndexPaths, with: .automatic)
```

---

## ❌ Common Mistakes

### Mistake 1: Not Resetting Cell State

**WRONG:**
```swift
// ❌ Old data visible when cell reused
override func tableView(_ tableView: UITableView,
                       cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
    cell.textLabel?.text = items[indexPath.row]
    // Doesn't clear previous state
    return cell
}
```

**CORRECT:**
```swift
// ✅ Clear state in prepareForReuse
override func prepareForReuse() {
    super.prepareForReuse()
    textLabel?.text = nil
    imageView?.image = nil
}
```

---

### Mistake 2: Heavy Operations in cellForRowAt

**WRONG:**
```swift
// ❌ Blocks scrolling
override func tableView(_ tableView: UITableView,
                       cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let image = downloadHeavyImage(url)  // Blocking!
    cell.imageView?.image = image
    return cell
}
```

**CORRECT:**
```swift
// ✅ Load asynchronously
class Cell: UITableViewCell {
    func loadImage(from url: URL) {
        Task {
            if let image = try await ImageCache.shared.image(for: url) {
                imageView?.image = image
            }
        }
    }
}
```

---

## Related Topics

- [UICollectionView](collection-view.md)
- [Performance Optimization](../07-advanced/performance-optimization.md)
- [UIViewController Lifecycle](uiviewcontroller-lifecycle.md)

---

**Master UITableView for efficient list interfaces!**
