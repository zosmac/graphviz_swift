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
    var text: String
    var attributes: Attributes!
    let logMessage = LogMessage()

    init(text: String) {
        self.text = text
    }

    func render(viewType: String, settings: [[String: String]]) -> Data {
        let handler = GraphvizLogHandler(logMessage: logMessage)
        return handler.capture {
            print("RENDER for \(viewType)")
            guard let graph = agmemread(text + "\n") else { return Data() }
            defer { agclose(graph) }
            print("GRAPH is \(graph)")

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

            var settings = Array(repeating: [String: String](), count: 3)
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
            let context = gvContext()
            defer { gvFreeContext(context) }
            gvLayout(context, graph, "dot") // TODO: set as for -K CLI flag?
            defer { gvFreeLayout(context, graph) }
            if gvRenderData(context, graph, viewType, &renderedData, &renderedLength) == 0 {
                return Data(bytesNoCopy: renderedData!,
                            count: renderedLength,
                            deallocator: .custom { ptr, _ in
                    gvFreeRenderData(ptr)
                })
            }
            return Data()
        } as! Data
    }
}
