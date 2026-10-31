//
//  DSSheetToolbar.swift
//
//  Standard chrome for a sheet, using the system toolbar instead of a custom
//  header. A sheet's root view sits in its own NavigationStack and gets an
//  inline title, Cancel on the leading side and the confirm action on the
//  trailing side, where iOS users expect them.
//
//  If the sheet holds unsaved changes, also block swipe-to-dismiss with
//  `.interactiveDismissDisabled(hasChanges)` and confirm on Cancel.
//

import SwiftUI

public extension View {
    /// Title, Cancel and confirm button for a sheet's root view.
    ///
    /// ```
    /// NavigationStack {
    ///     AddExpenseForm()
    ///         .dsSheetToolbar("Add expense", cancel: { dismiss() }, confirmTitle: "Save",
    ///                         isConfirmEnabled: form.isValid, confirm: save)
    /// }
    /// ```
    func dsSheetToolbar(
        _ title: String,
        cancel: (() -> Void)? = nil,
        confirmTitle: String = "Done",
        isConfirmEnabled: Bool = true,
        confirm: (() -> Void)? = nil
    ) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let cancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: cancel)
                    }
                }
                if let confirm {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(confirmTitle, action: confirm)
                            .disabled(!isConfirmEnabled)
                    }
                }
            }
    }
}

private struct DSSheetToolbarPreview: View {
    @State private var isPresented = true

    var body: some View {
        Button("Add expense") { isPresented = true }
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    Text("Form goes here")
                        .dsSheetToolbar("Add expense", cancel: { isPresented = false }, confirmTitle: "Save") {
                            isPresented = false
                        }
                }
            }
    }
}

#Preview {
    DSSheetToolbarPreview()
}
