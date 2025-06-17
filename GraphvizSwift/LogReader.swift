//
//  LogReader.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/16/25.
//

import Foundation

class LogReader {
    nonisolated(unsafe) static let shared: LogReader = {
        let instance = LogReader()
        let stderr = dup(STDERR_FILENO)
        let stderrHandle = FileHandle(fileDescriptor: stderr)
        pipe.fileHandleForReading.readabilityHandler = { handle in
            while true {
                let data = handle.availableData
                if !data.isEmpty {
                    let message = String(data: data, encoding: .utf8)
                    try? stderrHandle.write(contentsOf: data)
//                    print("message read in handler is \(message ?? "(no message)")")
                    messages.append(message ?? "(no message)")
                }
            }
        }
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        return instance
    }()
    
    nonisolated(unsafe) static var pipe = Pipe()
    nonisolated(unsafe) static var messages: [String] = []
    
    static func clearMessages() {
        messages.removeAll()
    }
}
