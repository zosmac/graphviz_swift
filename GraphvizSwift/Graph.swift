//
//  Graph.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/12/25.
//

import SwiftUI

class Graph: @unchecked Sendable {
    static let pipe = Pipe()
    nonisolated(unsafe) static let graphContext = gvContext()
    nonisolated(unsafe) static var pipeInitialized: Bool = false
    nonisolated(unsafe) static var messages: [String] = []

    var graph: UnsafeMutablePointer<Agraph_t>?
    var layout = false
    var message: String?
    
    init(text: String) {
        if !Graph.pipeInitialized {
            Graph.pipe.fileHandleForReading.readabilityHandler = { handle in
                while true {
                    let data = handle.availableData
                    if !data.isEmpty {
                        let message = String(data: data, encoding: .utf8)
                        print("message read in handler is \(message ?? "(no message)")")
                        Graph.messages.append(message ?? "(no message)")
                    }
                }
            }
            dup2(Graph.pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
            Graph.pipeInitialized = true
        }
        
        Graph.messages = []
        self.message = nil
        self.graph = agmemread(text + "\0")
        if self.graph == nil {
            _settings = [[:], [:], [:]]
        }
        print("any messages? \(Graph.messages.count)")
        if Graph.messages.count > 0 {
            self.message = Graph.messages.joined(separator: "\n")
        }
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
        if graph != nil {
            if layout {
                print("free layout")
                gvFreeLayout(Graph.graphContext, graph)
            }
            print("close graph")
            agclose(graph)
        }
    }
    
    @MainActor
    func renderGraph() -> Data {
        if graph != nil {
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
        } else {
            return Data()
        }
    }
    
    @MainActor
    func changeAttribute(kind: Int, name: String, value: String) -> Void {
        if graph != nil {
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
}
