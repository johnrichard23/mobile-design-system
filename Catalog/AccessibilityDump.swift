//
//  AccessibilityDump.swift
//
//  Test aid: the simulator can't run VoiceOver, so with `-dump-a11y` the
//  catalog writes what VoiceOver would read (each element's label, value,
//  hint, traits and frame, in reading order) to Documents/a11y.txt once a
//  second. Also records the Reduce Motion and Bold Text settings it sees.
//

import SwiftUI
import UIKit

@MainActor
enum AccessibilityDump {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-dump-a11y")
    }

    static func start() {
        guard isEnabled else { return }
        enableAutomation()
        Task { @MainActor in
            while true {
                try? await Task.sleep(for: .seconds(1))
                write()
            }
        }
    }

    /// SwiftUI builds its accessibility tree only for an accessibility client.
    /// Turn on the same automation switch UI-testing tools use, so the tree
    /// exists without VoiceOver. Test builds only.
    private static func enableAutomation() {
        guard let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let symbol = dlsym(library, "_AXSSetAutomationEnabled")
        else { return }
        typealias SetEnabled = @convention(c) (Int32) -> Void
        unsafeBitCast(symbol, to: SetEnabled.self)(1)
    }

    private static func write() {
        var lines = [
            "reduceMotion=\(UIAccessibility.isReduceMotionEnabled)"
                + " boldText=\(UIAccessibility.isBoldTextEnabled)"
                + " darkerColors=\(UIAccessibility.isDarkerSystemColorsEnabled)",
        ]
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { !$0.isHidden }
            .sorted { $0.windowLevel.rawValue > $1.windowLevel.rawValue }
        for window in windows {
            lines.append("-- window level \(Int(window.windowLevel.rawValue))")
            walk(window, into: &lines)
        }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("a11y.txt")
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private static func walk(_ element: NSObject, into lines: inout [String]) {
        if element.accessibilityElementsHidden { return }
        if element.isAccessibilityElement {
            lines.append(describe(element))
            return
        }
        if let children = element.accessibilityElements as? [NSObject], !children.isEmpty {
            children.forEach { walk($0, into: &lines) }
            return
        }
        let count = element.accessibilityElementCount()
        if count != NSNotFound, count > 0 {
            for index in 0..<count {
                if let child = element.accessibilityElement(at: index) as? NSObject {
                    walk(child, into: &lines)
                }
            }
            return
        }
        if let view = element as? UIView {
            view.subviews.filter { !$0.isHidden }.forEach { walk($0, into: &lines) }
        }
    }

    private static func describe(_ element: NSObject) -> String {
        let traits = element.accessibilityTraits
        let names: [(UIAccessibilityTraits, String)] = [
            (.button, "button"), (.header, "header"), (.selected, "selected"),
            (.notEnabled, "dimmed"), (.staticText, "text"), (.image, "image"),
            (.adjustable, "adjustable"), (.link, "link"), (.searchField, "search"),
            (.toggleButton, "switch"),
        ]
        let traitList = names.filter { traits.contains($0.0) }.map(\.1).joined(separator: ",")
        let frame = element.accessibilityFrame.integral
        var parts = ["\"\(element.accessibilityLabel ?? "")\""]
        if let value = element.accessibilityValue, !value.isEmpty { parts.append("value=\"\(value)\"") }
        if let hint = element.accessibilityHint, !hint.isEmpty { parts.append("hint=\"\(hint)\"") }
        if !traitList.isEmpty { parts.append("[\(traitList)]") }
        parts.append("@\(Int(frame.minX)),\(Int(frame.minY)) \(Int(frame.width))x\(Int(frame.height))")
        return parts.joined(separator: " ")
    }
}
