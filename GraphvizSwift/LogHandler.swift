//
//  LogHandler.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 9/1/25.
//

import os
import Foundation

/// LogMessage contains a single error line captured during graph render and sent as a notification.
struct LogMessage: NotificationCenter.MainActorMessage {
    typealias Subject = LogHandler
    let line: String
}

/// LogMessages holds the block of log messages captured during graph.render. This type is a member of an instance of observable class Graph so that the post of the messages can be detected by the Text view of the Messages button.
@Observable final class LogMessages: Sendable {
    var block: String = ""
}

/// LogHandler receives log messages during graph render. Its capture method provides a wrapper for capturing log messages from graphviz API calls to display in the UI.
@Observable final class LogHandler: Sendable {
    static let captureLock = OSAllocatedUnfairLock()
    let logMessages: LogMessages

    init(logMessages: LogMessages) {
        self.logMessages = logMessages
    }

    func capture(block: () -> Any ) -> Any {
        Self.captureLock.lock()
        defer { Self.captureLock.unlock() }
        self.logMessages.block = ""

        let observer = NotificationCenter.default.addObserver(
            for: LogMessage.self
        ) { self.logMessages.block += $0.line }
        defer {
            NotificationCenter.default.removeObserver(observer)
        }

        let errf = agseterrf { line in
            // A closure for a C function cannot capture variables from its enclosing context, and therefore cannot simply append each log message line to the message block. Use a notification to post the line to an observer.
            if let line {
                let line = String(cString: line)
                if !line.isEmpty {
                    NotificationCenter.default.post(
                        LogMessage(line: line)
                    )
                }
            }
            return 0
        }
        defer { agseterrf(errf) }

        return block()
    }
}
