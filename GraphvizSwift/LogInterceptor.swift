//
//  LogInterceptor.swift
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
            forName: NSNotification.Name("GraphvizSwift.LogInterceptor.\(name)\n"),
            object: nil, queue: nil) {
                print("message update \($0.object ?? "")")
//                graph.message = $0.object as! String
            }
    }
    
    nonisolated func ignore(observer: NSObjectProtocol) {
        print("REMOVE OBSERVER \(observer.description)")
        NotificationCenter.default.removeObserver(observer)
    }

    private init() {
        self.duperrHandle = FileHandle(fileDescriptor: duperr)
        pipe.fileHandleForReading.readabilityHandler = { handle in
            var interceptMessage = false
            var message: Data!
            while true {
                let data = handle.availableData
                if data.isEmpty {
                    continue
                }
                if data == self.beginMarker {
                    try? self.duperrHandle.write(contentsOf: data) // debug
                    interceptMessage = true
                    message = nil
                } else if data.prefix(self.endMarker.count) == self.endMarker {
                    try? self.duperrHandle.write(contentsOf: data) // debug
                    interceptMessage = false
                    let name = String(data: data.suffix(data.count-self.endMarker.count), encoding: .utf8) // will include newline
                    if name != nil && message != nil {
                        print("name is |\(name!)|\twith error message \(message!)")
                        var string = String(data: message, encoding: .utf8)!
                        string = string.replacingOccurrences(of: "\n", with: " ")+"\n"
                        try? self.duperrHandle.write(contentsOf: string.data(using: .utf8) ?? Data())
                        NotificationCenter.default.post(name: Notification.Name("GraphvizSwift.LogInterceptor.\(name!)"), object: string)
                        message = nil
                    }
                } else if interceptMessage {
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
