//
//  DSSecureField.swift
//
//  Password field: the same layout as DSTextField, with a show/hide toggle
//  and helper text for password rules.
//

import SwiftUI
import UIKit

/// A password field with a show/hide toggle.
public struct DSSecureField: View {
    private let label: String
    private let placeholder: String
    @Binding private var text: String
    private let isFocused: FocusState<Bool>.Binding
    private let helperMessage: String?
    private let errorMessage: String?
    private let textContentType: UITextContentType

    @State private var isVisible = false
    @Environment(\.theme) private var theme

    /// Use `.newPassword` for sign-up and change-password, so iOS offers a
    /// strong password.
    public init(
        _ label: String,
        placeholder: String = "",
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        helperMessage: String? = nil,
        errorMessage: String? = nil,
        textContentType: UITextContentType = .password
    ) {
        self.label = label
        self.placeholder = placeholder
        _text = text
        self.isFocused = isFocused
        self.helperMessage = helperMessage
        self.errorMessage = errorMessage
        self.textContentType = textContentType
    }

    public var body: some View {
        DSFieldLayout(
            label: label,
            helperMessage: helperMessage,
            errorMessage: errorMessage,
            isFocused: isFocused.wrappedValue,
            isReadOnly: false
        ) {
            Group {
                if isVisible {
                    TextField(text: $text, prompt: prompt) { Text(label) }
                } else {
                    SecureField(text: $text, prompt: prompt) { Text(label) }
                }
            }
            .textContentType(textContentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused(isFocused)
            .accessibilityLabel(Text(label))
        } trailing: {
            if !text.isEmpty {
                Button(
                    isVisible ? "Hide password" : "Show password",
                    systemImage: isVisible ? "eye.slash" : "eye"
                ) {
                    isVisible.toggle()
                }
                .buttonStyle(DSFieldAccessoryStyle())
            }
        }
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(theme.labelTertiary)
    }
}

private struct DSSecureFieldPreview: View {
    @State private var password = "hunter22"
    @FocusState private var isFocused: Bool

    var body: some View {
        DSSecureField(
            "Password",
            text: $password,
            isFocused: $isFocused,
            helperMessage: "At least 8 characters.",
            textContentType: .newPassword
        )
        .screenMargins()
        .frame(maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    DSSecureFieldPreview()
}
