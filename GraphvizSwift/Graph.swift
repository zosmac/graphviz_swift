//
//  Graph.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/12/25.
//

import SwiftUI

class Graph: @unchecked Sendable {
    nonisolated(unsafe) static let graphContext = gvContext()
    
    var graph: UnsafeMutablePointer<Agraph_t>
    var layout = false
    
    init(graph: UnsafeMutablePointer<Agraph_t>) {
        self.graph = graph
    }

    private var _settings : [[String: String]]?
    var settings: [[String: String]] {
        get {
            if let settings = _settings {
                return settings
            }
            var settings: [[String: String]] = [[:], [:], [:]]
            for kind in [AGRAPH, AGNODE, AGEDGE] { // assumes these are 0, 1, 2 ;)
                var nextSymbol: UnsafeMutablePointer<Agsym_t>? = nil
                while let symbol = agnxtattr(graph, Int32(kind), nextSymbol) {
                    let name = String(cString: symbol.pointee.name)
                    let value = String(cString: symbol.pointee.defval)
                    settings[kind][name] = value
                    nextSymbol = symbol
                }
            }
            _settings = settings
            return settings
        }
    }
    
    deinit {
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
        let symbol = name.withCString { name in
            return value.withCString { value in
                return agattr(graph, Int32(kind), UnsafeMutablePointer(mutating: name), UnsafeMutablePointer(mutating: value))
            }
        }
        if let symbol = symbol {
            print("Updated value of \(String(cString: symbol.pointee.name))(\(symbol.pointee.kind)) is \"\(String(cString: symbol.pointee.defval))\"")
        }
    }
}
