//
//  GraphvizDocument.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    static var gv: UTType {
        UTType(exportedAs: "com.att.graphviz.graph")
    }
    static var dot: UTType {
        UTType(importedAs: "com.att.graphviz.graph.dot")
    }
}

struct GraphvizDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.gv, .dot] }
    static var writeableContentTypes: [UTType] { [.svg, .pdf, .gv] }
    
    var name: String!
    var data: Data!
    var text: String!
    var graph: Graph!
    
    init() {
        name = nil
        data = nil
        text = nil
        graph = nil
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let name = configuration.file.filename,
              let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadUnknown)
        }
        self.name = name
        self.data = data
        self.text = text
        self.graph = Graph(text: text, utType: .svg)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let text = text,
              let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        print("writing file \(configuration.existingFile?.filename ?? "none") as \(configuration.contentType)")
        return .init(regularFileWithContents: data)
    }
}
