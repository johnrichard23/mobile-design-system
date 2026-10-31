//
//  DSTextField.swift
//
//  Text field: a label above the field that stays visible, a real
//  placeholder, keyboard and AutoFill settings, an error message with an icon
//  (announced to VoiceOver), a read-only state, and a height that grows with
//  Dynamic Type. `DSFieldLayout` is public for building other kinds of field.
//
//  Set the return key from outside with `.submitLabel(.next)` and move focus
//  in `.onSubmit`.
//

import SwiftUI
import UIKit

/// A single-line text field with a label, helper text and an error.
public struct DSTextField: View {
    private let label: String
    private let placeholder: String
    @Binding private var text: String
    private let isFocused: FocusState<Bool>.Binding
    private let helperMessage: String?
    private let errorMessage: String?
    private let keyboardType: UIKeyboardType
    private let textContentType: UITextContentType?
    private let autocapitalization: TextInputAutocapitalization
    private let autocorrectionDisabled: Bool
    private let isReadOnly: Bool

    @Environment(\.theme) private var theme

    public init(
        _ label: String,
        placeholder: String = "",
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        helperMessage: String? = nil,
        errorMessage: String? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        autocorrectionDisabled: Bool = false,
        isReadOnly: Bool = false
    ) {
        self.label = label
        self.placeholder = placeholder
        _text = text
        self.isFocused = isFocused
        self.helperMessage = helperMessage
        self.errorMessage = errorMessage
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.isReadOnly = isReadOnly
    }

    public var body: some View {
        DSFieldLayout(
            label: label,
            helperMessage: helperMessage,
            errorMessage: errorMessage,
            isFocused: isFocused.wrappedValue,
            isReadOnly: isReadOnly
        ) {
            TextField(text: $text, prompt: Text(placeholder).foregroundStyle(theme.labelTertiary)) {
                Text(label)
            }
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(autocorrectionDisabled)
            .focused(isFocused)
            .disabled(isReadOnly)
            .accessibilityLabel(Text(label))
        } trailing: {
            if isFocused.wrappedValue, !text.isEmpty, !isReadOnly {
                Button("Clear text", systemImage: "xmark.circle.fill") { text = "" }
                    .buttonStyle(DSFieldAccessoryStyle())
            }
        }
    }
}

/// Label, field box, and helper or error text: the frame every field uses.
/// Build a project-specific field (phone number, dropdown, amount) by putting
/// its control in `field` and any icon button in `trailing`, so it matches the
/// other fields in focus, error, read-only and Dynamic Type behaviour.
///
/// The visible label is hidden from VoiceOver, so give each control inside
/// `field` its own `.accessibilityLabel` (usually the field's label). The
/// helper or error message is added to them as a hint.
public struct DSFieldLayout<Field: View, Trailing: View>: View {
    let label: String
    let helperMessage: String?
    let errorMessage: String?
    let isFocused: Bool
    let isReadOnly: Bool
    let field: Field
    let trailing: Trailing

    @Environment(\.theme) private var theme

    public init(
        label: String,
        helperMessage: String? = nil,
        errorMessage: String? = nil,
        isFocused: Bool,
        isReadOnly: Bool = false,
        @ViewBuilder field: () -> Field,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.label = label
        self.helperMessage = helperMessage
        self.errorMessage = errorMessage
        self.isFocused = isFocused
        self.isReadOnly = isReadOnly
        self.field = field()
        self.trailing = trailing()
    }

    public var body: some View {
        let shape = DesignSystem.Radius.shape(theme.radius.field)
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if !label.isEmpty {
                Text(label)
                    .textRole(theme.components.field.label)
                    .foregroundStyle(isReadOnly ? theme.labelSecondary : theme.labelPrimary)
                    .accessibilityHidden(true)
            }

            HStack(spacing: theme.spacing.xxs) {
                field
                    .textRole(theme.components.field.text)
                    .foregroundStyle(isReadOnly ? theme.labelSecondary : theme.labelPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHint(errorMessage ?? helperMessage ?? "")
                trailing
            }
            .padding(.leading, theme.spacing.md)
            .padding(.trailing, theme.spacing.xxs)
            .frame(minHeight: max(theme.size.fieldHeight, DesignSystem.minTapTarget))
            .background(isReadOnly ? theme.surfacePressed : theme.surface, in: shape)
            .overlay {
                shape.strokeBorder(borderColor, lineWidth: theme.size.borderWidth)
            }
            .animation(DesignSystem.Motion.press, value: isFocused)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .textRole(theme.components.field.message)
                    .foregroundStyle(theme.destructive)
                    .accessibilityHidden(true)
            } else if let helperMessage {
                Text(helperMessage)
                    .textRole(theme.components.field.message)
                    .foregroundStyle(theme.labelSecondary)
                    .accessibilityHidden(true)
            }
        }
        .onChange(of: errorMessage) { _, newValue in
            if let newValue {
                AccessibilityNotification.Announcement(newValue).post()
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return theme.destructive }
        if isFocused, !isReadOnly { return theme.accent }
        return theme.border
    }
}

/// Small icon button inside a field (clear, show password, open a picker).
public struct DSFieldAccessoryStyle: ButtonStyle {
    @Environment(\.theme) private var theme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .textRole(theme.components.field.text)
            .foregroundStyle(theme.labelTertiary)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .minTapTarget()
    }
}

private struct DSTextFieldPreview: View {
    @State private var name = ""
    @State private var email = "dana@"
    @FocusState private var nameFocused: Bool
    @FocusState private var emailFocused: Bool

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.standard.groupGap) {
            DSTextField(
                "Trip name",
                placeholder: "e.g. Siargao with the barkada",
                text: $name,
                isFocused: $nameFocused,
                helperMessage: "Everyone in the trip sees this."
            )
            DSTextField(
                "Email",
                text: $email,
                isFocused: $emailFocused,
                errorMessage: "Enter a full email address, like name@example.com.",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never,
                autocorrectionDisabled: true
            )
        }
        .screenMargins()
        .frame(maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    DSTextFieldPreview()
}
