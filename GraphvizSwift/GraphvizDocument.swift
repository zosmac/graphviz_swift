//
//  GraphvizDocument.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    nonisolated static var gv: UTType {
        UTType(exportedAs: "com.att.graphviz.graph")
    }
    nonisolated static var dot: UTType {
        UTType(importedAs: "com.att.graphviz.graph.dot")
    }
}

/// GraphvizDocument contains the contents of the file.
nonisolated
struct GraphvizDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.gv, .dot] }
    static var writableContentTypes: [UTType] { [.pdf, .svg, .gv] }
    
    let name: String
    var text: String
    
    init() {
        self.name = ""
        self.text = ""
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let name = configuration.file.filename,
              let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadUnknown)
        }
        self.name = name
        self.text = text
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: Data(text.utf8))
    }
}
