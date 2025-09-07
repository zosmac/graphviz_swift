//
//  GraphvizDocument.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    nonisolated static var canon: UTType {
        UTType(exportedAs: "com.att.graphviz.graph.canonical")
    }
    nonisolated static var gv: UTType {
        UTType(exportedAs: "com.att.graphviz.graph")
    }
    nonisolated static var dot: UTType {
        UTType(importedAs: "com.att.graphviz.graph.dot")
    }
}

/// GraphvizDocument contains the contents of the file.
final class GraphvizDocument: ReferenceFileDocument {
    static let readableContentTypes: [UTType] = [.gv, .dot, .canon]
    static let writableContentTypes: [UTType] = [.gv, .dot, .canon]
    typealias Snapshot = Data
    
    let name: String
    let docType: UTType
    @Published var text: String!
    @Published var graph: Graph!
    
    init() {
        self.name = ""
        self.text = ""
        self.docType = .gv
    }

    init(configuration: ReadConfiguration) throws {
        guard let name = configuration.file.filename,
              let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadUnknown)
        }
        self.name = name
        self.text = text
        self.docType = configuration.contentType
        self.graph = Graph(text: text)
    }

    func snapshot(contentType: UTType) throws -> Data {
        Data(text.utf8)
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: snapshot)
    }
}
