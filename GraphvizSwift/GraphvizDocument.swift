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
    var attributes: Attributes!
    
    init() {
        name = nil
        data = nil
        text = nil
        graph = nil
        attributes = nil
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
        self.graph = Graph(text: text)
        attributes = Attributes()

        // read document's graph/node/edge settings
        var settings: [[String: String]] = [[:], [:], [:]]
        for kind in [AGRAPH, AGNODE, AGEDGE] { // assumes these are 0, 1, 2 ;)
            var nextSymbol: UnsafeMutablePointer<Agsym_t>?
            while let symbol = agnxtattr(graph.graph, Int32(kind), nextSymbol) {
                let name = String(cString: symbol.pointee.name)
                let value = String(cString: symbol.pointee.defval)
                Swift.print("\(name)(\(symbol.pointee.kind)): \"\(value)\"")
                settings[kind][name] = value
                nextSymbol = symbol
            }
        }
        
        // record settings in attributes
        for kind in [AGRAPH, AGNODE, AGEDGE] {
            for attribute in attributes.tables[kind] {
                if let value = settings[kind][attribute.name] {
                    attribute.value = value
                }
            }
        }
        
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
