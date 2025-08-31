import SwiftUI
// This allows users to just: import SwiftUIToast

// MARK: - ToastConfiguration

/// Configuration struct for customizing toast behavior and appearance.
/// All values have sensible defaults that can be overridden.
public struct ToastConfiguration: Sendable {
    /// Maximum number of toasts to display simultaneously
    public var maxToasts: Int = 3

    /// Default duration in seconds before toasts auto-dismiss (0 = no auto-dismiss)
    public var defaultDuration: Double = 4.5

    /// Width of toast capsules
    public var toastWidth: CGFloat = 220

    /// Duration of add/remove animations in seconds
    public var animationDuration: Double = 0.3

    /// Distance threshold for triggering dismiss on drag
    public var dismissTriggerDistance: CGFloat = 60

    /// Distance to animate toast offscreen when dismissed
    public var offscreenDistance: CGFloat = 500

    /// Height of each row when toasts are expanded
    public var expandedRowHeight: CGFloat = 44

    /// Damping factor for drag gestures (lower = more resistance)
    public var dragDampFactor: CGFloat = 0.15

    /// Maximum vertical damping distance during drag
    public var dragMaxVerticalDamp: CGFloat = 12

    /// Maximum horizontal damping distance during drag
    public var dragMaxHorizontalDamp: CGFloat = 20

    /// Spacing between toasts when expanded
    public var toastSpacing: CGFloat = 8

    public init() {}
}

// MARK: - ToastStyle Protocol
public protocol ToastStyle: Sendable {
    /// The SF Symbol name that should appear to the left of the message. `nil` means no icon.
    var iconName: String? { get }
    /// The colour of that icon.
    var iconColor: Color { get }
    /// The background colour of the toast capsule.
    var backgroundColor: Color { get }
}

/// A small convenience enum that ships with three out-of-the-box styles while still
/// allowing callers to define their own `ToastStyle` conformances.
public enum DefaultToastStyle: ToastStyle, Sendable {
    case success(iconColor: Color? = nil)
    case error(iconColor: Color? = nil)
    case info(iconColor: Color? = nil)
    case custom(iconName: String? = nil, iconColor: Color? = nil, backgroundColor: Color = .white)

    // Consolidated associated attributes
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

// MARK: - Loading Toast Style
public struct LoadingToastStyle: ToastStyle, Sendable {
    public var iconName: String? { nil } // Spinner handled separately
    public var iconColor: Color { .primary }
    public var backgroundColor: Color { .white }
    public init() {}
}

// MARK: - Toast Handle

/// A handle for controlling a displayed toast imperatively.
/// Provides methods to dismiss or update the toast without needing to track the manager or toast ID.
public struct ToastHandle: Hashable, Sendable {
    fileprivate let id: UUID
    fileprivate weak var manager: ToastManager?

    fileprivate init(id: UUID, manager: ToastManager) {
        self.id = id
        self.manager = manager
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ToastHandle, rhs: ToastHandle) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Dismisses this toast immediately.
    @MainActor
    public func dismiss() async {
        manager?.dismiss(id: id)
    }
    
    /// Updates this toast's style, message, and duration.
    /// - Parameters:
    ///   - style: The new style for the toast
    ///   - message: The new message for the toast
    ///   - duration: The new duration before auto-dismissal (0 = no auto-dismiss)
    @MainActor
    public func update(style: any ToastStyle, message: String, duration: Double) async {
        manager?.update(id: id, style: style, message: message, duration: duration)
    }
}

// MARK: - Model

public struct Toast: Identifiable, Sendable {
    public let id = UUID()
    public var style: any ToastStyle
    public var message: String
    public let createdAt = Date()

    // Explicit initializer for clarity and to avoid relying on the synthesized one
    public nonisolated init(style: any ToastStyle, message: String) {
        self.style = style
        self.message = message
    }

    // No builder helpers here – see Kind namespace below
}

// MARK: - Toast Builder Namespace
extension Toast {
    public enum Kind {
        public static func success(_ message: String, iconColor: Color? = nil) -> Toast {
            Toast(style: DefaultToastStyle.success(iconColor: iconColor), message: message)
        }
        public static func error(_ message: String, iconColor: Color? = nil) -> Toast {
            Toast(style: DefaultToastStyle.error(iconColor: iconColor), message: message)
        }
        public static func info(_ message: String, iconColor: Color? = nil) -> Toast {
            Toast(style: DefaultToastStyle.info(iconColor: iconColor), message: message)
        }
        public static func loading(_ message: String = "Loading…") -> Toast {
            Toast(style: LoadingToastStyle(), message: message)
        }
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
    
    // Convenience static methods on Toast itself for better ergonomics
    public static func success(_ message: String, iconColor: Color? = nil) -> Toast {
        Kind.success(message, iconColor: iconColor)
    }
    public static func error(_ message: String, iconColor: Color? = nil) -> Toast {
        Kind.error(message, iconColor: iconColor)
    }
    public static func info(_ message: String, iconColor: Color? = nil) -> Toast {
        Kind.info(message, iconColor: iconColor)
    }
    public static func loading(_ message: String = "Loading…") -> Toast {
        Kind.loading(message)
    }
    public static func custom(_ message: String,
                              iconName: String? = nil,
                              iconColor: Color? = nil,
                              backgroundColor: Color = .white) -> Toast {
        Kind.custom(message, iconName: iconName, iconColor: iconColor, backgroundColor: backgroundColor)
    }
}

// MARK: - Single Toast View

private struct ToastView: View {
    let style: any ToastStyle
    let message: String
    let configuration: ToastConfiguration
    
    // MARK: - Accessibility Helpers
    private var accessibilityDescription: String {
        var components: [String] = []
        
        // Add icon description based on style
        if let iconName = style.iconName {
            let iconDescription = iconAccessibilityDescription(for: iconName)
            components.append(iconDescription)
        } else if style is LoadingToastStyle {
            components.append("Loading")
        }
        
        // Add the message
        components.append(message)
        
        return components.joined(separator: ". ")
    }
    
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
            // For custom icons, try to derive a meaningful description
            return iconName.replacingOccurrences(of: ".", with: " ")
                          .replacingOccurrences(of: "_", with: " ")
                          .capitalized
        }
    }

    var body: some View {
        HStack {
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

// MARK: - Toast Dismiss Direction
public enum ToastDismissAxis {
    case horizontal, vertical, both, none
}

// MARK: - Generic Drag-to-Dismiss Modifier
private struct DragDismissModifier: ViewModifier {
    let configuration: ToastConfiguration

    let allowed: ToastDismissAxis
    var threshold: CGFloat { configuration.dismissTriggerDistance }
    let isStiff: Bool
    let onDismiss: () -> Void

    @Environment(\.toastManager) private var manager
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1
    @State private var timersPaused = false
    @State private var dampDuringDrag = false

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
    private func handleChanged(_ value: DragGesture.Value) {
        guard allowed != .none else { return }

        if !timersPaused && !manager.isExpanded {
            manager.pauseTimers()
            timersPaused = true
        }

        let t = value.translation

        if offset == .zero {
            dampDuringDrag = isStiff
        }

        // Y-axis damping
        var limitedY: CGFloat
        if t.height > 0 {
            // Downward drag is always damped a bit for a stiffer feel
            limitedY = min(t.height * configuration.dragDampFactor, configuration.dragMaxVerticalDamp)
        } else {
            // Upward drag: damp only when vertical dismissal is not allowed
            if manager.isExpanded || isStiff {
                limitedY = -min(abs(t.height) * configuration.dragDampFactor, configuration.dragMaxVerticalDamp)
            } else {
                limitedY = t.height
            }
        }

        // X-axis damping (for non-dismissable cases, e.g. Loading style or stiff)
        var limitedX: CGFloat
        if dampDuringDrag || isStiff {
            let damped = min(abs(t.width) * configuration.dragDampFactor, configuration.dragMaxHorizontalDamp)
            limitedX = (t.width >= 0 ? 1 : -1) * damped
        } else {
            limitedX = t.width
        }

        offset = CGSize(width: limitedX, height: limitedY)
    }

    private func handleEnded(_ value: DragGesture.Value) {
        defer {
            if timersPaused && !manager.isExpanded {
                manager.resumeTimers()
                timersPaused = false
            }
            dampDuringDrag = false
        }

        guard allowed != .none else {
            withAnimation(.spring()) {
                offset = .zero; opacity = 1
            }
            return
        }

        let dx = value.translation.width
        let dy = value.translation.height

        let canHorizontal = allowed == .horizontal || allowed == .both
        let canVertical   = allowed == .vertical   || allowed == .both

        // Determine predominant direction
        let isHorizontal = abs(dx) >= abs(dy)
        let horizontalTrigger = canHorizontal && abs(dx) > threshold && isHorizontal && !isStiff
        let verticalTrigger   = canVertical   && dy < -threshold      && !isHorizontal && !manager.isExpanded && !isStiff

        guard horizontalTrigger || verticalTrigger else {
            withAnimation(.spring()) { offset = .zero; opacity = 1 }
            return
        }

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

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            onDismiss()
        }
    }
}



// MARK: - ToastManager

/// ToastManager handles the display and lifecycle of toast notifications.
///
/// **Usage:**
/// Inject ToastManager through the environment:
/// ```swift
/// @Environment(\.toastManager) private var toastManager
///
/// // In your app setup:
/// ContentView()
///     .environment(\.toastManager, ToastManager())
///
/// // Show toasts:
/// let handle = toastManager.show(.success("Saved!"), duration: 3)
/// ```
@Observable
@MainActor
public final class ToastManager {

    public private(set) var toasts: [Toast] = []
    public var isExpanded: Bool = false

    // Configuration for toast behavior and appearance
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

    public init(configuration: ToastConfiguration = .init()) {
        self.configuration = configuration
    }

    // MARK: Public API


    /// Shows a toast with the specified duration.
    /// This is the primary public method for displaying toasts.
    /// - Parameters:
    ///   - toast: The toast to display
    ///   - duration: How long to show the toast before auto-dismissal (0 = no auto-dismiss)
    /// - Returns: A handle for controlling the toast imperatively
    @discardableResult
    public func show(_ toast: Toast, duration: Double? = nil) -> ToastHandle {
        enqueue(toast: toast, duration: duration)
        return ToastHandle(id: toast.id, manager: self)
    }

    /// Called by the host view to toggle between the collapsed Z-stack and expanded V-stack
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

    // MARK: Internals

    /// Internal method to enqueue a new toast for display with the specified duration.
    /// Use the public `show(_:duration:)` method instead.
    internal func enqueue(toast: Toast, duration: Double?) {
        let actualDuration = duration ?? configuration.defaultDuration

        withAnimation(addAnimation) {
            if toasts.count >= configuration.maxToasts, let oldest = toasts.first {
                cancelCountdown(for: oldest.id)
                toasts.removeFirst()
            }

            toasts.append(toast)

            if isExpanded {
                countdowns[toast.id] = Countdown(task: nil, expiry: nil, remaining: actualDuration)
            } else {
                scheduleCountdown(for: toast, after: actualDuration)
            }
        }
        
        // Announce new toast to VoiceOver users
        announceToastForAccessibility(toast)
    }
    
    // MARK: - Accessibility Support
    private func announceToastForAccessibility(_ toast: Toast) {
        #if os(iOS)
        guard UIAccessibility.isVoiceOverRunning else { return }

        var announcement = ""

        // Add status description based on style
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

        // Add the message
        announcement += toast.message

        UIAccessibility.post(notification: .announcement, argument: announcement)
        #endif
    }

    // Countdown scheduling & helpers
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

    private func cancelCountdown(for id: UUID) {
        countdowns[id]?.task?.cancel()
        countdowns.removeValue(forKey: id)
    }

    private func remainingTime(for id: UUID, reference now: Date = Date()) -> Double? {
        if let explicit = countdowns[id]?.remaining { return explicit }
        if let expiry = countdowns[id]?.expiry { return max(0, expiry.timeIntervalSince(now)) }
        return nil
    }

    // MARK: Timer controls (used by drag gesture)
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

    private func collapseIfNeeded() {
        if toasts.count <= 1 && isExpanded {
            isExpanded = false
            resumeTimers()
        }
    }

    // NEW: Immediate dismissal helper used by drag gesture
    @MainActor
    public func dismiss(_ toast: Toast) {
        dismiss(id: toast.id)
    }
    
    // Internal dismissal by ID (used by ToastHandle)
    @MainActor
    internal func dismiss(id: UUID) {
        cancelCountdown(for: id)
        withAnimation(removeAnimation) {
            toasts.removeAll { $0.id == id }
            collapseIfNeeded()
        }
    }

    // NEW: Update an existing toast's content and reschedule dismissal
    @MainActor
    public func updateToast(_ toast: Toast,
                            style: any ToastStyle,
                            message: String,
                            duration: Double) {
        update(id: toast.id, style: style, message: message, duration: duration)
    }
    
    // Internal update by ID (used by ToastHandle)
    @MainActor
    internal func update(id: UUID, style: any ToastStyle, message: String, duration: Double) {
        guard let index = toasts.firstIndex(where: { $0.id == id }) else { return }

        // Cancel any outstanding countdown for this toast
        cancelCountdown(for: id)

        withAnimation(addAnimation) {
            toasts[index].style = style
            toasts[index].message = message
        }

        if !isExpanded {
            scheduleCountdown(for: toasts[index], after: duration)
        } else {
            countdowns[id] = Countdown(task: nil, expiry: nil, remaining: duration)
        }
        
        // Announce the updated toast to VoiceOver users
        announceToastForAccessibility(toasts[index])
    }
}

// MARK: - Environment Key Infrastructure

/// Environment key for injecting ToastManager instances into the SwiftUI environment.
/// This replaces the singleton pattern with proper dependency injection.
@MainActor
public struct ToastManagerKey: @preconcurrency EnvironmentKey {
    public static let defaultValue = ToastManager()
}

public extension EnvironmentValues {
    /// Access the current ToastManager from the environment.
    ///
    /// Usage:
    /// ```swift
    /// @Environment(\.toastManager) private var toastManager
    /// ```
    var toastManager: ToastManager {
        get { self[ToastManagerKey.self] }
        set { self[ToastManagerKey.self] = newValue }
    }
}

public extension View {
    /// Injects a custom ToastManager into the environment for this view and its descendants.
    ///
    /// Usage:
    /// ```swift
    /// ContentView()
    ///     .toastManager(myCustomToastManager)
    /// ```
    ///
    /// - Parameter manager: The ToastManager instance to inject
    /// - Returns: A view with the ToastManager injected into its environment
    func toastManager(_ manager: ToastManager) -> some View {
        environment(\.toastManager, manager)
    }
    
    /// Adds a toast host overlay to this view, following SwiftUI patterns like `.alert()` and `.sheet()`.
    ///
    /// Usage:
    /// ```swift
    /// ContentView()
    ///     .environment(\.toastManager, myManager)
    ///     .toasts()
    /// ```
    ///
    /// - Returns: A view with the ToastHost overlaid at the top
    func toasts() -> some View {
        overlay(alignment: .top) {
            ToastHost()
        }
    }
}

// MARK: - Loading Task Helper
extension ToastManager {
    /// Shows a toast that begins in a loading state and automatically updates when the async operation completes.
    ///
    /// **Usage:**
    /// ```swift
    /// @Environment(\.toastManager) private var toastManager
    /// let task = ToastManager.showLoadingTask(
    ///     manager: toastManager,
    ///     operation: { await someAsyncWork() },
    ///     success: { "Success: \($0)" },
    ///     failure: { "Error: \($0.localizedDescription)" }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - manager: The ToastManager to use for displaying toasts.
    ///   - loadingMessage: Message to show while the task is in flight.
    ///   - operation: The async operation to perform.
    ///   - success: Builds the success message using the operation's return value.
    ///   - failure: Builds the error message using the thrown `Error`.
    ///   - successDuration: Duration for the success toast.
    ///   - failureDuration: Duration for the failure toast.
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
        let toastManager = manager
        let loadingToast = Toast.loading(loadingMessage)
        
        // Present loading toast immediately and get handle
        let handle = toastManager.show(loadingToast, duration: 0) // 0 => no auto-dismiss

        // Perform the operation and update UI when done
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

// MARK: - ToastHost


public struct ToastHost: View {
    @Environment(\.toastManager) private var manager
    @Namespace private var toastNamespace

    public init() {}

    private var spacing: CGFloat { manager.configuration.toastSpacing }
    private var addAnimation: Animation {
        Animation.timingCurve(0.25, 0.2, 0.25, 1, duration: manager.configuration.animationDuration)
    }

    // MARK: Layout Helpers
    private func layoutInfo(for index: Int, total: Int, isExpanded: Bool) -> (z: Double, offset: CGSize, scale: CGFloat, opacity: Double) {
        // When expanded, lay toasts out vertically using a fixed row height (similar to the Preview demo). When
        // collapsed, use a card-stack style by offsetting and scaling items based on depth.
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

    private var toastList: some View {
        let toastsToShow = manager.isExpanded ? Array(manager.toasts.suffix(manager.configuration.maxToasts)) : manager.toasts
        
        return ForEach(Array(toastsToShow.enumerated()), id: \.element.id) { index, toast in
            let layout = layoutInfo(for: index, total: toastsToShow.count, isExpanded: manager.isExpanded)

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

