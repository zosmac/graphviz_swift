//
//  GraphvizDocument.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI
//import Synchronization

nonisolated
extension UTType {
    static var gv: UTType {
        UTType(exportedAs: "com.att.graphviz.graph")
    }
    static var canon: UTType {
        UTType(exportedAs: "com.att.graphviz.graph.canon")
    }
}

/// GraphvizDocument contains the contents of the file.
struct GraphvizDocument: FileDocument {
//@Observable final class GraphvizDocument: ReferenceFileDocument {
    static let readableContentTypes: [UTType] = [.gv, .canon]
    static let writableContentTypes: [UTType] = [.gv, .canon]
//    struct Storage {
//        var data: Data
//    }
//    let storage: Mutex<Storage>

    let docType: UTType
    var text: String
//    var text: String {
//        get { storage.withLock { String(data: $0.data, encoding: .utf8) ?? "" } }
//        set { storage.withLock { $0.data = Data(newValue.utf8) } }
//    }

    init() {
//        self.storage = .init(.init(data: Data()))
        self.text = ""
        self.docType = .gv
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadUnknown)
        }
//        self.storage = .init(.init(data: data))
        self.text = text
        self.docType = configuration.contentType
    }

    func snapshot(contentType: UTType) throws -> Data {
        Data(text.utf8)
//        storage.withLock { $0.data }
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: snapshot)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: Data(text.utf8))
    }
}
