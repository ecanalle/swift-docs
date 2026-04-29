# Copilot Instructions for Swift Documentation Repository

## Repository Overview

This is a comprehensive Swift development documentation project with 180+ detailed guides organized into 8 numbered sections (01-fundamentals through 08-resources). The repository follows a **learning-path structure** with progressive difficulty levels (beginner to advanced).

### Key Characteristics
- **Pure documentation** - Markdown-only repository (no code compilation)
- **Structured learning** - Content organized by topic complexity
- **Code-heavy** - Each guide includes complete, runnable Swift examples
- **Multi-level approach** - Content addresses beginners, intermediates, and advanced developers simultaneously

---

## File Organization & Naming Conventions

### Directory Structure

```
01-fundamentals/    → Swift basics, OOP, functions (Level 🟢 Beginner)
02-architecture/    → Design patterns, DI, scalability (Level 🟡 Intermediate)
03-networking-backend/ → APIs, networking, backend (Level 🟡 Intermediate)
04-app-lifecycle/   → Release, CI/CD, debugging, tools (Level 🟡 Intermediate)
05-features/        → iOS-specific features, hardware (Level 🟠 Advanced)
06-data/            → Storage, persistence, CloudKit (Level 🟠 Advanced)
07-advanced/        → Performance, security, ML, NLP (Level 🔴 Expert)
08-resources/       → External materials, community links (Reference)
```

### File vs Folder Strategy

**Use FOLDER when topic has 3+ distinct subtopics:**
```
05-features/bluetooth-and-ble/
├── bluetooth-basics.md (400-600 lines)
├── central-peripheral-roles.md (400-600 lines)
├── device-discovery.md (400-600 lines)
└── reading-writing-data.md (400-600 lines)
```

**Use SINGLE FILE when topic is standalone:**
```
05-features/
├── dark-mode-appearance.md (400-600 lines)
└── deep-links.md (400-600 lines)
```

**Benefits of folder structure:**
- ✅ More visual and organized (especially in Obsidian)
- ✅ Prevents duplication issues
- ✅ Each file stays at ideal size (400-700 lines)
- ✅ Natural growth path for topics
- ✅ Better navigation in both GitHub and Obsidian

### File Naming Rules

- **All lowercase** with hyphens: `topic-name.md`
- **No spaces or underscores** in filenames
- **Descriptive and searchable**: Use complete topic names (not abbreviated)
- Examples: `dependency-injection.md`, `memory-management.md`, `app-launch-sequence.md`

---

## Content Standards & Template

### Mandatory Structure

Every new file **must** follow the [TEMPLATE.md](../TEMPLATE.md) structure:

```markdown
# [Title] 🎯

## Overview
Brief 2-3 sentence description. What problem does this solve?

## Main Topics
- [Section 1](#section-1) - Brief description
- [Section 2](#section-2) - Brief description
- [Use Cases](#use-cases) - Practical applications
- [Best Practices](#best-practices)
- [Common Mistakes](#common-mistakes-anti-patterns)

## Official Documentation
- [Apple: Framework Name](https://developer.apple.com/...)
- [WWDC YYYY: Video Title](https://developer.apple.com/videos/...)

## [Section 1]
### Subsection 1.1
[Content with code examples]

...continuing with complete sections...

## 📚 Use Cases & Real Applications
## ✅ Best Practices
## ❌ Common Mistakes (Anti-patterns)
## 🔗 Related Topics
```

### Code Examples: Critical Requirements

- ✅ **Complete & runnable** - Full code blocks that execute without additional setup
- ✅ **With output** - Show expected results in comments
- ✅ **Demonstrate both approaches** - Show correct AND incorrect patterns
- ✅ **Real-world applicable** - Practical examples, not just tutorials
- ✅ **Language specification** - Always use ` ```swift ` for code blocks

### Writing Guidelines

1. **Multi-level content** - Explain concepts at beginner, intermediate, and advanced levels within the same section
2. **100% English only** - No Portuguese, Portuguese transliterations, or mixed languages
3. **Apple official documentation** - Cross-reference official documentation where relevant
4. **Clarity over brevity** - Define technical terms; assume readers may not know all jargon
5. **Section coherence** - Each section should be self-contained but clearly link to related topics

---

## Contributing Workflow

### Before Creating Content

1. Check [CONTRIBUTING.md](../CONTRIBUTING.md) for full guidelines
2. Use [TEMPLATE.md](../TEMPLATE.md) as your starting point
3. Verify the topic isn't already covered (search existing files)
4. Choose the appropriate folder (01-08) based on difficulty level

### Quality Checklist

Before submitting changes:
- [ ] Content is accurate and verified against official Apple docs
- [ ] All Swift code examples are complete and tested
- [ ] No Portuguese or mixed language content
- [ ] Follows the template structure exactly
- [ ] File name uses lowercase-with-hyphens convention
- [ ] Internal links use relative paths: `[Link](../02-architecture/)`
- [ ] External links point to official Apple documentation
- [ ] Spelling and grammar checked
- [ ] Cross-references updated in related files

### Git Commit Message Format

```
docs: brief description

More detailed explanation if needed
- Point 1
- Point 2
```

Example:
```
docs: add dependency-injection guide with 5 patterns

Covers constructor injection, property injection, method injection,
and service locator patterns with real-world examples.
- Includes memory management considerations
- Compares performance characteristics
```

---

## Section-Specific Guidelines

### 01-fundamentals/
- Foundation for all other sections
- Swift syntax, types, operators, OOP concepts
- Beginner-friendly; define all terminology
- No framework-specific content

### 02-architecture/
- Design patterns (MVC, MVVM, VIPER, Redux)
- Dependency injection techniques
- Scalability principles
- Trade-offs between approaches

### 03-networking-backend/
- API design and consumption
- URL session and networking frameworks
- Backend integration patterns
- Security and authentication

### 04-app-lifecycle/
- App lifecycle events (launch, foreground, background, termination)
- Testing and debugging tools
- CI/CD pipelines and automation
- Release process and distribution

### 05-features/
- iOS-specific frameworks (HealthKit, HomeKit, MapKit, etc.)
- Hardware integration (Bluetooth, location, sensors)
- User interface features beyond basic views
- Extension types and integration

### 06-data/
- Data persistence (UserDefaults, Core Data, SQLite)
- CloudKit and cloud synchronization
- Codable and JSON handling
- Data security and encryption

### 07-advanced/
- Performance optimization (memory, CPU, battery)
- Security deep-dives (keychain, biometrics, HTTPS)
- Machine learning (Core ML, Vision)
- Concurrency and async-await patterns

### 08-resources/
- Links to official Apple documentation
- WWDC video references
- Community resources
- Learning tools and external courses

---

## Related Topics & Cross-Referencing

When creating content:

1. **Link to related sections** using relative paths:
   - Same section: `[Functions](functions.md)`
   - Different section: `[Architecture Patterns](../02-architecture/design-patterns.md)`

2. **Include a "Related Topics" section** that links to:
   - More advanced versions of the same concept
   - Prerequisites needed to understand this topic
   - Practical applications in other sections

3. **Update cross-references** - If you add a new topic, update existing files that should reference it

---

## Learning Path Integration

The [LEARNING_PATH.md](../LEARNING_PATH.md) defines the suggested sequence for new developers. When adding content:

- Consider where it fits in the progression
- Verify prerequisites are covered first
- Suggest learning path updates if your topic should be included

---

## Implementation Status & Incomplete Topics

### ✅ Recently Implemented (Following Real Pattern)

**05-features/ (3 topics completed):**
- `bluetooth-and-ble.md` (15.4 KB) - BLE fundamentals, Central/Peripheral roles, Connection management
- `siri-and-app-intents.md` (11.7 KB) - App Intents, Siri Suggestions, Shortcuts integration
- `communication-and-deeplinks.md` (13.2 KB) - URL schemes, Universal Links, Deep linking

**Pattern Used:** 500-700 lines per file, WRONG/CORRECT comparisons, emoji headers, Best Practices + Common Mistakes sections

### 🟠 Incomplete Topics (Ready for Implementation)

These folders/files are empty stubs and need implementation following the real pattern:

**05-features/ (5 remaining):**
- `app-extensions.md`
- `callkit-advanced.md`
- `geolocation-and-maps.md`
- `uikit.md`
- `user-interface-frameworks.md`

**03-networking-backend/ (1 section):**
- Placeholder subfolders: `backend/`, `networking-and-apis/` (content should go in section-level `.md` files)

**08-resources/ (1 section):**
- Placeholder subfolders: `frameworks/`, `resources-and-community/`

**Empty Files to Remove/Fill:**
- `fundamentals.md` (root) - Remove or consolidate
- `animation-in-swift.md` (root) - Remove, use section version
- `01-fundamentals/animation-in-swift.md` - Ready for content
- `01-fundamentals/fundamentals.md` - Ready for content

**Naming Issues:**
- `06-data/{cloudkit-advanced}/` - Rename to valid folder name (remove braces)

---

## Real Pattern for New Content

Instead of the generic TEMPLATE.md, follow this **actual pattern from completed files:**

```markdown
# [Title] - [Subtitle/Context]

## Overview
[1-2 sentences about what this is and why it matters]

## Main Topics
- [Section](#section)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation
- [Apple: Link](https://developer.apple.com/...)

---

## Section Title

### Subsection
[Explanation]

\`\`\`swift
// ✅ Correct / ❌ Wrong
// Complete, runnable code
\`\`\`

**Key Points:**
- Point 1
- Point 2

---

## ✅ Best Practices

### Practice Name
**DO:**
\`\`\`swift
// Correct approach
\`\`\`

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake Name

**WRONG:**
\`\`\`swift
// Problematic code
\`\`\`

**CORRECT:**
\`\`\`swift
// Fixed approach
\`\`\`

---

## 🔗 Related Topics
- [Link](../path/file.md)
```

**Key Differences from Generic Template:**
- **Use actual emojis**: ✅ ❌ 🔗 📚 ⚠️ in headers
- **WRONG/CORRECT side by side**: Not just explanations
- **Concrete sections**: Not placeholder topic lists
- **Related Topics always at end**: With real internal links
- **400-700 lines typical**: Substantial, not minimal

**See the template:** `/Users/ecanalle/.copilot/session-state/.../PADRÃO_REAL_DO_REPOSITÓRIO.md`

---

## Review & Maintenance

### Content Review Criteria

Maintainers check for:
1. **Accuracy** - Verified against current Apple documentation
2. **Completeness** - All examples are runnable, all concepts explained
3. **Consistency** - Follows real pattern (not generic template)
4. **Clarity** - Accessible to the target audience level
5. **Currency** - Uses current Swift/iOS versions

### Update Frequency

- Review for outdated API usage annually
- Update WWDC video links when new sessions are released
- Fix broken Apple documentation links as they appear
- Incorporate new frameworks as they're released

---

## Key Reminders for Copilot Sessions

- **Follow the REAL pattern** (PADRÃO_REAL_DO_REPOSITÓRIO.md), not generic TEMPLATE.md
- **Every file: 500-700 lines minimum** with substantive content
- **WRONG/CORRECT code samples** - Always show both approaches side by side
- **Best Practices + Common Mistakes sections required** - Every file must have both
- **Emojis in headers**: ✅ ❌ 🔗 📚 - Makes content scannable
- **Related Topics at end** - Link to 3-5 related articles
- **Every code example complete and runnable** - No incomplete snippets
- **Link liberally with relative paths** - `[Link](../02-architecture/file.md)`
- **100% English only** - No Portuguese or mixed language
- **Verify against Apple documentation** - Cross-check all technical content

---

**Last Updated:** April 28, 2026  
**Repository Status:** ✅ Active & Maintained  
**Implementation Progress:** 3/~15 topics completed (Real pattern established)
