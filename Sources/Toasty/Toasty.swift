import SwiftUI

// MARK: - ToastConfiguration

/// A configuration struct that customizes the behavior and appearance of toast notifications.
///
/// Use this struct to customize various aspects of toast presentation, including timing,
/// sizing, animations, and interaction behavior. All properties have sensible defaults
/// that work well for most use cases.
///
/// Example usage:
/// ```swift
/// let config = ToastConfiguration(
///     maxToasts: 5,
///     defaultDuration: 3.0,
///     toastWidth: 280
/// )
/// let toastManager = ToastManager(configuration: config)
/// ```
public struct ToastConfiguration: Sendable {
    /// The maximum number of toasts to display simultaneously.
    ///
    /// When this limit is exceeded, the oldest toast is automatically dismissed
    /// to make room for new ones. Defaults to 3.
    public var maxToasts: Int = 3

    /// The default duration in seconds before toasts auto-dismiss.
    ///
    /// Set to 0 to disable auto-dismissal entirely. Defaults to 4.5 seconds.
    public var defaultDuration: Double = 4.5

    /// The width of toast capsules in points.
    ///
    /// This affects the overall size of each toast notification. Defaults to 220 points.
    public var toastWidth: CGFloat = 220

    /// The duration of add/remove animations in seconds.
    ///
    /// Controls how quickly toasts appear and disappear. Defaults to 0.3 seconds.
    public var animationDuration: Double = 0.3

    /// The distance threshold in points for triggering dismiss on drag.
    ///
    /// Users must drag toasts at least this far to trigger dismissal. Defaults to 60 points.
    public var dismissTriggerDistance: CGFloat = 60

    /// The distance in points to animate toast offscreen when dismissed.
    ///
    /// Controls how far toasts move when being dismissed via drag gestures. Defaults to 500 points.
    public var offscreenDistance: CGFloat = 500

    /// The height of each row when toasts are expanded into a vertical list.
    ///
    /// Only applies when toasts are in expanded mode. Defaults to 44 points.
    public var expandedRowHeight: CGFloat = 44

    /// The damping factor for drag gestures (lower values = more resistance).
    ///
    /// Controls the resistance feel during drag interactions. Lower values make
    /// dragging feel more resistant. Defaults to 0.15.
    public var dragDampFactor: CGFloat = 0.15

    /// The maximum vertical damping distance during drag interactions.
    ///
    /// Limits how far toasts can be dragged vertically. Defaults to 12 points.
    public var dragMaxVerticalDamp: CGFloat = 12

    /// The maximum horizontal damping distance during drag interactions.
    ///
    /// Limits how far toasts can be dragged horizontally. Defaults to 20 points.
    public var dragMaxHorizontalDamp: CGFloat = 20

    /// The spacing between toasts when expanded into a vertical list.
    ///
    /// Controls the gap between individual toasts in expanded mode. Defaults to 8 points.
    public var toastSpacing: CGFloat = 8

    /// Creates a new toast configuration with default values.
    ///
    /// All properties are initialized with sensible defaults that work well
    /// for most applications. Modify individual properties as needed.
    public init() {}
}

// MARK: - ToastStyle Protocol

/// A protocol that defines the visual styling for toast notifications.
///
/// Types conforming to this protocol specify the appearance of toast notifications,
/// including the icon, icon color, and background color. The library provides
/// several built-in implementations while allowing for complete customization.
///
/// Example usage:
/// ```swift
/// struct MyCustomStyle: ToastStyle {
///     var iconName: String? { "star.fill" }
///     var iconColor: Color { .yellow }
///     var backgroundColor: Color { .purple.opacity(0.9) }
/// }
///
/// let toast = Toast(style: MyCustomStyle(), message: "Favorite!")
/// ```
public protocol ToastStyle: Sendable {
    /// The SF Symbol name that should appear to the left of the message.
    ///
    /// Set to `nil` to display no icon. Use SF Symbol names like "checkmark.circle.fill"
    /// or "exclamationmark.triangle.fill". The icon will be rendered in a monospaced
    /// style with semibold weight.
    var iconName: String? { get }

    /// The color of the icon.
    ///
    /// This color is applied to the SF Symbol icon. For best results, use colors
    /// that provide good contrast against the background color.
    var iconColor: Color { get }

    /// The background color of the toast capsule.
    ///
    /// This forms the main background of the toast notification. The toast also
    /// includes a subtle border and shadow for visual definition.
    var backgroundColor: Color { get }
}

/// An enumeration providing built-in toast styles for common use cases.
///
/// This enum offers convenient, pre-configured styles for success, error, and info toasts,
/// while also allowing complete customization. All styles use white backgrounds with
/// appropriate colored icons and can be further customized by providing custom colors.
///
/// Example usage:
/// ```swift
/// // Use default colors
/// let successToast = Toast.success("Data saved!")
///
/// // Customize icon color
/// let errorToast = Toast.error("Failed to save", iconColor: .orange)
///
/// // Fully custom style
/// let customToast = Toast.custom("Hello!", iconName: "hand.wave", backgroundColor: .blue)
/// ```
public enum DefaultToastStyle: ToastStyle, Sendable {
    /// A success style with a green checkmark icon.
    ///
    /// - Parameter iconColor: Optional custom color for the checkmark icon.
    ///                      Defaults to `.green` if not specified.
    case success(iconColor: Color? = nil)

    /// An error style with a red X icon.
    ///
    /// - Parameter iconColor: Optional custom color for the X icon.
    ///                      Defaults to `.red` if not specified.
    case error(iconColor: Color? = nil)

    /// An info style with a blue info icon.
    ///
    /// - Parameter iconColor: Optional custom color for the info icon.
    ///                      Defaults to `.blue` if not specified.
    case info(iconColor: Color? = nil)

    /// A fully customizable style allowing complete control over appearance.
    ///
    /// - Parameters:
    ///   - iconName: Optional SF Symbol name for the icon. Pass `nil` for no icon.
    ///   - iconColor: Optional color for the icon. Defaults to `.black` if not specified.
    ///   - backgroundColor: The background color for the toast. Defaults to `.white`.
    case custom(iconName: String? = nil, iconColor: Color? = nil, backgroundColor: Color = .white)

    /// The computed attributes for the current style case.
    private var attributes: (icon: String?, color: Color, background: Color) {
        switch self {
        case .success(let iconOverride):
            return ("checkmark.circle.fill", iconOverride ?? .green, .white)
        case .error(let iconOverride):
            return ("xmark.circle.fill", iconOverride ?? .red, .white)
        case .info(let iconOverride):
            return ("info.circle.fill", iconOverride ?? .blue, .white)
        case .custom(let iconName, let colorOverride, let backgroundColor):
            return (iconName, colorOverride ?? .black, backgroundColor)
        }
    }

    public var iconName: String? { attributes.icon }
    public var iconColor: Color { attributes.color }
    public var backgroundColor: Color { attributes.background }
}

// MARK: - LoadingToastStyle

/// A toast style that displays a loading spinner instead of a static icon.
///
/// This style is specifically designed for loading states and displays a circular
/// progress indicator. Unlike other toast styles, loading toasts are resistant to
/// dismissal gestures, ensuring users see the loading state until it's explicitly
/// updated or dismissed by the application.
///
/// Example usage:
/// ```swift
/// let loadingToast = Toast.loading("Uploading file...")
/// let handle = toastManager.show(loadingToast, duration: 0) // No auto-dismiss
///
/// // Later, update to success
/// await handle.update(style: .success(), message: "Upload complete!")
/// ```
public struct LoadingToastStyle: ToastStyle, Sendable {
    /// The icon name for this style. Always returns `nil` as the spinner is handled separately.
    public var iconName: String? { nil }

    /// The color of the loading spinner. Uses the primary color from the current color scheme.
    public var iconColor: Color { .primary }

    /// The background color of the toast. Uses white for consistency with other built-in styles.
    public var backgroundColor: Color { .white }

    /// Creates a new loading toast style.
    public init() {}
}

// MARK: - ToastHandle

/// A handle that provides imperative control over a displayed toast notification.
///
/// ToastHandle allows you to programmatically dismiss or update a toast after it's been
/// displayed, without needing to keep references to the toast manager or toast ID.
/// This is particularly useful for loading states that need to transition to success
/// or error states based on async operation results.
///
/// Example usage:
/// ```swift
/// // Show a loading toast and keep the handle
/// let handle = toastManager.show(.loading("Saving..."), duration: 0)
///
/// // Later, update it to success
/// await handle.update(style: .success(), message: "Saved successfully!")
///
/// // Or dismiss it early
/// await handle.dismiss()
/// ```
///
/// - Note: ToastHandle uses weak references to the toast manager, so handles become
///         ineffective if the manager is deallocated. Operations on invalid handles
///         are safe but have no effect.
public struct ToastHandle: Hashable, Sendable {
    /// The unique identifier of the toast this handle controls.
    fileprivate let id: UUID

    /// A weak reference to the toast manager that created this handle.
    fileprivate weak var manager: ToastManager?

    /// Creates a new toast handle.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the toast.
    ///   - manager: The toast manager that displayed the toast.
    fileprivate init(id: UUID, manager: ToastManager) {
        self.id = id
        self.manager = manager
    }

    /// Hashes the essential components of this value by feeding them into the given hasher.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: ToastHandle, rhs: ToastHandle) -> Bool {
        lhs.id == rhs.id
    }

    /// Dismisses the toast immediately, bypassing any auto-dismiss timer.
    ///
    /// This method provides a way to programmatically dismiss a toast before its
    /// natural expiration. If the toast is already dismissed or the manager is
    /// deallocated, this method has no effect.
    ///
    /// - Note: This operation is performed on the main actor to ensure UI safety.
    @MainActor
    public func dismiss() async {
        manager?.dismiss(id: id)
    }

    /// Updates the toast's style, message, and auto-dismiss duration.
    ///
    /// This method allows you to change multiple aspects of a toast simultaneously,
    /// which is particularly useful for transitioning loading states to final states.
    /// The toast will animate to the new appearance and reset its auto-dismiss timer.
    ///
    /// - Parameters:
    ///   - style: The new visual style for the toast.
    ///   - message: The new message text to display.
    ///   - duration: The new duration before auto-dismissal. Pass 0 for no auto-dismiss.
    ///
    /// - Note: This operation is performed on the main actor to ensure UI safety.
    @MainActor
    public func update(style: any ToastStyle, message: String, duration: Double) async {
        manager?.update(id: id, style: style, message: message, duration: duration)
    }
}

// MARK: - Toast

/// A model representing a toast notification with its style and content.
///
/// Toast encapsulates the visual appearance and message content for a notification.
/// Each toast has a unique identifier and timestamp, and can be styled using any
/// type that conforms to the `ToastStyle` protocol.
///
/// Example usage:
/// ```swift
/// // Create a success toast
/// let toast = Toast.success("Data saved successfully!")
///
/// // Create a custom toast
/// let customToast = Toast.custom(
///     "Custom message",
///     iconName: "star.fill",
///     backgroundColor: .purple
/// )
/// ```
public struct Toast: Identifiable, Sendable {
    /// A unique identifier for this toast instance.
    public let id = UUID()

    /// The visual style defining the toast's appearance.
    public var style: any ToastStyle

    /// The message text displayed in the toast.
    public var message: String

    /// The date and time when this toast was created.
    public let createdAt = Date()

    /// Creates a new toast with the specified style and message.
    ///
    /// - Parameters:
    ///   - style: The visual style for the toast's appearance.
    ///   - message: The text message to display in the toast.
    public nonisolated init(style: any ToastStyle, message: String) {
        self.style = style
        self.message = message
    }
}

// MARK: - Toast Convenience Methods

extension Toast {
    /// Creates a success toast with a green checkmark icon.
    ///
    /// - Parameters:
    ///   - message: The message to display in the toast.
    ///   - iconColor: Optional custom color for the checkmark icon. Defaults to green.
    /// - Returns: A new toast configured with success styling.
    public static func success(_ message: String, iconColor: Color? = nil) -> Toast {
        Toast(style: DefaultToastStyle.success(iconColor: iconColor), message: message)
    }

    /// Creates an error toast with a red X icon.
    ///
    /// - Parameters:
    ///   - message: The message to display in the toast.
    ///   - iconColor: Optional custom color for the X icon. Defaults to red.
    /// - Returns: A new toast configured with error styling.
    public static func error(_ message: String, iconColor: Color? = nil) -> Toast {
        Toast(style: DefaultToastStyle.error(iconColor: iconColor), message: message)
    }

    /// Creates an info toast with a blue info icon.
    ///
    /// - Parameters:
    ///   - message: The message to display in the toast.
    ///   - iconColor: Optional custom color for the info icon. Defaults to blue.
    /// - Returns: A new toast configured with info styling.
    public static func info(_ message: String, iconColor: Color? = nil) -> Toast {
        Toast(style: DefaultToastStyle.info(iconColor: iconColor), message: message)
    }

    /// Creates a loading toast with a spinning progress indicator.
    ///
    /// - Parameter message: The message to display in the toast. Defaults to "Loading…".
    /// - Returns: A new toast configured with loading styling.
    public static func loading(_ message: String = "Loading…") -> Toast {
        Toast(style: LoadingToastStyle(), message: message)
    }

    /// Creates a custom toast with full control over appearance.
    ///
    /// - Parameters:
    ///   - message: The message to display in the toast.
    ///   - iconName: Optional SF Symbol name for the icon. Pass `nil` for no icon.
    ///   - iconColor: Optional color for the icon. Defaults to black if not specified.
    ///   - backgroundColor: The background color for the toast. Defaults to white.
    /// - Returns: A new toast configured with custom styling.
    public static func custom(_ message: String,
                              iconName: String? = nil,
                              iconColor: Color? = nil,
                              backgroundColor: Color = .white) -> Toast {
        Toast(style: DefaultToastStyle.custom(iconName: iconName,
                                              iconColor: iconColor,
                                              backgroundColor: backgroundColor),
              message: message)
    }
}

// MARK: - ToastView

/// A view that renders a single toast notification with its styling and accessibility features.
private struct ToastView: View {
    /// The visual style defining the toast's appearance.
    let style: any ToastStyle

    /// The message text to display in the toast.
    let message: String

    /// The configuration controlling toast behavior and appearance.
    let configuration: ToastConfiguration

    // MARK: - Accessibility

    /// A computed description for VoiceOver accessibility.
    private var accessibilityDescription: String {
        var components: [String] = []

        // Add icon description based on the toast style
        if let iconName = style.iconName {
            let iconDescription = iconAccessibilityDescription(for: iconName)
            components.append(iconDescription)
        } else if style is LoadingToastStyle {
            components.append("Loading")
        }

        // Add the message content
        components.append(message)

        return components.joined(separator: ". ")
    }
    
    /// Provides an accessibility description for the given SF Symbol name.
    ///
    /// - Parameter iconName: The SF Symbol name to describe.
    /// - Returns: A human-readable description of the icon's meaning.
    private func iconAccessibilityDescription(for iconName: String) -> String {
        switch iconName {
        case "checkmark.circle.fill":
            return "Success"
        case "xmark.circle.fill":
            return "Error"
        case "info.circle.fill":
            return "Information"
        case "star.fill":
            return "Star"
        default:
            // For custom icons, derive a meaningful description from the symbol name
            return iconName.replacingOccurrences(of: ".", with: " ")
                          .replacingOccurrences(of: "_", with: " ")
                          .capitalized
        }
    }

    /// The body of the ToastView, containing the icon, message, and styling.
    var body: some View {
        HStack {
            // Display icon or loading indicator based on style
            if let icon = style.iconName {
                Image(systemName: icon)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(style.iconColor)
                    .contentTransition(.symbolEffect(.replace.offUp))
            } else if style is LoadingToastStyle {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(style.iconColor)
                    .contentTransition(.opacity)
            }

            // Display the message text
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .contentTransition(.interpolate)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: configuration.toastWidth)
        .background(
            Capsule()
                .fill(style.backgroundColor)
                .contentTransition(.interpolate)
        )
        .overlay(
            Capsule()
                .stroke(.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Toast notification. Swipe to dismiss.")
        .accessibilityAddTraits(.isStaticText)
        .contentTransition(.interpolate)
    }
}

// MARK: - ToastDismissAxis

/// Defines the axes along which a toast can be dismissed via drag gestures.
public enum ToastDismissAxis {
    /// Allows dismissal by dragging horizontally (left or right).
    case horizontal

    /// Allows dismissal by dragging vertically (up or down).
    case vertical

    /// Allows dismissal by dragging in both horizontal and vertical directions.
    case both

    /// Disables drag-to-dismiss functionality entirely.
    case none
}

// MARK: - DragDismissModifier

/// A view modifier that adds drag-to-dismiss functionality to toast notifications.
///
/// This modifier handles the complex logic for drag gestures, including damping,
/// threshold detection, and different behaviors based on the toast type and position.
/// It provides smooth, intuitive dismissal interactions while respecting the toast's
/// configuration and current state.
private struct DragDismissModifier: ViewModifier {
    /// The configuration controlling drag behavior and appearance.
    let configuration: ToastConfiguration

    /// The axes along which dismissal is allowed.
    let allowed: ToastDismissAxis

    /// The distance threshold that must be exceeded to trigger dismissal.
    var threshold: CGFloat { configuration.dismissTriggerDistance }

    /// Whether this toast should have stiff (resistant) drag behavior.
    let isStiff: Bool

    /// The closure to execute when the toast should be dismissed.
    let onDismiss: () -> Void

    /// The toast manager from the environment.
    @Environment(\.toastManager) private var manager

    /// The current offset of the toast during dragging.
    @State private var offset: CGSize = .zero

    /// The current opacity of the toast during dragging.
    @State private var opacity: Double = 1

    /// Whether timers have been paused during the current drag operation.
    @State private var timersPaused = false

    /// Whether damping should be applied during the current drag operation.
    @State private var dampDuringDrag = false

    /// Applies the drag dismiss behavior to the modified content.
    func body(content: Content) -> some View {
        content
            .offset(x: offset.width, y: offset.height)
            .opacity(opacity)
            .gesture(
                DragGesture()
                    .onChanged { value in handleChanged(value) }
                    .onEnded { value in handleEnded(value) }
            )
    }

    // MARK: - Gesture Handlers

    /// Handles changes in the drag gesture, updating the toast's position and state.
    ///
    /// - Parameter value: The current drag gesture value containing translation information.
    private func handleChanged(_ value: DragGesture.Value) {
        guard allowed != .none else { return }

        // Pause timers on first drag movement if not already expanded
        if !timersPaused && !manager.isExpanded {
            manager.pauseTimers()
            timersPaused = true
        }

        let t = value.translation

        // Enable damping on initial drag
        if offset == .zero {
            dampDuringDrag = isStiff
        }

        // Apply vertical damping based on drag direction and constraints
        var limitedY: CGFloat
        if t.height > 0 {
            // Downward drag is always slightly damped for better feel
            limitedY = min(t.height * configuration.dragDampFactor, configuration.dragMaxVerticalDamp)
        } else {
            // Upward drag: damp only when vertical dismissal is not allowed
            if manager.isExpanded || isStiff {
                limitedY = -min(abs(t.height) * configuration.dragDampFactor, configuration.dragMaxVerticalDamp)
            } else {
                limitedY = t.height
            }
        }

        // Apply horizontal damping for non-dismissable cases
        var limitedX: CGFloat
        if dampDuringDrag || isStiff {
            let damped = min(abs(t.width) * configuration.dragDampFactor, configuration.dragMaxHorizontalDamp)
            limitedX = (t.width >= 0 ? 1 : -1) * damped
        } else {
            limitedX = t.width
        }

        offset = CGSize(width: limitedX, height: limitedY)
    }

    /// Handles the end of a drag gesture, determining whether to dismiss the toast.
    ///
    /// This method analyzes the final drag position and velocity to decide whether
    /// the dismissal threshold has been exceeded. If dismissal is triggered, it
    /// animates the toast offscreen and executes the dismiss closure.
    ///
    /// - Parameter value: The final drag gesture value.
    private func handleEnded(_ value: DragGesture.Value) {
        defer {
            // Clean up state after handling the gesture
            if timersPaused && !manager.isExpanded {
                manager.resumeTimers()
                timersPaused = false
            }
            dampDuringDrag = false
        }

        guard allowed != .none else {
            // Reset position for non-dismissable toasts
            withAnimation(.spring()) {
                offset = .zero; opacity = 1
            }
            return
        }

        let dx = value.translation.width
        let dy = value.translation.height

        // Check which dismissal directions are allowed
        let canHorizontal = allowed == .horizontal || allowed == .both
        let canVertical   = allowed == .vertical   || allowed == .both

        // Determine the predominant drag direction
        let isHorizontal = abs(dx) >= abs(dy)
        let horizontalTrigger = canHorizontal && abs(dx) > threshold && isHorizontal && !isStiff
        let verticalTrigger   = canVertical   && dy < -threshold      && !isHorizontal && !manager.isExpanded && !isStiff

        guard horizontalTrigger || verticalTrigger else {
            // Threshold not exceeded, reset to original position
            withAnimation(.spring()) { offset = .zero; opacity = 1 }
            return
        }

        // Animate dismissal offscreen
        withAnimation(.easeIn(duration: 0.2)) {
            if horizontalTrigger {
                let directionX: CGFloat = dx >= 0 ? 1 : -1
                offset = CGSize(width: directionX * configuration.offscreenDistance, height: dy)
            } else {
                // Pure upward dismissal
                offset = CGSize(width: dx * 0.3, height: -configuration.offscreenDistance)
            }
            opacity = 0
        }

        // Execute dismiss closure after animation completes
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            onDismiss()
        }
    }
}



// MARK: - ToastManager

/// The central manager for displaying and controlling toast notifications.
///
/// ToastManager coordinates the display, animation, and lifecycle of toast notifications
/// throughout your SwiftUI application. It handles queuing, auto-dismissal, drag gestures,
/// and accessibility features.
///
/// ## Basic Usage
///
/// ```swift
/// // Set up in your app
/// @main
/// struct MyApp: App {
///     @StateObject private var toastManager = ToastManager()
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(\.toastManager, toastManager)
///                 .toasts()
///         }
///     }
/// }
///
/// // Use in your views
/// struct ContentView: View {
///     @Environment(\.toastManager) private var toastManager
///
///     var body: some View {
///         Button("Show Success") {
///             toastManager.show(.success("Data saved!"))
///         }
///     }
/// }
/// ```
///
/// ## Advanced Features
///
/// ToastManager supports:
/// - Multiple simultaneous toasts with automatic queuing
/// - Drag-to-dismiss gestures with haptic feedback
/// - Expandable toast stack for reviewing multiple notifications
/// - Loading states with automatic state transitions
/// - Full VoiceOver accessibility support
/// - Customizable timing and appearance
///
/// - Note: ToastManager is an `@Observable` object and should be injected
///         through the SwiftUI environment for proper state management.
@Observable
@MainActor
public final class ToastManager {

    /// The currently displayed toasts, ordered from oldest to newest.
    ///
    /// This array contains all active toast notifications. The first element is the oldest
    /// toast, and the last element is the most recent. When the toast limit is exceeded,
    /// the oldest toast is automatically removed.
    public private(set) var toasts: [Toast] = []

    /// A Boolean value indicating whether the toast stack is currently expanded.
    ///
    /// When `true`, toasts are displayed in a vertical list that users can scroll through.
    /// When `false`, toasts are displayed in a compact stack with the most recent toast
    /// on top. Users can tap the stack to toggle this state.
    public var isExpanded: Bool = false

    /// The configuration that controls toast behavior and appearance.
    ///
    /// This configuration is set during initialization and cannot be changed afterwards.
    /// It defines timing, sizing, animations, and interaction behavior for all toasts
    /// managed by this instance.
    public let configuration: ToastConfiguration

    // Unified countdown storage replacing individual timer dictionaries
    private struct Countdown {
        var task: Task<Void, Never>?
        var expiry: Date?
        var remaining: Double?
    }
    private var countdowns: [UUID: Countdown] = [:]

    // Computed animation properties using configuration
    private var addAnimation: Animation {
        Animation.timingCurve(0.25, 0.2, 0.25, 1, duration: configuration.animationDuration)
    }
    private var removeAnimation: Animation {
        Animation.timingCurve(0.25, 0.2, 0.25, 1, duration: configuration.animationDuration * 0.67) // Slightly faster for removal
    }

    /// Creates a new toast manager with the specified configuration.
    ///
    /// - Parameter configuration: The configuration to use for toast behavior and appearance.
    ///                          If not specified, uses default configuration values.
    public init(configuration: ToastConfiguration = .init()) {
        self.configuration = configuration
    }

    // MARK: - Public API

    /// Displays a toast notification and returns a handle for controlling it.
    ///
    /// This is the primary method for showing toast notifications. The toast will be
    /// displayed immediately if there's space, or queued if the maximum number of
    /// toasts is already showing.
    ///
    /// - Parameters:
    ///   - toast: The toast notification to display.
    ///   - duration: The duration in seconds before auto-dismissal. If `nil`, uses
    ///               the default duration from the configuration. Pass `0` to disable
    ///               auto-dismissal entirely.
    /// - Returns: A handle that can be used to programmatically control the toast.
    ///
    /// Example usage:
    /// ```swift
    /// // Show a toast that auto-dismisses after 3 seconds
    /// let handle = toastManager.show(.success("Saved!"), duration: 3)
    ///
    /// // Show a loading toast that doesn't auto-dismiss
    /// let loadingHandle = toastManager.show(.loading("Processing..."), duration: 0)
    /// ```
    @discardableResult
    public func show(_ toast: Toast, duration: Double? = nil) -> ToastHandle {
        enqueue(toast: toast, duration: duration)
        return ToastHandle(id: toast.id, manager: self)
    }

    /// Toggles between collapsed and expanded toast display modes.
    ///
    /// In collapsed mode, toasts are displayed as a compact stack with the most recent
    /// toast on top. In expanded mode, toasts are displayed as a vertical list that
    /// users can scroll through. This method is typically called in response to user
    /// interaction (such as tapping the toast area).
    ///
    /// When expanding:
    /// - Auto-dismiss timers are paused so users can read all notifications
    /// - Only takes effect if there are multiple toasts to display
    ///
    /// When collapsing:
    /// - Auto-dismiss timers are resumed
    /// - The toast stack returns to the compact display mode
    public func toggleExpanded() {
        if isExpanded {
            // Collapse back to stack ⇒ resume timers
            isExpanded = false
            resumeTimers()
        } else {
            guard toasts.count > 1 else { return } // nothing to expand
            isExpanded = true
            pauseTimers()
        }
    }

    // MARK: - Internal Methods

    /// Enqueues a toast for display with the specified duration.
    ///
    /// This internal method handles the actual display logic, including queue management,
    /// animation, and timer scheduling. Use the public `show(_:duration:)` method instead.
    ///
    /// - Parameters:
    ///   - toast: The toast to display.
    ///   - duration: The duration before auto-dismissal, or `nil` to use the default.
    internal func enqueue(toast: Toast, duration: Double?) {
        let actualDuration = duration ?? configuration.defaultDuration

        withAnimation(addAnimation) {
            // Remove oldest toast if we've reached the maximum
            if toasts.count >= configuration.maxToasts, let oldest = toasts.first {
                cancelCountdown(for: oldest.id)
                toasts.removeFirst()
            }

            toasts.append(toast)

            // Set up auto-dismissal timer based on current state
            if isExpanded {
                countdowns[toast.id] = Countdown(task: nil, expiry: nil, remaining: actualDuration)
            } else {
                scheduleCountdown(for: toast, after: actualDuration)
            }
        }

        // Announce the new toast to VoiceOver users for accessibility
        announceToastForAccessibility(toast)
    }
    
    // MARK: - Accessibility Support

    /// Announces a toast to VoiceOver users for accessibility.
    ///
    /// This method creates a descriptive announcement that includes the toast's
    /// status (success, error, info, or loading) followed by the message content.
    /// Only active when VoiceOver is running.
    ///
    /// - Parameter toast: The toast to announce.
    private func announceToastForAccessibility(_ toast: Toast) {
        #if os(iOS)
        guard UIAccessibility.isVoiceOverRunning else { return }

        var announcement = ""

        // Add status description based on the toast style
        if let iconName = toast.style.iconName {
            switch iconName {
            case "checkmark.circle.fill":
                announcement += "Success. "
            case "xmark.circle.fill":
                announcement += "Error. "
            case "info.circle.fill":
                announcement += "Information. "
            default:
                break
            }
        } else if toast.style is LoadingToastStyle {
            announcement += "Loading. "
        }

        // Add the message content
        announcement += toast.message

        UIAccessibility.post(notification: .announcement, argument: announcement)
        #endif
    }

    // MARK: - Timer Management

    /// Schedules an auto-dismissal countdown for a toast.
    ///
    /// Creates an asynchronous task that will automatically dismiss the toast
    /// after the specified duration. The countdown can be paused, resumed, or cancelled.
    ///
    /// - Parameters:
    ///   - toast: The toast to schedule dismissal for.
    ///   - seconds: The duration in seconds before dismissal.
    private func scheduleCountdown(for toast: Toast, after seconds: Double) {
        guard seconds > 0 else { return }

        let expiry = Date().addingTimeInterval(seconds)
        cancelCountdown(for: toast.id)

        let task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            if !Task.isCancelled {
                await MainActor.run {
                    guard let self else { return }
                    withAnimation(self.removeAnimation) {
                        self.toasts.removeAll { $0.id == toast.id }
                        self.countdowns.removeValue(forKey: toast.id)
                        self.collapseIfNeeded()
                    }
                }
            }
        }

        countdowns[toast.id] = Countdown(task: task, expiry: expiry, remaining: nil)
    }

    /// Cancels the auto-dismissal countdown for a specific toast.
    ///
    /// - Parameter id: The unique identifier of the toast to cancel.
    private func cancelCountdown(for id: UUID) {
        countdowns[id]?.task?.cancel()
        countdowns.removeValue(forKey: id)
    }

    /// Calculates the remaining time before a toast's auto-dismissal.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the toast.
    ///   - now: The reference date for calculation. Defaults to current date.
    /// - Returns: The remaining seconds, or `nil` if no countdown exists.
    private func remainingTime(for id: UUID, reference now: Date = Date()) -> Double? {
        if let explicit = countdowns[id]?.remaining { return explicit }
        if let expiry = countdowns[id]?.expiry { return max(0, expiry.timeIntervalSince(now)) }
        return nil
    }

    /// Pauses all active auto-dismissal timers.
    ///
    /// This method is called when users start interacting with toasts (e.g., dragging)
    /// to prevent unexpected dismissals during interaction.
    @MainActor
    public func pauseTimers() {
        let now = Date()
        for id in toasts.map({ $0.id }) {
            guard var countdown = countdowns[id] else { continue }
            if let expiry = countdown.expiry {
                countdown.remaining = max(0, expiry.timeIntervalSince(now))
            }
            countdown.expiry = nil
            countdown.task?.cancel()
            countdown.task = nil
            countdowns[id] = countdown
        }
    }

    /// Resumes all paused auto-dismissal timers.
    ///
    /// Restores the countdown timers that were paused during user interaction.
    /// Toasts with expired timers during pause are dismissed immediately.
    @MainActor
    public func resumeTimers() {
        for toast in toasts {
            guard var countdown = countdowns[toast.id] else { continue }
            let remaining = countdown.remaining ?? configuration.defaultDuration
            countdown.remaining = nil
            countdowns[toast.id] = countdown
            if remaining > 0 {
                scheduleCountdown(for: toast, after: remaining)
            } else {
                withAnimation(removeAnimation) {
                    toasts.removeAll { $0.id == toast.id }
                }
            }
        }
    }

    /// Automatically collapses the expanded toast stack when appropriate.
    ///
    /// This method checks if the toast stack should collapse back to the compact
    /// mode. It collapses when there are 1 or fewer toasts remaining in an expanded state.
    private func collapseIfNeeded() {
        if toasts.count <= 1 && isExpanded {
            isExpanded = false
            resumeTimers()
        }
    }

    /// Immediately dismisses a specific toast.
    ///
    /// This method provides a convenient way to dismiss a toast by passing the toast instance.
    /// It's typically called from gesture handlers when users dismiss toasts via interaction.
    ///
    /// - Parameter toast: The toast to dismiss.
    @MainActor
    public func dismiss(_ toast: Toast) {
        dismiss(id: toast.id)
    }

    /// Immediately dismisses a toast by its unique identifier.
    ///
    /// This internal method handles the actual dismissal logic, including animation
    /// and cleanup of associated timers and state.
    ///
    /// - Parameter id: The unique identifier of the toast to dismiss.
    @MainActor
    internal func dismiss(id: UUID) {
        cancelCountdown(for: id)
        withAnimation(removeAnimation) {
            toasts.removeAll { $0.id == id }
            collapseIfNeeded()
        }
    }

    /// Updates an existing toast's content and reschedules its dismissal.
    ///
    /// This method provides a convenient way to update a toast by passing the toast instance.
    /// It's typically used when transitioning loading states to final states.
    ///
    /// - Parameters:
    ///   - toast: The toast to update.
    ///   - style: The new visual style for the toast.
    ///   - message: The new message text.
    ///   - duration: The new duration before auto-dismissal.
    @MainActor
    public func updateToast(_ toast: Toast,
                            style: any ToastStyle,
                            message: String,
                            duration: Double) {
        update(id: toast.id, style: style, message: message, duration: duration)
    }

    /// Updates a toast's content by its unique identifier.
    ///
    /// This internal method handles the actual update logic, including animation,
    /// timer rescheduling, and accessibility announcements.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the toast to update.
    ///   - style: The new visual style for the toast.
    ///   - message: The new message text.
    ///   - duration: The new duration before auto-dismissal.
    @MainActor
    internal func update(id: UUID, style: any ToastStyle, message: String, duration: Double) {
        guard let index = toasts.firstIndex(where: { $0.id == id }) else { return }

        // Cancel any outstanding countdown for this toast
        cancelCountdown(for: id)

        withAnimation(addAnimation) {
            toasts[index].style = style
            toasts[index].message = message
        }

        // Reschedule dismissal based on current state
        if !isExpanded {
            scheduleCountdown(for: toasts[index], after: duration)
        } else {
            countdowns[id] = Countdown(task: nil, expiry: nil, remaining: duration)
        }

        // Announce the updated toast to VoiceOver users
        announceToastForAccessibility(toasts[index])
    }
}

// MARK: - Environment Infrastructure

/// Environment key for injecting ToastManager instances into the SwiftUI environment.
///
/// This key enables proper dependency injection of ToastManager instances through
/// SwiftUI's environment system, replacing the singleton pattern with a more
/// flexible and testable approach.
@MainActor
public struct ToastManagerKey: @preconcurrency EnvironmentKey {
    /// The default ToastManager instance to use when none is explicitly provided.
    public static let defaultValue = ToastManager()
}

public extension EnvironmentValues {
    /// Accesses the current ToastManager from the SwiftUI environment.
    ///
    /// This computed property provides access to the ToastManager instance that
    /// has been injected into the environment, either explicitly or through the default value.
    ///
    /// Example usage:
    /// ```swift
    /// struct MyView: View {
    ///     @Environment(\.toastManager) private var toastManager
    ///
    ///     var body: some View {
    ///         Button("Show Toast") {
    ///             toastManager.show(.success("Hello!"))
    ///         }
    ///     }
    /// }
    /// ```
    var toastManager: ToastManager {
        get { self[ToastManagerKey.self] }
        set { self[ToastManagerKey.self] = newValue }
    }
}

public extension View {
    /// Injects a custom ToastManager into the environment for this view and its descendants.
    ///
    /// This method allows you to provide a custom-configured ToastManager instance
    /// to a specific view hierarchy, enabling different toast behaviors in different
    /// parts of your app.
    ///
    /// - Parameter manager: The ToastManager instance to inject into the environment.
    /// - Returns: A view with the specified ToastManager injected into its environment.
    ///
    /// Example usage:
    /// ```swift
    /// let customConfig = ToastConfiguration(maxToasts: 1, defaultDuration: 2.0)
    /// let customManager = ToastManager(configuration: customConfig)
    ///
    /// ContentView()
    ///     .toastManager(customManager)
    /// ```
    func toastManager(_ manager: ToastManager) -> some View {
        environment(\.toastManager, manager)
    }

    /// Adds a toast overlay to this view, following SwiftUI patterns like `.alert()` and `.sheet()`.
    ///
    /// This method overlays the ToastHost view on top of the current view, enabling
    /// toast notifications to appear. The ToastManager must be available in the environment
    /// (either explicitly injected or using the default).
    ///
    /// - Returns: A view with the ToastHost overlaid at the top.
    ///
    /// Example usage:
    /// ```swift
    /// ContentView()
    ///     .toastManager(myManager)  // Optional: inject custom manager
    ///     .toasts()                  // Add toast overlay
    /// ```
    func toasts() -> some View {
        overlay(alignment: .top) {
            ToastHost()
        }
    }
}

// MARK: - Loading Task Helper

extension ToastManager {
    /// Shows a toast that automatically transitions from loading to success or error state.
    ///
    /// This convenience method simplifies the common pattern of showing a loading indicator
    /// during an async operation and then updating the toast based on the result.
    /// The toast starts in a loading state and automatically updates when the operation completes.
    ///
    /// Example usage:
    /// ```swift
    /// @Environment(\.toastManager) private var toastManager
    ///
    /// func saveData() async throws -> Int {
    ///     // Some async operation that returns a count
    ///     return 42
    /// }
    ///
    /// // Show loading toast that updates based on operation result
    /// let task = ToastManager.showLoadingTask(
    ///     manager: toastManager,
    ///     loadingMessage: "Saving data...",
    ///     operation: { try await saveData() },
    ///     success: { count in "Saved \(count) items successfully!" },
    ///     failure: { error in "Failed to save: \(error.localizedDescription)" }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - manager: The ToastManager instance to use for displaying the toast.
    ///   - loadingMessage: The message to display while the operation is in progress.
    ///   - operation: The asynchronous operation to perform.
    ///   - success: A closure that builds the success message using the operation's return value.
    ///   - failure: A closure that builds the error message using any thrown error.
    ///   - successDuration: How long to show the success toast before auto-dismissal.
    ///   - failureDuration: How long to show the error toast before auto-dismissal.
    /// - Returns: A Task that represents the loading operation. Can be cancelled if needed.
    @discardableResult
    public static func showLoadingTask<T: Sendable>(
        manager: ToastManager,
        loadingMessage: String = "Loading…",
        operation: @escaping () async throws -> T,
        success: @escaping (T) -> String,
        failure: @escaping (Error) -> String,
        successDuration: Double = 2,
        failureDuration: Double = 2
    ) -> Task<Void, Never> {
        let loadingToast = Toast.loading(loadingMessage)

        // Present loading toast immediately and get handle for updates
        let handle = manager.show(loadingToast, duration: 0) // 0 = no auto-dismiss

        // Perform the operation and update the toast based on the result
        return Task {
            do {
                let value = try await operation()
                let successMessage = success(value)
                await handle.update(style: DefaultToastStyle.success(),
                                  message: successMessage,
                                  duration: successDuration)
            } catch {
                let errorMessage = failure(error)
                await handle.update(style: DefaultToastStyle.error(),
                                  message: errorMessage,
                                  duration: failureDuration)
            }
        }
    }
}

/// A SwiftUI view that displays and manages the visual presentation of toast notifications.
///
/// ToastHost is responsible for rendering the toast stack, handling user interactions
/// like drag gestures and taps, and coordinating with the ToastManager for state changes.
/// It automatically adapts its layout between collapsed (stack) and expanded (list) modes.
///
/// This view should be overlaid on your content using the `.toasts()` view modifier.
/// It requires a ToastManager to be available in the environment.
///
/// Example usage:
/// ```swift
/// ContentView()
///     .environment(\.toastManager, ToastManager())
///     .toasts()  // This adds ToastHost as an overlay
/// ```
public struct ToastHost: View {
    /// The ToastManager instance from the environment.
    @Environment(\.toastManager) private var manager

    /// Namespace for coordinating matched geometry effects during animations.
    @Namespace private var toastNamespace

    /// Creates a new ToastHost instance.
    public init() {}

    private var spacing: CGFloat { manager.configuration.toastSpacing }
    private var addAnimation: Animation {
        Animation.timingCurve(0.25, 0.2, 0.25, 1, duration: manager.configuration.animationDuration)
    }

    // MARK: - Layout Helpers

    /// Calculates layout information for a toast at the specified position.
    ///
    /// This method determines the visual properties (position, scale, opacity) for each
    /// toast based on its position in the stack and whether the stack is expanded or collapsed.
    ///
    /// - Parameters:
    ///   - index: The zero-based index of the toast in the current display order.
    ///   - total: The total number of toasts being displayed.
    ///   - isExpanded: Whether the toast stack is in expanded mode.
    /// - Returns: A tuple containing z-index, offset, scale, and opacity values.
    private func layoutInfo(for index: Int, total: Int, isExpanded: Bool) -> (z: Double, offset: CGSize, scale: CGFloat, opacity: Double) {
        // When expanded, arrange toasts vertically with fixed spacing.
        // When collapsed, create a card-stack effect with offset and scaling.
        if isExpanded {
            return (
                z: Double(index),
                offset: CGSize(width: 0, height: CGFloat(index) * manager.configuration.expandedRowHeight),
                scale: 1,
                opacity: 1
            )
        } else {
            let backness = total - 1 - index
            let isOverLimit = index == 0 && total > manager.configuration.maxToasts
            return (
                z: Double(index),
                offset: CGSize(width: 0, height: -CGFloat(backness) * 10),
                scale: 1 - CGFloat(backness) * 0.05,
                opacity: isOverLimit ? 0 : 1
            )
        }
    }

    /// The computed view containing all visible toasts with their layout and interaction handling.
    private var toastList: some View {
        let toastsToShow = manager.isExpanded ? Array(manager.toasts.suffix(manager.configuration.maxToasts)) : manager.toasts

        return ForEach(Array(toastsToShow.enumerated()), id: \.element.id) { index, toast in
            let layout = layoutInfo(for: index, total: toastsToShow.count, isExpanded: manager.isExpanded)

            // Determine drag behavior based on position and toast type
            let isDraggable = manager.isExpanded || index == toastsToShow.count - 1
            let allowedAxis: ToastDismissAxis = {
                if !isDraggable { return .none }
                if toast.style is LoadingToastStyle { return .both } // allow movement but no dismissal (stiff)
                return manager.isExpanded ? .horizontal : .both
            }()
            let stiff = toast.style is LoadingToastStyle

            ToastView(style: toast.style, message: toast.message, configuration: manager.configuration)
                .modifier(
                    DragDismissModifier(
                        configuration: manager.configuration,
                        allowed: allowedAxis,
                        isStiff: stiff,
                        onDismiss: { manager.dismiss(toast) }
                    )
                )
                .matchedGeometryEffect(id: toast.id, in: toastNamespace)
                .offset(layout.offset)
                .scaleEffect(layout.scale)
                .opacity(layout.opacity)
                .zIndex(layout.z)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: -16)),
                    removal: .opacity.combined(with: .offset(y: -16))
                ))
        }
    }

    /// The body of the ToastHost view, containing the toast stack with interaction handling.
    public var body: some View {
        ZStack {
            toastList
        }
        .padding(.top, 12)
        .onTapGesture {
            withAnimation(addAnimation) {
                manager.toggleExpanded()
            }
        }
        .accessibilityAction(named: manager.isExpanded ? "Collapse toasts" : "Expand toasts") {
            withAnimation(addAnimation) {
                manager.toggleExpanded()
            }
        }
    }
}

