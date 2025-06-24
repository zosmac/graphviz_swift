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
    static var writeableContentTypes: [UTType] { [.pdf, .svg, .gv] }
    
    var text = ""
    var graph: Graph!

    init() {}
    
    init(configuration: ReadConfiguration) throws {
        guard let name = configuration.file.filename,
              let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadUnknown)
        }
        self.text = text
        self.graph = Graph(name: name, text: text)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        print("file write requested")
        return .init(regularFileWithContents: text.data(using: .utf8)!)
    }
}
