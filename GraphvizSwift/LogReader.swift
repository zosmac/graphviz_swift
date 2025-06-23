//
//  LogReader.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/16/25.
//

import Foundation

actor LogReader {
    static let shared = LogReader()
    static let fileNumber: Int32 = STDERR_FILENO
    static let beginMarker = "<<<<<<<<<<\n"
    static let endMarker = ">>>>>>>>>> "
    private let pipe = Pipe()
    var message: String = ""
    
    func addObserver(document: GraphvizDocument) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GraphvizSwift.LogReader."+document.graph.name),
            object: nil, queue: nil) {
                document.graph.message = $0.object as! String
            }
    }
    
    private init() {
        let stderr = dup(LogReader.fileNumber)
        let stderrHandle = FileHandle(fileDescriptor: stderr)
        pipe.fileHandleForReading.readabilityHandler = { handle in
            var graphvizMessage = false
            var message: String = ""
            var name: String = ""
            while true {
                let data = handle.availableData
                if data.isEmpty {
                    continue
                }
                guard let record = String(data: data, encoding: .utf8) else {
                    continue
                }
                if record.isEmpty {
                    continue
                }
                if record == LogReader.beginMarker {
                    try? stderrHandle.write(contentsOf: data) // debug
                    graphvizMessage = true
                    message = ""
                    continue
                } else if record.prefix(LogReader.endMarker.count) == LogReader.endMarker {
                    try? stderrHandle.write(contentsOf: data) // debug
                    graphvizMessage = false
                    name = String(record.suffix(record.count-LogReader.endMarker.count)) // will include newline
                    try? stderrHandle.write(contentsOf: message.data(using: .utf8) ?? Data())
                    if !message.isEmpty {
                        NotificationCenter.default.post(name: Notification.Name("GraphvizSwift.LogReader.\(name)"), object: message)
                    }
                    message = ""
                } else if graphvizMessage {
                    try? stderrHandle.write(contentsOf: data) // debug
                    message += record
                } else {
                    try? stderrHandle.write(contentsOf: data)
                }
            }
        }
        dup2(pipe.fileHandleForWriting.fileDescriptor, LogReader.fileNumber)
    }
}
