//
//  GraphvizDocument.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

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
    static let readableContentTypes: [UTType] = [.gv, .canon]
    static let writableContentTypes: [UTType] = [.gv, .canon]

    let docType: UTType
    var text: String

    init() {
        self.text = ""
        self.docType = .gv
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadUnknown)
        }
        self.text = text
        self.docType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: Data(text.utf8))
    }
}
