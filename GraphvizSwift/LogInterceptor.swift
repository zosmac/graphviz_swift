//
//  LogInterceptor.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/16/25.
//

import os
import SwiftUI

/// LogObservee provides a place for log messages to be sent for display in the inspector view. This type is observable so that the posting of the message is detectcd by the Text view in InspectorView.
@Observable final class LogObservee: @unchecked Sendable {
    var name: Notification.Name
    var message: String = ""
    init(name: Notification.Name) {
        self.name = name
    }
    
    deinit {
//        print("deinit LogObservee \(name.rawValue)")
    }
}

/// LogObserver awaits log message notifications from graphviz render operations.
final class LogObserver {
    private let name: NSNotification.Name
    let observer: Any
    let observee: LogObservee

    init(name: String) {
        self.name = Notification.Name("GraphvizSwift.LogInterceptor.\(name)")
        self.observee = LogObservee(name: self.name)
        self.observer = NotificationCenter.default.addObserver(
            forName: self.name,
            object: nil,
            queue: nil,
            using: LogObserver.receiver(observee: observee))
//        print("add observer for \(name) \(observer)")
    }

    deinit {
//        print("deinit LogObserver for \(name.rawValue) \(observer)")
        NotificationCenter.default.removeObserver(
            observer,
            name: name,
            object: nil
        )
    }

    static func receiver(observee: LogObservee) -> @Sendable (_ notification: Notification) -> Void {
        return { @Sendable (notification) in
            let string = notification.userInfo?["message"] as! String
//            print(string)
//            DispatchQueue.main.async {
                observee.message = string
//            }
        }
    }
    
    func observe(name: String, block: () -> Any ) -> Any {
        LogInterceptor.logLock.lock()
        fflush(stderr)
        dup2(LogInterceptor.shared.pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        LogInterceptor.shared.pipe.fileHandleForWriting.write(Data("\(name)\n".utf8))
        let result = block()
        LogInterceptor.shared.pipe.fileHandleForWriting.write(Data("\n".utf8))
        dup2(LogInterceptor.shared.duperr, STDERR_FILENO)
        LogInterceptor.logLock.unlock()
        return result
    }
}

/// logInterceptor prevents lazy loading of the global shared LogInterceptor.
let logInterceptor = LogInterceptor.shared

/// LogInterceptor defines a pipe for capturing log messages sent to stderr.
struct LogInterceptor {
    static let shared = LogInterceptor()
    static let logLock = OSAllocatedUnfairLock()
    let pipe = Pipe()
    let duperr = dup(STDERR_FILENO)

    private init() {
//        let duperrHandle = FileHandle(fileDescriptor: duperr)
        pipe.fileHandleForReading.readabilityHandler = { handle in
            var data = Data()
            while true {
                data += handle.availableData
                if data.count > 2 && // TODO: Scan for "\n\n" instead? Use additional exit string?
                    data[data.endIndex-1] == 10 &&
                    data[data.endIndex-2] == 10 {
                    data = data.dropLast(2)
                    let string = String(data: data, encoding: .utf8)!
                    let splits = string.split(separator: "\n")
                    let name = splits[0]
                    let message = splits.count > 1 ? splits[1...].joined(separator: "\n") : ""
//                    duperrHandle.write(Data("\(name): \(message)\n".utf8))
                    if !message.isEmpty {
                        NotificationCenter.default.post(
                            name: Notification.Name("GraphvizSwift.LogInterceptor.\(name)"),
                            object: nil,
                            userInfo: ["message": message]
                        )
                    }
                    data = Data()
                }
            }
        }
    }
}
