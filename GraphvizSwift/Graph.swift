//
//  Graph.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/12/25.
//

import UniformTypeIdentifiers
import SwiftUI

/// Graph bridges a Graphviz document to its views.
@Observable final class Graph {
    nonisolated(unsafe) static let context = gvContext()

    var text: String!
    var viewType: String
    var data = Data()
    var settings = Array(repeating: [String: String](), count: 3)
    var attributes: Attributes? // set in render
    let logMessage = LogMessage()
    let handler: GraphvizLogHandler

    init(text: String, viewType: String) {
        self.handler = GraphvizLogHandler(logMessage: logMessage)
        self.text = text
        self.viewType = viewType
        render(text: text)
    }

    func changeAttribute(kind: Int?, name: String, value: String) -> Void {
        if let kind {
            settings[kind][name] = value
            render(text: text)
        }
    }

    func render(text: String) -> Void {
        data = handler.capture {
            guard let graph = agmemread(text + "\n") else { return Data() }
            print("RENDER performed for \(viewType) \(graph, default: "nil")")
            for kind in [AGRAPH, AGNODE, AGEDGE] {
                var nextSymbol: UnsafeMutablePointer<Agsym_t>? = nil
                while let symbol = agnxtattr(graph, Int32(kind), nextSymbol) {
                    let name = String(cString: symbol.pointee.name)
                    let value = String(cString: symbol.pointee.defval)
                    settings[kind][name] = value
                    nextSymbol = symbol
                }
            }
            attributes = Attributes(applying: settings)

            var renderedData: UnsafeMutablePointer<CChar>?
            var renderedLength: size_t = 0
            for (kind, settings) in settings.enumerated() {
                for (name, value) in settings {
                    _ = name.withCString { name in
                        value.withCString { value in
                            // withCString sends in an UnsafePointer. Because agattr does not declare its parameters as const, must recast argument to UnsafeMutablePointer.
                            return agattr_text(graph, Int32(kind), UnsafeMutablePointer(mutating: name), UnsafeMutablePointer(mutating: value))
                        }
                    }
                }
            }
            gvLayout(Graph.context, graph, "dot") // TODO: set as for -K CLI flag?
            defer { gvFreeLayout(Graph.context, graph) }
            if gvRenderData(Graph.context, graph, viewType, &renderedData, &renderedLength) == 0 {
                return Data(bytesNoCopy: renderedData!,
                            count: renderedLength,
                            deallocator: .custom { ptr, _ in
                    gvFreeRenderData(ptr) // presumably frees up render memory
                })
            }
            return Data()
        } as! Data
    }
}
