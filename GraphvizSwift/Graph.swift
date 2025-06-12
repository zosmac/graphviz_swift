//
//  Graph.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/12/25.
//

import Foundation

final class Graph: @unchecked Sendable {
    static let graphContext = gvContext()
    
    var graph: UnsafeMutablePointer<Agraph_t>
    var layout: Bool
    
    init(text: String) {
        graph = agmemread(text + "\0")
        layout = false
    }
    deinit { // For Swift 6, how to get this to run on the MainActor??
        if layout {
            print("free layout")
            gvFreeLayout(Graph.graphContext, graph)
        }
        print("close graph")
        agclose(graph)
    }
    
    @MainActor
    func renderGraph() -> Data {
        if layout {
            gvFreeLayout(Graph.graphContext, graph);
        }
        // PSinputscale = 72.0  // TODO: set as for -s CLI flag?
        gvLayout(Graph.graphContext, graph, "dot") // TODO: set as for -K CLI flag?
        layout = true
        var renderedData: UnsafeMutablePointer<CChar>?
        var renderedLength: size_t = 0
        let format = "pdf:quartz"
        gvRenderData(Graph.graphContext, graph, format, &renderedData, &renderedLength)
        return Data(bytes:renderedData!, count:renderedLength)
    }
    
    @MainActor
    func changeAttribute(kind: Int, name: String, value: String) -> Void {
        var symbol = name.withCString { name in
            return value.withCString { value in
                return agattr(graph, Int32(kind), UnsafeMutablePointer(mutating: name), nil)
            }
        }
        if let symbol = symbol {
            print("Current value of \(String(cString: symbol.pointee.name))(\(symbol.pointee.kind)) is \"\(String(cString: symbol.pointee.defval))\"")
        }
        symbol = name.withCString { name in
            return value.withCString { value in
                return agattr(graph, Int32(kind), UnsafeMutablePointer(mutating: name), UnsafeMutablePointer(mutating: value))
            }
        }
        if let symbol = symbol {
            print("Updated value of \(String(cString: symbol.pointee.name))(\(symbol.pointee.kind)) is \"\(String(cString: symbol.pointee.defval))\"")
        }
    }
}
