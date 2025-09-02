//
//  LogMessage.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 9/1/25.
//

import os
import SwiftUI

/// LogMessage holds the log message from graphviz log. This type is a member of an instance of observable class Graph so that the post of the message is detected by a Text view.
final class LogMessage: @unchecked Sendable {
    var message: String = ""
}

/// GraphvizLogHandler receives log messages from graphviz render operations. Its static capture function provides a wrapper for capturing log messages from graphviz API calls to display in the UI. All of its instance methods are private.
final class GraphvizLogHandler: @unchecked Sendable {
    static let captureLock = OSAllocatedUnfairLock()
    private let logMessage: LogMessage
    private var observer: Any?
    
    // FYI: agseterrf type is @convention(c) (_ cChar: UnsafeMutablePointer<CChar>?) -> Int32
    private init(logMessage: LogMessage) {
        self.logMessage = logMessage
    }

    static func capture(logMessage: LogMessage, block: () -> Any ) -> Any {
        captureLock.lock()
        defer { captureLock.unlock() }
        logMessage.message = ""
        let handler = GraphvizLogHandler(logMessage: logMessage)
        defer {
            if logMessage.message.count > 0 {
                logMessage.message = String(logMessage.message.dropLast()) // drop final newline
            }
            handler.close()
        }
        
        return handler.observe { block() }
    }
    
    deinit {
        close()
    }

    private func close() {
        print("close LogMessageObserver for \(observer, default: "nil")")
        if let observer {
            NotificationCenter.default.removeObserver(
                observer,
                name: Notification.Name("GraphvizSwift.LogPipe"),
                object: nil)
        }
        observer = nil
    }

    private func observe(_ block: () -> Any ) -> Any {
        observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("GraphvizSwift.LogPipe"),
            object: nil,
            queue: nil // .main?
        ) { @Sendable notification in
            let logMessage = self.logMessage
            if let fragment = notification.userInfo?["fragment"] as? String {
                logMessage.message += fragment
            }
        }

        let errf = agseterrf { fragment in
            if let fragment {
                let fragment = String(cString: fragment)
                if !fragment.isEmpty {
                    NotificationCenter.default.post(
                        name: Notification.Name("GraphvizSwift.LogPipe"),
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
