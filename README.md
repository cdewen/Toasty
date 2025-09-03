# Toasty 🍞

A modern, accessible, and highly customizable toast notification library for SwiftUI.

![iOS 17+](https://img.shields.io/badge/iOS-17+-blue.svg)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)

## ✨ Features

- 🎨 **Multiple Styles**: Success, Error, Info, Loading, and Custom toasts
- 👆 **Drag to Dismiss**: Intuitive gesture-based dismissal with haptic feedback
- 📱 **Expandable Stack**: Tap to expand collapsed toasts into a scrollable list
- ⏰ **Auto-dismiss**: Configurable timing with pause/resume on interaction
- ♿ **Accessibility**: Full VoiceOver support with semantic announcements
- 🎛️ **Highly Customizable**: Colors, icons, timing, animations, and behavior
- 🚀 **Swift 6.0**: Modern concurrency with strict concurrency checking
- 📦 **Swift Package Manager**: Easy integration with SPM

### Expanded Stack View
*Add screenshot showing multiple toasts expanded into a vertical list*

### Drag to Dismiss
*Add screenshot or GIF demonstrating swipe gestures to dismiss toasts*

## 📦 Installation

### Swift Package Manager

Add Toasty as a dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Toasty.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. Go to File → Add Packages...
2. Enter `https://github.com/yourusername/Toasty.git`
3. Select the version you want to use

## 🚀 Quick Start

### 1. Set up the Toast Manager

```swift
import SwiftUI
import Toasty

@main
struct MyApp: App {
    @StateObject private var toastManager = ToastManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.toastManager, toastManager)
                .toasts()
        }
    }
}
```

### 2. Show Your First Toast

```swift
struct ContentView: View {
    @Environment(\.toastManager) private var toastManager

    var body: some View {
        VStack {
            Button("Show Success") {
                toastManager.show(.success("Data saved successfully!"))
            }

            Button("Show Error") {
                toastManager.show(.error("Failed to save data"))
            }

            Button("Show Info") {
                toastManager.show(.info("New version available"))
            }

            Button("Show Loading") {
                toastManager.show(.loading("Uploading..."))
            }
        }
    }
}
```

## 🎯 Usage Examples

### Custom Styling

```swift
// Custom colors and icons
let customToast = Toast.custom(
    "Custom message",
    iconName: "star.fill",
    iconColor: .yellow,
    backgroundColor: .purple.opacity(0.9)
)
toastManager.show(customToast)
```

### Advanced Configuration

```swift
// Custom toast manager with specific settings
let config = ToastConfiguration(
    maxToasts: 5,
    defaultDuration: 3.0,
    toastWidth: 280,
    animationDuration: 0.4
)

let customManager = ToastManager(configuration: config)
```

### Async Operations with Loading Toast

```swift
Button("Save Data") {
    ToastManager.showLoadingTask(
        manager: toastManager,
        loadingMessage: "Saving...",
        operation: { try await saveData() },
        success: { "Saved \($0.items.count) items" },
        failure: { "Save failed: \($0.localizedDescription)" }
    )
}
```

### Toast Control Handle

```swift
// Get a handle to control the toast imperatively
let handle = toastManager.show(.loading("Processing..."), duration: 0)

// Later, update the toast
await handle.update(
    style: .success(),
    message: "Processing complete!",
    duration: 2.0
)

// Or dismiss it early
await handle.dismiss()
```

## 🔧 Configuration Options

### ToastConfiguration

```swift
public struct ToastConfiguration {
    /// Maximum number of toasts to display simultaneously (default: 3)
    public var maxToasts: Int = 3

    /// Default duration in seconds before auto-dismissal (default: 4.5)
    public var defaultDuration: Double = 4.5

    /// Width of toast capsules (default: 220)
    public var toastWidth: CGFloat = 220

    /// Duration of add/remove animations (default: 0.3)
    public var animationDuration: Double = 0.3

    /// Distance threshold for triggering dismiss on drag (default: 60)
    public var dismissTriggerDistance: CGFloat = 60

    /// Distance to animate toast offscreen when dismissed (default: 500)
    public var offscreenDistance: CGFloat = 500

    /// Height of each row when toasts are expanded (default: 44)
    public var expandedRowHeight: CGFloat = 44

    /// Damping factor for drag gestures (default: 0.15)
    public var dragDampFactor: CGFloat = 0.15

    /// Maximum vertical damping distance during drag (default: 12)
    public var dragMaxVerticalDamp: CGFloat = 12

    /// Maximum horizontal damping distance during drag (default: 20)
    public var dragMaxHorizontalDamp: CGFloat = 20

    /// Spacing between toasts when expanded (default: 8)
    public var toastSpacing: CGFloat = 8
}
```

## 🎨 Customization

### Built-in Toast Styles

- **Success**: Green checkmark with white background
- **Error**: Red X with white background
- **Info**: Blue info icon with white background
- **Loading**: Spinning progress indicator with white background
- **Custom**: Fully customizable icon, colors, and background

### Custom Toast Styles

```swift
struct MyCustomStyle: ToastStyle {
    var iconName: String? { "heart.fill" }
    var iconColor: Color { .pink }
    var backgroundColor: Color { .white }
}

// Use it
toastManager.show(Toast(style: MyCustomStyle(), message: "I love this!"))
```

## ♿ Accessibility

Toasty is fully accessible and includes:

- **VoiceOver Support**: Automatic announcements when toasts appear and update
- **Semantic Labels**: Descriptive accessibility labels for all toast elements
- **Haptic Feedback**: Subtle haptic feedback on toast interactions
- **Screen Reader**: Proper navigation and reading order

## 📋 Requirements

- iOS 17.0+
- Swift 6.0+
- Xcode 15.0+

## 🏗️ Architecture

Toasty follows modern SwiftUI patterns:

- **Environment Injection**: Uses SwiftUI's environment system for dependency injection
- **Observable Objects**: Built on `@Observable` for state management
- **Async/Await**: Modern concurrency with `Task` and `async` functions
- **Sendable**: All types conform to `Sendable` for safe cross-actor usage
- **MainActor**: Proper main thread isolation for UI updates

## 🔍 API Reference

### ToastManager
The main class for managing toast notifications.

```swift
@MainActor
public final class ToastManager {
    // Show a toast
    @discardableResult
    public func show(_ toast: Toast, duration: Double?) -> ToastHandle

    // Toggle expanded/collapsed state
    public func toggleExpanded()

    // Pause/resume auto-dismiss timers
    public func pauseTimers()
    public func resumeTimers()
}
```

### ToastHandle
A handle for controlling individual toasts.

```swift
public struct ToastHandle: Hashable, Sendable {
    // Dismiss the toast
    @MainActor public func dismiss() async

    // Update the toast's content
    @MainActor public func update(style: any ToastStyle, message: String, duration: Double) async
}
```

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by modern toast notification patterns
- Built with SwiftUI's latest features and best practices
- Designed for accessibility and inclusive design principles

---

Made with ❤️ and SwiftUI
