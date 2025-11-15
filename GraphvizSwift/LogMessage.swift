//
//  LogMessage.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 9/1/25.
//

import os
import SwiftUI

/// LogMessage holds the log message from graphviz log. This type is a member of an instance of observable class Graph so that the post of the message is detected by a Text view.
@Observable nonisolated final class LogMessage: @unchecked Sendable {
    var message: String = ""
}

/// GraphvizLogHandler receives log messages from graphviz render operations. Its static capture function provides a wrapper for capturing log messages from graphviz API calls to display in the UI. All of its instance methods are private.
@Observable final class GraphvizLogHandler: Sendable {
    static let captureLock = OSAllocatedUnfairLock()
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
}
