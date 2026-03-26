# 🤝 Contributing Guidelines

Thank you for your interest in contributing to this Swift documentation!

## 📋 Before You Start

1. **Read the existing documentation** to understand the style and structure
2. **Check [TEMPLATE.md](TEMPLATE.md)** for the standard file format
3. **Follow naming conventions** (lowercase with hyphens)
4. **Ensure content is 100% English** - no Portuguese or mixed languages

---

## ✍️ How to Contribute

### 1. Choose a Topic

Check the [README.md](README.md) or [DOCUMENTATION_OVERVIEW.md](../DOCUMENTATION_OVERVIEW.md) to find:
- Missing topics
- Sections needing expansion
- Areas requiring improvement

### 2. Create or Edit a File

**For new files:**
1. Use [TEMPLATE.md](TEMPLATE.md) as your starting point
2. Choose the appropriate folder (01-08)
3. Follow the naming convention: `topic-name.md`

**For existing files:**
1. Check for accuracy
2. Update outdated information
3. Add new examples or use cases
4. Improve clarity or structure

### 3. Follow the Template Structure

Every file should include:

```
# [Title] 🎯
## Overview
## Main Topics
## Official Documentation
[Detailed sections with code examples]
## Use Cases & Real Applications
## Best Practices
## Performance Considerations
## Common Mistakes (Anti-patterns)
## Related Topics
```

See [TEMPLATE.md](TEMPLATE.md) for the complete template.

---

## 📝 Writing Guidelines

### Content Standards

- **Clarity:** Write for diverse skill levels
- **Completeness:** Provide working code examples
- **Accuracy:** Verify against official Apple documentation
- **Recency:** Use current Swift/iOS versions
- **Practicality:** Focus on real-world applications

### Code Examples

- ✅ **DO:** Provide complete, runnable examples
- ✅ **DO:** Include output/expected results
- ✅ **DO:** Show both correct and incorrect approaches
- ❌ **DON'T:** Include incomplete snippets
- ❌ **DON'T:** Mix multiple concepts in one example
- ❌ **DON'T:** Use outdated API syntax

### Formatting

- Use **markdown** formatting
- Use **code blocks** with language specification:
  ```swift
  // Swift code here
  ```
- **Bold** for emphasis: `**important concept**`
- Use emojis for section headers (follow existing pattern)
- Keep line length reasonable (80-100 chars for code)

### Links

- Link to related topics in the same section
- Link to official Apple documentation
- Use relative paths for internal links:
  ```markdown
  [Functions](functions.md)
  [Architecture](../02-architecture/)
  ```

---

## 🔍 Quality Checklist

Before submitting, ensure:

- [ ] Content is accurate and tested
- [ ] Code examples run without errors
- [ ] All links work (internal and external)
- [ ] Spelling and grammar are correct
- [ ] No Portuguese or mixed language content
- [ ] Following the template structure
- [ ] File is in the correct folder
- [ ] File name follows naming convention
- [ ] Cross-references are updated
- [ ] Examples demonstrate best practices

---

## 🚀 Submission Process

### Via Git/GitHub

1. **Fork the repository** (if applicable)
2. **Create a branch:**
   ```bash
   git checkout -b add-topic-name
   ```
3. **Create/edit your file(s)**
4. **Commit with clear message:**
   ```bash
   git commit -m "docs: add topic-name with examples"
   ```
5. **Push to your fork:**
   ```bash
   git push origin add-topic-name
   ```
6. **Create a Pull Request** with:
   - Clear title describing changes
   - Description of what was added/changed
   - Any relevant issue numbers

### Commit Message Format

```
docs: brief description

More detailed explanation if needed
- Point 1
- Point 2
```

### PR Title Format

- `docs: add [topic-name]`
- `docs: improve [topic-name]`
- `docs: fix [issue] in [topic-name]`

---

## 📚 Section Guidelines

### 01-fundamentals/
- Basic Swift concepts
- No framework-specific content
- Beginner-friendly examples
- Build foundation for other sections

### 02-architecture/
- Design patterns
- Architectural approaches
- Best practices for large apps
- Design principles

### 03-networking-backend/
- API communication
- Server frameworks
- Network security
- Data formats (JSON, GraphQL, etc)

### 04-app-lifecycle/
- App events and lifecycle
- Distribution process
- CI/CD automation
- Development tools

### 05-features/
- iOS-specific features
- Framework integration
- Hardware interaction
- User interface features

### 06-data/
- Data persistence
- Cloud synchronization
- Database management
- Data security

### 07-advanced/
- Complex topics
- Performance optimization
- Security deep-dives
- Specialized frameworks

### 08-resources/
- Learning materials
- Community links
- References
- External resources

---

## 🎓 Documentation Levels

Content should cater to multiple levels:

### Beginner
- Explain "why" not just "how"
- Define technical terms
- Include simple examples first
- Avoid advanced concepts

### Intermediate
- Assume basic knowledge
- Show practical patterns
- Include real-world scenarios
- Explain trade-offs

### Advanced
- Optimize for performance
- Discuss edge cases
- Show advanced patterns
- Connect to related concepts

---

## ✅ Review Process

**Maintainers will:**
1. Check content accuracy
2. Verify code examples work
3. Ensure consistency with documentation
4. Review for clarity and completeness
5. Suggest improvements if needed
6. Approve and merge

**Timeline:**
- Simple edits: 1-3 days
- New content: 3-7 days
- Major additions: up to 2 weeks

---

## ❓ Questions?

If you have questions about:
- **Content:** Check the relevant section
- **Process:** See this file
- **Standards:** Check [TEMPLATE.md](TEMPLATE.md)
- **Structure:** See [README.md](README.md)

---

## 🎉 Thank You!

Your contributions help make this documentation better for everyone.

**We appreciate:**
- ✨ Fixing typos and grammar
- 🧐 Improving clarity
- 📚 Adding new topics
- 🐛 Reporting inaccuracies
- 💡 Suggesting improvements

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

**Happy contributing!** 🚀
