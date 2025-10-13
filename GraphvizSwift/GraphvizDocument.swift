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
    static var canon: UTType {
        UTType(exportedAs: "com.att.graphviz.graph.canon")
    }
}

/// GraphvizDocument contains the contents of the file.
//struct GraphvizDocument: FileDocument {
@Observable final class GraphvizDocument: ReferenceFileDocument {
    static let readableContentTypes: [UTType] = [.gv, .canon]
    static let writableContentTypes: [UTType] = [.gv, .canon]
    typealias Snapshot = Data
    
    let name: String
    let docType: UTType
    var text: String

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
    }

    func snapshot(contentType: UTType) throws -> Data {
        Data(text.utf8)
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        return .init(regularFileWithContents: snapshot)
    }

//    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
//        return .init(regularFileWithContents: Data(text.utf8))
//    }
}
