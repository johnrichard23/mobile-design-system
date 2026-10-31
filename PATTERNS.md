# UX patterns

How screens behave, for any app built on this design system. Components
decide how things look; these patterns decide how they work together. Each
pattern names the components it uses and, where there is one, the catalog page
that shows it working (`Catalog/run.sh <page>`).

## 1. Navigation

| The user is… | Use | Back / close |
|---|---|---|
| Going deeper into the same task (list → detail) | Push onto the `NavigationStack` | Back button and edge swipe |
| Starting a separate, self-contained task (add, edit, compose) | `.sheet` with its own `NavigationStack` and `.dsSheetToolbar` | Cancel / confirm; swipe down |
| Making a quick choice (filters, options) | `.sheet` with `.presentationDetents([.medium, .large])` | Swipe down |
| Viewing something immersive (photo, map, player) | `.fullScreenCover` with a `DSCloseButton` | Close button |
| Passing a one-way door (sign-in, onboarding done, purchase) | Swap the root view on app state | None: there is nothing to go back to |

- Back is never blocked, except while a save is in flight or a sheet holds
  unsaved changes (`.interactiveDismissDisabled(hasChanges)` plus a
  confirmation on Cancel).
- A sheet that needs a second step was a navigation flow; give it a
  `NavigationStack` and push.
- Tabs are peers. Each tab keeps its own stack; tapping the active tab
  returns to its root.
- Deep links build the whole stack (list, then detail), not just the last
  screen.

## 2. Forms — catalog: `pattern-form`

- One column, labels above fields (`DSTextField`), in the order people think
  of the information.
- Set the keyboard and AutoFill for every field (`keyboardType`,
  `textContentType`). The return key moves to the next field
  (`.submitLabel(.next)` + `.onSubmit`); the last field's is `.done`.
- Validate a field when the user leaves it, and everything on submit. Never
  while they are still typing.
- Errors sit under the field, say what to do ("Enter all 10 digits"), and
  carry an icon. On a failed submit, move focus to the first field with an
  error and play the error haptic.
- The primary action stays enabled and explains what's missing, rather than
  being greyed out with no reason. (A sheet's toolbar Save may be disabled
  while the form is empty; that is the system convention.)
- The primary action sits in `.dsBottomBar`, above the keyboard; drag down
  dismisses the keyboard (`.scrollDismissesKeyboard(.interactively)`).

## 3. Destructive actions — catalog: `pattern-delete`

Confirm **or** undo, never both.

- **Undo** when the action is easy to reverse and frequent (delete one item,
  archive, remove from list): do it at once and show a toast with Undo
  (`DSToast(…, action: .init("Undo") { … })`).
- **Confirm** when it can't be undone or affects a lot (delete all, leave a
  group, delete an account): `.confirmationDialog` with a destructive button
  that names the action ("Delete 4 expenses"), and Cancel.
- Destructive buttons use `.ds(.destructive)` or the system destructive role,
  never the accent. The theme tints the whole app with its accent, and that
  tint also overrides the red of a destructive swipe action, so add
  `.tint(theme.destructive)` to it:
  `Button("Delete", role: .destructive) { … }.tint(theme.destructive)`.

## 4. Loading, empty, error, offline

Every screen designs all four before it ships.

- **Loading:** render the real layout with sample data under
  `.dsLoading(true)`; never a spinner over a blank screen. On refresh, keep
  showing what's cached.
- **Empty:** `DSStateView` explains what goes here and offers the action
  that fills it.
- **Error:** say what happened and what to do, with Try again; never an
  error code. Inline errors use `DSBanner(kind: .error)`.
- **Offline:** if there's cached content, show it with a warning banner; if
  not, `DSStateView.offline`.

## 5. Feedback

- Taps change the screen at once (optimistic update); the network catches up
  in the background. If it fails, roll back visibly and say so in a toast.
- Toasts confirm things that happened out of view or after a delay. Don't
  toast what the screen already shows.
- Haptics: selection when a value steps, success/error for outcomes, one per
  action, always with a visual change (`.dsHaptic`).

## 6. Permissions — catalog: `pattern-permission`

- Ask at the moment the feature needs it, never at launch.
- First show your own screen: what you'll use it for, in one sentence, with
  Continue and Not now. Only Continue triggers the system prompt, so the one
  system prompt isn't wasted.
- If denied, the feature still works where it can, and a banner explains how
  to turn it on, with Open Settings.

## 7. Keyboard

- The focused field is always visible; content scrolls above the keyboard.
- Bottom actions rise with the keyboard (`.dsBottomBar` does this).
- Drag down or tap outside a field to dismiss; no "Done" toolbar unless the
  keyboard has no return key (number pads).

## 8. Writing

- Sentence case everywhere: "Add expense", not "Add Expense".
- One label per intent across the app: pick "Continue" or "Next", not both.
- Buttons say what happens ("Save expense", "Delete 4 expenses"), not "OK"
  or "Yes".
- Errors say what happened and what to do next, in plain words, without
  blaming the user and without codes.
- Keep it short: one sentence of explanation is usually enough.
