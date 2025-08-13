//
//  Graph.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/12/25.
//

import UniformTypeIdentifiers
import SwiftUI
import PDFKit
import WebKit

/// Graph bridges a Graphviz document to its views.
@Observable final class Graph {
    nonisolated(unsafe) static let graphContext = gvContext()

    let name: String
    let observer: LogObserver
    let graph: UnsafeMutablePointer<Agraph_t>?

    var attributes: Attributes
    var settings: [[String: String]]

    init(document: Binding<GraphvizDocument>) {
        self.name = document.wrappedValue.name
        let observer = LogObserver(name: name)
        var graph: UnsafeMutablePointer<Agraph_t>?
        observer.observe(name: name) {
            graph = agmemread(document.wrappedValue.text + "\n")
        }
        print("INIT \(name) \(graph)")
        self.graph = graph
        self.observer = observer
        let settings = {
            var settings: [[String: String]] = [[:], [:], [:]]
            guard let graph else { return settings }
            for kind in [AGRAPH, AGNODE, AGEDGE] { // assumes these are 0, 1, 2 ;)
                var nextSymbol: UnsafeMutablePointer<Agsym_t>? = nil
                while let symbol = agnxtattr(graph, Int32(kind), nextSymbol) {
                    let name = String(cString: symbol.pointee.name)
                    let value = String(cString: symbol.pointee.defval)
                    settings[kind][name] = value
                    nextSymbol = symbol
                }
            }
            return settings
        }()
        self.settings = settings
        self.attributes = Attributes(applying: settings)
    }
    
    // For completeness. This actually only gets called if the NSViewRepresentable
    // using this graph calls dismantleNSView to run closeGraph.
    isolated deinit {
        if graph != nil {
            print("deinit requested \(graph)")
            gvFreeLayout(Graph.graphContext, graph)
            print("close and free graph")
            agclose(graph)
        }
    }

    func changeAttribute(kind: Int, name: String, value: String) -> Void {
        settings[kind][name] = value
        attributes = Attributes(applying: settings)
    }

    func renderGraph(nsView: NSView) -> Data {
        print("RENDER \(name) \(graph)")
        if graph != nil {
            gvFreeLayout(Graph.graphContext, graph)
        } else {
            return Data()
        }

        var format = ""
        switch nsView {
        case nsView as WKWebView:
            format = "svg"
        case nsView as PDFView:
            format = "pdf:quartz"
        default:
            break
        }
        
        if format != "" {
            var renderedData: UnsafeMutablePointer<CChar>?
            var renderedLength: size_t = 0
            // PSinputscale = 72.0  // TODO: set as for -s CLI flag?
            observer.observe(name: name) {
                for (kind, settings) in settings.enumerated() {
                    for (name, value) in settings {
                        _ = name.withCString { name in
                            value.withCString { value in
                                agattr(graph, Int32(kind), UnsafeMutablePointer(mutating: name), UnsafeMutablePointer(mutating: value))
                            }
                        }
                    }
                }
                gvLayout(Graph.graphContext, graph, "dot") // TODO: set as for -K CLI flag?
                gvRenderData(Graph.graphContext, graph, format, &renderedData, &renderedLength)
            }
            return Data(bytes:renderedData!, count:renderedLength)
        }
        
        return Data()
    }
}
