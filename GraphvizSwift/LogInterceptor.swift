//
//  LogReader.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/16/25.
//

import SwiftUI

actor LogInterceptor {
    static let shared = LogInterceptor()
    
    let duperr = dup(STDERR_FILENO)
    let duperrHandle: FileHandle
    let stderrHandle = FileHandle(fileDescriptor: STDERR_FILENO)
    let beginMarker = "<<<<<<<<<<\n".data(using: .utf8)!
    let endMarker = ">>>>>>>>>> ".data(using: .utf8)!
    let pipe = Pipe()
    
    nonisolated func writeBeginMarker() {
        try? stderrHandle.write(contentsOf: beginMarker)
    }
    
    nonisolated func writeEndMarker(_ name: String) {
        try? stderrHandle.write(contentsOf: endMarker + "\(name)\n".data(using: .utf8)!)
    }
    
    nonisolated func observe(name: String, graph: Graph) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GraphvizSwift.LogReader.\(name)\n"),
            object: nil, queue: nil) {
                graph.message = $0.object as! String
            }
    }
    
    nonisolated func ignore(observer: NSObjectProtocol) {
        print("REMOVE OBSERVER")
        NotificationCenter.default.removeObserver(observer)
    }

    private init() {
        self.duperrHandle = FileHandle(fileDescriptor: duperr)
        pipe.fileHandleForReading.readabilityHandler = { handle in
            var graphvizMessage = false
            var message: Data!
            while true {
                let data = handle.availableData
                if data.isEmpty {
                    continue
                }
                if data == self.beginMarker {
                    try? self.duperrHandle.write(contentsOf: data) // debug
                    graphvizMessage = true
                    message = nil
                } else if data.prefix(self.endMarker.count) == self.endMarker {
                    try? self.duperrHandle.write(contentsOf: data) // debug
                    graphvizMessage = false
                    if let name = String(data: data.suffix(data.count-self.endMarker.count), encoding: .utf8), // will include newline
                       let message = message {
                        print("name is <\(name)> error message is \(String(data: message, encoding: .utf8) ?? "(null)")")
                        try? self.duperrHandle.write(contentsOf: message)
                        NotificationCenter.default.post(name: Notification.Name("GraphvizSwift.LogReader.\(name)"), object: String(data: message, encoding: .utf8))
                    }
                    message = nil
                } else if graphvizMessage {
                    try? self.duperrHandle.write(contentsOf: data) // debug
                    if message == nil {
                        message = data
                    } else {
                        message += data
                    }
                } else {
                    try? self.duperrHandle.write(contentsOf: data)
                }
            }
        }
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
    }
}
