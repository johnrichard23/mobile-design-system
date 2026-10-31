//
//  DSToast.swift
//
//  Toast: one at a time, auto-dismisses, swipes up to dismiss, and lives in
//  its own window so it shows above sheets. An icon per kind (never colour
//  alone), a close button with a VoiceOver label, the message is announced,
//  it stays longer while VoiceOver runs, it fades instead of sliding under
//  Reduce Motion, and success and error play a haptic.
//
//  ```swift
//  SomeScreen()
//      .dsToast($toast)
//  // later
//  toast = .success("Saved")
//  ```
//
//  Kinds are open: `extension DSToast.Kind { static let synced = Self(systemImage:
//  "arrow.triangle.2.circlepath", haptic: nil) { $0.info } }`.
//

import SwiftUI
import UIKit

/// A short message about something that just happened.
public struct DSToast: Equatable, Sendable {
    /// Toast meaning: its icon, colour and haptic. Give each kind a distinct
    /// icon shape.
    public struct Kind: Sendable {
        public let systemImage: String
        public let haptic: UINotificationFeedbackGenerator.FeedbackType?
        let color: @Sendable (DesignSystem.Theme) -> Color

        public init(
            systemImage: String,
            haptic: UINotificationFeedbackGenerator.FeedbackType?,
            color: @escaping @Sendable (DesignSystem.Theme) -> Color
        ) {
            self.systemImage = systemImage
            self.haptic = haptic
            self.color = color
        }

        public static let success = Kind(systemImage: "checkmark.circle.fill", haptic: .success) { $0.success }
        public static let error = Kind(systemImage: "exclamationmark.circle.fill", haptic: .error) {
            $0.destructive
        }
        public static let info = Kind(systemImage: "info.circle.fill", haptic: nil) { $0.info }
    }

    public static func == (lhs: DSToast, rhs: DSToast) -> Bool {
        lhs.id == rhs.id
    }

    /// One short action, typically "Undo". Running it also closes the toast.
    public struct Action: Sendable {
        public let title: String
        let handler: @MainActor @Sendable () -> Void

        public init(_ title: String, handler: @escaping @MainActor @Sendable () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    public let id = UUID()
    public var message: String
    public var kind: Kind
    public var duration: TimeInterval
    public var action: Action?

    /// A toast with an action stays at least 6 seconds, so it can be reached.
    public init(_ message: String, kind: Kind = .info, duration: TimeInterval = 3, action: Action? = nil) {
        self.message = message
        self.kind = kind
        self.duration = action == nil ? duration : max(duration, 6)
        self.action = action
    }

    /// Something worked.
    public static func success(_ message: String) -> DSToast {
        DSToast(message, kind: .success)
    }

    /// Something failed. Say what to do next.
    public static func error(_ message: String) -> DSToast {
        DSToast(message, kind: .error, duration: 5)
    }

    /// Neutral information.
    public static func info(_ message: String) -> DSToast {
        DSToast(message, kind: .info)
    }
}

public extension View {
    /// Shows a toast when `toast` is set, and sets it back to `nil` when the
    /// toast goes. A new toast replaces the current one.
    func dsToast(_ toast: Binding<DSToast?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var toast: DSToast?
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .onChange(of: toast) { _, newValue in
                if let newValue {
                    DSToastPresenter.shared.show(newValue, theme: theme) {
                        toast = nil
                    }
                } else {
                    DSToastPresenter.shared.dismiss()
                }
            }
            .onDisappear {
                // The owning screen left, so its toast goes with it.
                if toast != nil {
                    toast = nil
                    DSToastPresenter.shared.dismiss()
                }
            }
    }
}

/// One toast for the whole app, in a window above the app's own.
@MainActor
final class DSToastPresenter {
    static let shared = DSToastPresenter()

    private var window: UIWindow?
    private var dismissTask: Task<Void, Never>?
    private var onDismiss: (@MainActor () -> Void)?

    func show(
        _ toast: DSToast,
        theme: DesignSystem.Theme,
        onDismiss: @escaping @MainActor () -> Void
    ) {
        // Detach the old binding before replacing the toast, so clearing it
        // can't take down the toast being shown now.
        self.onDismiss = nil
        dismiss(animated: false)
        self.onDismiss = onDismiss

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        let topInset = scene.keyWindow?.safeAreaInsets.top ?? 0
        let windowWidth = scene.keyWindow?.bounds.width ?? scene.screen.bounds.width
        let width = min(
            windowWidth - 2 * theme.spacing.screenMarginCompact,
            theme.size.readableWidth
        )

        let host = UIHostingController(
            rootView: ToastPill(toast: toast, topInset: topInset, width: width) { [weak self] in
                self?.dismiss()
            }
            .theme(theme)
        )
        host.view.backgroundColor = .clear
        host.sizingOptions = [.intrinsicContentSize]
        // The pill clears the status bar itself with `topInset`.
        host.safeAreaRegions = []

        // The pill is a child pinned to the top centre, not the root view:
        // the window lets a touch through only when it lands on the root.
        let root = UIViewController()
        root.view.backgroundColor = .clear
        root.addChild(host)
        root.view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: root.view.topAnchor),
            host.view.centerXAnchor.constraint(equalTo: root.view.centerXAnchor),
        ])
        host.didMove(toParent: root)

        let window = ToastWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = root
        window.isHidden = false
        self.window = window

        let slides = !UIAccessibility.isReduceMotionEnabled
        host.view.transform = slides ? CGAffineTransform(translationX: 0, y: -120) : .identity
        host.view.alpha = 0
        UIView.animate(withDuration: 0.25) {
            host.view.transform = .identity
            host.view.alpha = 1
        }

        if theme.hapticsEnabled, let haptic = toast.kind.haptic {
            UINotificationFeedbackGenerator().notificationOccurred(haptic)
        }
        AccessibilityNotification.Announcement(toast.message).post()

        let duration = UIAccessibility.isVoiceOverRunning ? max(toast.duration, 8) : toast.duration
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    func dismiss(animated: Bool = true) {
        dismissTask?.cancel()
        dismissTask = nil
        let finished = onDismiss
        onDismiss = nil
        guard let window else {
            finished?()
            return
        }
        self.window = nil
        guard animated, let view = window.rootViewController?.view else {
            window.isHidden = true
            finished?()
            return
        }
        let slides = !UIAccessibility.isReduceMotionEnabled
        UIView.animate(withDuration: 0.18) {
            if slides { view.transform = CGAffineTransform(translationX: 0, y: -120) }
            view.alpha = 0
        } completion: { _ in
            window.isHidden = true
            finished?()
        }
    }

    /// Claims touches on the toast only; everything else reaches the app.
    private final class ToastWindow: UIWindow {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let view = super.hitTest(point, with: event)
            return view === rootViewController?.view ? nil : view
        }
    }
}

private struct ToastPill: View {
    let toast: DSToast
    /// Status-bar height, which the pill sits below.
    let topInset: CGFloat
    let width: CGFloat
    let onClose: () -> Void

    @Environment(\.theme) private var theme
    @State private var dragOffset: CGFloat = 0
    private let dismissThreshold: CGFloat = 20

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: iconName)
                .textRole(.body)
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)
            Text(toast.message)
                .textRole(theme.components.feedback.toast)
                .foregroundStyle(theme.background)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let action = toast.action {
                Button(action.title) {
                    action.handler()
                    onClose()
                }
                .textRole(theme.components.button.label)
                .foregroundStyle(theme.background)
                .minTapTarget()
            }
            Button("Dismiss", systemImage: "xmark", action: onClose)
                .labelStyle(.iconOnly)
                .textRole(.footnote, emphasized: true)
                .foregroundStyle(theme.background)
                .minTapTarget()
        }
        .padding(.leading, theme.spacing.md)
        .padding(.trailing, theme.spacing.xxs)
        .padding(.vertical, theme.spacing.xxs)
        .frame(width: width)
        .background(theme.labelPrimary, in: DesignSystem.Radius.shape(theme.radius.card))
        .shadow(
            color: theme.elevation.color,
            radius: theme.elevation.radius,
            y: theme.elevation.offsetY
        )
        .padding(.top, topInset + theme.spacing.xs)
        .offset(y: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { dragOffset = min(0, $0.translation.height) }
                .onEnded { value in
                    if value.translation.height < -dismissThreshold {
                        onClose()
                    } else {
                        withAnimation(DesignSystem.Motion.settle) { dragOffset = 0 }
                    }
                }
        )
    }

    private var iconName: String { toast.kind.systemImage }
    private var iconColor: Color { toast.kind.color(theme) }
}

private struct DSToastPreview: View {
    @State private var toast: DSToast?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.standard.sm) {
            Button("Success") { toast = .success("Expense added. Everyone's share is updated.") }
            Button("Error") { toast = .error("Couldn't save. Check your connection and try again.") }
            Button("Info") { toast = .info("Dana joined the trip") }
        }
        .buttonStyle(.ds(.secondary))
        .screenMargins()
        .dsToast($toast)
    }
}

#Preview {
    DSToastPreview()
}
