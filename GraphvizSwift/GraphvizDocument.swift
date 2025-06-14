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
              let text = String(data: data, encoding: .utf8),
              let graph = agmemread(text + "\0") else {
            throw CocoaError(.fileReadUnknown)
        }
        self.name = name
        self.data = data
        self.text = text
        self.graph = Graph(graph: graph)
        
        //        let bb = document.attributes.settings[AGRAPH]["bb"]
        //        print("size of graph is \(String(describing: bb))")
        //        let s = bb?.split(separator: " ")
        //        let w = Float(s![2]) ?? 0
        //        let h = Float(s![3]) ?? 0
        //        document.width = CGFloat(w)
        //        document.height = CGFloat(h)
        //        print("width \(document.width) height \(document.height)")
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let text = text,
              let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return .init(regularFileWithContents: data)
    }
    
    // in case this ever becomes a ReferenceFileDocument (a class)
//    typealias Snapshot = String?
//    func snapshot(contentType: UTType) throws -> Snapshot {
//        guard let text = text else {
//            throw CocoaError(.fileWriteUnknown)
//        }
//        return text
//    }
//
//    func fileWrapper(snapshot: Snapshot, configuration: WriteConfiguration) throws -> FileWrapper {
//        guard let snapshot = snapshot,
//              let data = snapshot.data(using: .utf8) else {
//            throw CocoaError(.fileWriteUnknown)
//        }
//        return .init(regularFileWithContents: data)
//    }
}
