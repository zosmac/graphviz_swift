//
//  LogMessage.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 9/1/25.
//

import os
import SwiftUI

// GraphvizLogView reports messages from graphviz API operations.
struct GraphvizLogView: View {
    @Environment(LogMessage.self) var logMessage: LogMessage

    var body: some View {
        ScrollView {
            // logMessage must be an observable class type
            Text(logMessage.message)
                .foregroundStyle(.red)
        }
        .defaultScrollAnchor(.bottomLeading)
    }
}

/// LogMessage holds the log message from graphviz log. This type is a member of an instance of observable class Graph so that the post of the message is detected by a Text view.
@Observable final class LogMessage: @unchecked Sendable {
    var message: String = ""
}

/// GraphvizLogHandler receives log messages from graphviz render operations. Its static capture function provides a wrapper for capturing log messages from graphviz API calls to display in the UI. All of its instance methods are private.
@Observable final class GraphvizLogHandler: @unchecked Sendable {
    static let captureLock = OSAllocatedUnfairLock()
    private var observer: Any?
    private var errf: agusererrf? // type is @convention(c) (_ : UnsafeMutablePointer<CChar>?) -> Int32
    let logMessage: LogMessage

    init(logMessage: LogMessage) {
        self.logMessage = logMessage
    }

    func capture(block: () -> Any ) -> Any {
        Self.captureLock.lock()
        defer { Self.captureLock.unlock() }
        self.logMessage.message = ""

        let observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("GraphvizSwift.LogMessage"),
            object: nil,
            queue: nil // .main?
        ) { @Sendable notification in
            if let fragment = notification.userInfo?["fragment"] as? String {
                self.logMessage.message += fragment
            }
        }
        defer {
            NotificationCenter.default.removeObserver(
                observer,
                name: Notification.Name("GraphvizSwift.LogMessage"),
                object: nil)
        }

        let errf = agseterrf { fragment in
            // A closure for a C function cannot capture variables from its enclosing
            // context, and therefore cannot simply append fragment to message. Use a
            // notification to post the fragment to an observer.
            if let fragment {
                let fragment = String(cString: fragment)
                if !fragment.isEmpty {
                    NotificationCenter.default.post(
                        name: Notification.Name("GraphvizSwift.LogMessage"),
                        object: nil,
                        userInfo: ["fragment": fragment]
                    )
                }
            }
            return 0
        }
        defer { agseterrf(errf) }

        return block()
    }

    // The following is for a global message handler that displays all
    // graphviz messages in a single LogView window.
    static let logHandler = GraphvizLogHandler()
    private init() {
        let logMessage = LogMessage()
        self.observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("GraphvizSwift.LogHandler"),
            object: nil,
            queue: nil // .main?
        ) { @Sendable notification in
            if let fragment = notification.userInfo?["fragment"] as? String {
                logMessage.message += fragment
            }
        }
        self.logMessage = logMessage

        self.errf = agseterrf { fragment in
            if let fragment {
                let fragment = String(cString: fragment)
                if !fragment.isEmpty {
                    NotificationCenter.default.post(
                        name: Notification.Name("GraphvizSwift.LogHandler"),
                        object: nil,
                        userInfo: ["fragment": fragment]
                    )
                }
            }
            return 0
        }
    }

    deinit {
        agseterrf(errf)
        if let observer {
            NotificationCenter.default.removeObserver(
                observer,
                name: Notification.Name("GraphvizSwift.LogHandler"),
                object: nil)
        }
    }

    static func capture(block: () -> Any ) -> Any {
        captureLock.lock()
        defer { captureLock.unlock() }
        return block()
    }
}
