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
nonisolated
struct Graph {
    nonisolated(unsafe) static let graphContext = gvContext()
    nonisolated(unsafe) static let attributeDefaults = ParsedAttributes()
    nonisolated(unsafe) static var attributeDocumentation = """
    <style>
      p {font-family:sans-serif;font-size:10pt}
    </style>
    """

    let name: String
    nonisolated(unsafe) var observer: LogObserver!
//    nonisolated(unsafe) var graph: UnsafeMutablePointer<Agraph_t>?

    class Pointer {
        var graph: UnsafeMutablePointer<Agraph_t>?
        init(graph: UnsafeMutablePointer<Agraph_t>?) {
            self.graph = graph
        }
        deinit {
            if graph != nil {
                gvFreeLayout(Graph.graphContext, graph)
                agclose(graph)
            }
        }
    }

    var pointer: Pointer!
    var attributes: Attributes!
    var settings: [[String: String]]!
    
    nonisolated
    init() {
        self.name = ""
    }
    
    nonisolated
    init(name: String, text: String) {
        self.name = name
        let observer = LogObserver(name: name)
        var graph: UnsafeMutablePointer<Agraph_t>?
        observer.observe(name: name) {
            graph = agmemread(text + "\n")
        }
//        print("INIT \(name) \(graph)")
        self.pointer = Pointer(graph: graph)
//        self.graph = graph
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
    
//    deinit {
////        print("deinit Graph \(name) \(graph)")
//        if graph != nil {
//            gvFreeLayout(Graph.graphContext, graph)
//            agclose(graph)
//        }
//    }

    mutating func changeAttribute(kind: Int, name: String, value: String) -> Void {
        settings[kind][name] = value
        attributes = Attributes(applying: settings)
    }

    func renderGraph(nsView: NSView) -> Data {
//        print("RENDER \(name) \(graph)")
        var data = Data()
        if pointer.graph != nil {
            gvFreeLayout(Graph.graphContext, pointer.graph)
        } else {
            return data
        }

        var format = ""
        switch nsView {
        case nsView as WKWebView:
            format = "svg"
        case nsView as PDFView:
            format = "pdf"
        default:
            return data
        }
        
        observer.observe(name: name) {
            var renderedData: UnsafeMutablePointer<CChar>?
            var renderedLength: size_t = 0
            // PSinputscale = 72.0  // TODO: set as for -s CLI flag using Settings View
            for (kind, settings) in settings.enumerated() {
                for (name, value) in settings {
                    _ = name.withCString { name in
                        value.withCString { value in
                            agattr_text(pointer.graph, Int32(kind), UnsafeMutablePointer(mutating: name), UnsafeMutablePointer(mutating: value))
                        }
                    }
                }
            }
            gvLayout(Graph.graphContext, pointer.graph, "dot") // TODO: set as for -K CLI flag?
            if gvRenderData(Graph.graphContext, pointer.graph, format, &renderedData, &renderedLength) == 0 {
                data = Data(bytesNoCopy: renderedData!,
                            count: renderedLength,
                            deallocator: .custom { ptr, _ in
                    gvFreeRenderData(ptr)
                })
            }
        }
        
        return data
    }
    
    nonisolated
    func renderGraph(utType: UTType) throws -> Data {
        guard let format = utType.preferredFilenameExtension else { throw CocoaError(.fileWriteUnsupportedScheme) }
        var data: Data?
        observer.observe(name: name) {
            var renderedData: UnsafeMutablePointer<CChar>!
            var renderedLength: size_t = 0
//            gvLayout(Graph.graphContext, graph, "dot") // TODO: set as for -K CLI flag?
            if gvRenderData(Graph.graphContext, pointer.graph, format, &renderedData, &renderedLength) == 0 {
                data = Data(bytesNoCopy: renderedData!,
                                count: renderedLength,
                                deallocator: .custom { ptr, _ in
                    gvFreeRenderData(ptr)
                })
            }
        }
        guard let data else { throw CocoaError(.fileWriteUnknown) }
        return data
    }
}
