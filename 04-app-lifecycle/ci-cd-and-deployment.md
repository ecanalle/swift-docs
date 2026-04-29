# CI/CD & Deployment - Automating Release Pipelines 🎯

## Overview
Continuous Integration and Continuous Deployment (CI/CD) automate testing, building, and releasing your app. Learn to set up GitHub Actions workflows, use fastlane for automation, and implement reliable release processes that minimize human error and accelerate development.

## Main Topics
- [GitHub Actions Setup](#github-actions-setup) - CI/CD workflows
- [Build Automation](#build-automation) - Automated testing and building
- [fastlane Integration](#fastlane-integration) - Deployment automation
- [App Store Submission](#app-store-submission) - Release process
- [Beta Testing](#beta-testing) - TestFlight and external testing
- [Versioning & Releases](#versioning--releases) - Managing versions
- [Best Practices](#-best-practices) - Reliable pipelines
- [Common Mistakes](#-common-mistakes-anti-patterns) - CI/CD pitfalls

## Official Documentation
- [Apple: GitHub Actions for Xcode](https://github.com/apple/swift-org-website/blob/main/.github/workflows/publish.yml)
- [fastlane: iOS Automation](https://docs.fastlane.tools/getting-started/ios/setup/)
- [App Store Connect: API](https://developer.apple.com/app-store-connect/api/)

---

## GitHub Actions Setup

### Basic iOS Workflow

```yaml
# ✅ Correct: GitHub Actions workflow for iOS
name: CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: macos-13
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Xcode
      run: sudo xcode-select --switch /Applications/Xcode_14.3.app/Contents/Developer
    
    - name: Install dependencies
      run: |
        pod install
        # or: swift package resolve
    
    - name: Run tests
      run: |
        xcodebuild test \
          -workspace MyApp.xcworkspace \
          -scheme MyAppTests \
          -configuration Debug \
          -sdk iphonesimulator \
          -derivedDataPath DerivedData \
          | xcpretty
    
    - name: Lint code
      run: |
        swiftlint --strict
      
    - name: Build archive
      run: |
        xcodebuild archive \
          -workspace MyApp.xcworkspace \
          -scheme MyApp \
          -configuration Release \
          -archivePath MyApp.xcarchive
```

**Key Points:**
- Use `macos-13` runner for latest Xcode
- Always specify explicit paths for reproducibility
- Fail fast on tests before building
- Archive only on main branch

### Matrix Testing Across Environments

```yaml
# ✅ Correct: Testing multiple configurations
name: Multi-Platform Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-13
    strategy:
      matrix:
        include:
          - destination: "generic/platform=iOS Simulator,name=iPhone 14"
            scheme: "MyApp"
          - destination: "generic/platform=iOS Simulator,name=iPad Air"
            scheme: "MyApp"
          - destination: "generic/platform=macOS"
            scheme: "MyApp-macOS"
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Test ${{ matrix.destination }}
      run: |
        xcodebuild test \
          -workspace MyApp.xcworkspace \
          -scheme "${{ matrix.scheme }}" \
          -destination "${{ matrix.destination }}"
```

---

## Build Automation

### Build Script with Notifications

```swift
// ✅ Correct: Build script that notifies on completion
#!/bin/bash

set -e  # Exit on error

echo "🏗️ Starting build..."

# Build
xcodebuild archive \
  -workspace MyApp.xcworkspace \
  -scheme MyApp \
  -configuration Release \
  -archivePath MyApp.xcarchive \
  -derivedDataPath DerivedData

# Export IPA
xcodebuild -exportArchive \
  -archivePath MyApp.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ./build

# Notify Slack on success
curl -X POST $SLACK_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"✅ Build succeeded"}'

echo "✅ Build complete"
```

### Build Versioning

```swift
// ✅ Correct: Automated version management
import Foundation

// Build.swift
struct BuildInfo {
    static let version = "1.2.0"
    static let build = ProcessInfo.processInfo.environment["BUILD_NUMBER"] ?? "debug"
    static let gitCommit = ProcessInfo.processInfo.environment["GIT_COMMIT"] ?? "unknown"
    
    static var fullVersion: String {
        return "\(version) (build: \(build))"
    }
    
    static var userAgent: String {
        return "MyApp/\(version) (\(build))"
    }
}

// Usage
print(BuildInfo.fullVersion)  // "1.2.0 (build: 42)"
```

### Test Coverage Reporting

```yaml
# ✅ Correct: Collecting and reporting test coverage
- name: Run tests with coverage
  run: |
    xcodebuild test \
      -workspace MyApp.xcworkspace \
      -scheme MyApp \
      -enableCodeCoverage YES \
      -derivedDataPath DerivedData

- name: Generate coverage report
  run: |
    xcrun xccov view DerivedData/Logs/Test/*.xcresult \
      | tee coverage.txt

- name: Check coverage threshold
  run: |
    COVERAGE=$(grep "^Coverage:" coverage.txt | awk '{print $2}' | sed 's/%//')
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "Coverage too low: $COVERAGE%"
      exit 1
    fi
```

---

## fastlane Integration

### Setting up fastlane

```bash
# ✅ Correct: fastlane initialization
sudo gem install fastlane
cd MyApp
fastlane init
```

### fastlane Lanes

```ruby
# ✅ Correct: fastlane configuration
# fastlane/Fastfile

default_platform(:ios)

platform :ios do
  
  # Development lane
  private_lane :build_dev do
    build_app(
      workspace: "MyApp.xcworkspace",
      scheme: "MyApp",
      configuration: "Debug",
      derived_data_path: "DerivedData",
      destination: "generic/platform=iOS Simulator",
      skip_package_ipa: true,
      skip_package_pkg: true
    )
  end
  
  # Build for TestFlight
  lane :beta do
    setup_ci if is_ci
    
    increment_build_number(xcodeproj: "MyApp.xcodeproj")
    
    build_app(
      workspace: "MyApp.xcworkspace",
      scheme: "MyApp",
      configuration: "Release",
      export_method: "app-store",
      output_directory: "./build",
      skip_package_ipa: false
    )
    
    upload_to_testflight(
      beta_app_description: "New beta version",
      skip_submission: true
    )
  end
  
  # Release to App Store
  lane :release do
    setup_ci if is_ci
    
    # Increment version
    increment_version_number(
      bump_type: "patch"
    )
    
    # Build
    build_app(
      workspace: "MyApp.xcworkspace",
      scheme: "MyApp",
      configuration: "Release",
      export_method: "app-store",
      output_directory: "./build",
      skip_package_ipa: false
    )
    
    # Submit to App Store
    upload_to_app_store(
      skip_screenshots: false,
      skip_metadata: false,
      force: false
    )
    
    # Create git tag
    add_git_tag(tag: "v#{get_version_number}")
    push_to_git_remote
  end
  
  # Error handler
  error do |lane, exception|
    slack(
      message: "Lane '#{lane}' failed",
      success: false
    )
  end
  
end
```

### Keychain Configuration for CI

```bash
# ✅ Correct: Setting up signing certificates
# In CI environment

# Create keychain for CI
security create-keychain -p $CI_KEYCHAIN_PASSWORD ci.keychain

# Import certificates
security import ~/certificates.p12 \
  -k ci.keychain \
  -P $CERTIFICATE_PASSWORD \
  -A

# Set keychain as default
security default-keychain -s ci.keychain
security unlock-keychain -p $CI_KEYCHAIN_PASSWORD ci.keychain

# Use in fastlane
match(
  type: "appstore",
  keychain_password: ENV["CI_KEYCHAIN_PASSWORD"],
  readonly: true
)
```

---

## App Store Submission

### Managing App Store Metadata

```swift
// ✅ Correct: App Store metadata management
// fastlane/metadata/en-US/description.txt
MyApp - Your description here

// fastlane/metadata/en-US/release_notes.txt
Version 1.2.0:
- New feature: Dark mode support
- Bug fix: Fixed crash in settings
- Performance: Improved loading speed

// fastlane/metadata/en-US/keywords
swift,ios,app,productivity

// Programmatic approach
lane :update_metadata do
  deliver(
    username: "developer@apple.com",
    app_version: "1.2.0",
    automatic_release: false,
    skip_screenshots: true,
    skip_app_icon: true,
    force: true
  )
end
```

### Version Management

```swift
// ✅ Correct: Version bumping in CI/CD
lane :prepare_release do
  # Current version
  current_version = get_version_number(xcodeproj: "MyApp.xcodeproj")
  
  # Increment based on tag
  version_bump_type = ENV["VERSION_BUMP"] || "patch"  # patch, minor, major
  
  increment_version_number(
    xcodeproj: "MyApp.xcodeproj",
    bump_type: version_bump_type
  )
  
  new_version = get_version_number(xcodeproj: "MyApp.xcodeproj")
  
  # Update Info.plist
  set_info_plist_value(
    path: "MyApp/Info.plist",
    key: "CFBundleVersion",
    value: get_build_number(xcodeproj: "MyApp.xcodeproj").to_i + 1
  )
  
  puts "Version updated: #{current_version} -> #{new_version}"
end
```

---

## Beta Testing

### TestFlight Distribution

```ruby
# ✅ Correct: Automated TestFlight beta distribution
lane :beta_build do
  # Build
  build_app(
    workspace: "MyApp.xcworkspace",
    scheme: "MyApp",
    configuration: "Release",
    export_method: "app-store",
    destination: "generic/platform=iOS",
    skip_package_ipa: false
  )
  
  # Upload to TestFlight
  upload_to_testflight(
    skip_waiting_for_build_processing: false,
    skip_submission: true,  # Don't submit to review
    beta_app_description: "Version #{get_version_number} - #{get_build_number}",
    beta_app_feedback_email: "beta@example.com",
    notify_external_testers: true,
    groups: ["Internal", "Beta Testers"]
  )
  
  # Notify
  slack(
    message: "✅ New beta available on TestFlight",
    payload: {
      "Version" => get_version_number,
      "Build" => get_build_number
    }
  )
end
```

---

## Versioning & Releases

### Semantic Versioning Strategy

```swift
// ✅ Correct: Managing semantic versions
// 1.2.3 = MAJOR.MINOR.PATCH

enum VersionBumpType {
    case major  // Breaking changes: 1.0.0 -> 2.0.0
    case minor  // New features: 1.2.0 -> 1.3.0
    case patch  // Bug fixes: 1.2.0 -> 1.2.1
}

// Automated from git tags
lane :deploy do
    latest_tag = last_git_tag  # e.g., "v1.2.0"
    
    # Determine bump type
    commit_messages = changelog_from_git_commits(
        between: [latest_tag, "HEAD"],
        pretty: "%b"
    )
    
    is_breaking = commit_messages.include?("BREAKING")
    is_feature = commit_messages.include?("FEATURE")
    
    bump_type = is_breaking ? "major" : (is_feature ? "minor" : "patch")
    
    # Bump version
    increment_version_number(bump_type: bump_type)
    new_version = get_version_number
    
    # Create tag and release
    add_git_tag(tag: "v#{new_version}")
    push_to_git_remote
end
```

---

## ✅ Best Practices

### Practice 1: Fail Fast
**DO:**
```yaml
jobs:
  ci:
    runs-on: macos-13
    steps:
      - name: Lint
        run: swiftlint  # ✅ First - catches obvious errors
      
      - name: Test
        run: xcodebuild test  # ✅ Second - unit tests
      
      - name: Build
        run: xcodebuild archive  # ✅ Last - only if passing
```

### Practice 2: Pin Dependencies
**DO:**
```yaml
steps:
  - uses: actions/checkout@v3
  - uses: apple/swift-org-website/...@v1.2.3  # ✅ Specific version
  - run: pod install --lock-dependencies
```

### Practice 3: Cache Dependencies
**DO:**
```yaml
- name: Cache CocoaPods
  uses: actions/cache@v3
  with:
    path: Pods
    key: pods-${{ hashFiles('Podfile.lock') }}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Running Everything in Sequence
**WRONG:**
```yaml
# ❌ Slow - each step blocks
- run: swiftlint
- run: xcodebuild build
- run: xcodebuild test
- run: archive
# Takes 30+ minutes
```

**CORRECT:**
```yaml
# ✅ Fast - parallel where possible
jobs:
  lint:
    runs-on: macos-13
    steps:
      - run: swiftlint
  
  test:
    runs-on: macos-13
    steps:
      - run: xcodebuild test
  
  build:
    needs: [lint, test]  # Only run after passing
```

### Mistake 2: Committing Secrets to Repo
**WRONG:**
```
# ❌ Never do this
CERTIFICATES_PASSWORD=MyPassword123
APPSTORE_KEY_ID=abc123
```

**CORRECT:**
```yaml
# ✅ Use GitHub Secrets
env:
  CERTIFICATES_PASSWORD: ${{ secrets.CERTS_PASSWORD }}
  APPSTORE_KEY_ID: ${{ secrets.APPSTORE_KEY }}
```

### Mistake 3: Not Versioning Xcode
**WRONG:**
```yaml
runs-on: macos-latest  # ❌ Changes unexpectedly
```

**CORRECT:**
```yaml
runs-on: macos-13  # ✅ Specific, reproducible
- name: Set Xcode version
  run: sudo xcode-select --switch /Applications/Xcode_14.3.app
```

### Mistake 4: Skipping Code Coverage
**WRONG:**
```swift
// ❌ Building without validating quality
xcodebuild test
xcodebuild archive
```

**CORRECT:**
```swift
// ✅ Enforce quality gates
xcodebuild test -enableCodeCoverage YES
# Check coverage > 80%
xcodebuild archive
```

---

## 🔗 Related Topics
- [Testing Strategies](../01-fundamentals/testing-fundamentals.md) - Test organization
- [App Store Release](app-store-and-release.md) - Manual release process
- [Debugging](xcode-and-ide.md) - Development tools
- [Monitoring](../07-advanced/logging-and-monitoring.md) - Production monitoring
- [Error Handling](../02-architecture/error-handling.md) - Managing errors
