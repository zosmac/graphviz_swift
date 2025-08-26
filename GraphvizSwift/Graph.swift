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

nonisolated(unsafe) let graphContext = gvContext()

/// Graph bridges a Graphviz document to its views.
@Observable final class Graph {
    let name: String
    var observer: LogObserver!
    nonisolated(unsafe) let graph: UnsafeMutablePointer<Agraph_t>?

    var attributes: Attributes!
    var settings: [[String: String]]!
    
    nonisolated
    init() {
        self.name = ""
        self.graph = nil
    }
    
    nonisolated
    init(name: String, text: String) {
        self.name = name
        let observer = LogObserver(name: name)
        self.graph = observer.observe(name: name) {
            return agmemread(text + "\n") as Any
        } as! UnsafeMutablePointer<Agraph_t>?
//        print("INIT \(name) \(graph)")
        self.observer = observer
        var settings: [[String: String]] = [[:], [:], [:]]
        if let graph {
            for kind in parsedAttributes.kinds { // assumes these are 0, 1, 2 ;)
                var nextSymbol: UnsafeMutablePointer<Agsym_t>? = nil
                while let symbol = agnxtattr(graph, Int32(kind.kind), nextSymbol) {
                    let name = String(cString: symbol.pointee.name)
                    let value = String(cString: symbol.pointee.defval)
                    settings[kind.kind][name] = value
                    nextSymbol = symbol
                }
            }
        }
        self.settings = settings
        self.attributes = Attributes(applying: settings)
    }
    
    deinit {
        print("deinit Graph \(name) \(graph)")
        if graph != nil {
            agclose(graph)
        }
    }

    func changeAttribute(kind: Int, name: String, value: String) -> Void {
        settings[kind][name] = value
        attributes = Attributes(applying: settings)
    }

    nonisolated
    func renderGraph(viewType: UTType) -> Data {
        print("RENDER \(name) \(viewType) \(graph)")
        guard let format = viewType.preferredFilenameExtension,
              let graph else { return Data() }

        return observer.observe(name: name) {
            var data = Data()
            var renderedData: UnsafeMutablePointer<CChar>?
            var renderedLength: size_t = 0
            // PSinputscale = 72.0  // TODO: set as for -s CLI flag using Settings View
            for (kind, settings) in settings.enumerated() {
                for (name, value) in settings {
                    _ = name.withCString { name in
                        value.withCString { value in
                            return agattr_text(graph, Int32(kind), UnsafeMutablePointer(mutating: name), UnsafeMutablePointer(mutating: value))
                        }
                    }
//                    guard let symbol else { continue }
//                    print ("SET? \(name) \(value)")
//                    let name = String(cString: symbol.pointee.name)
//                    let value = String(cString: symbol.pointee.defval)
//                    print ("SET! \(name) \(value)")
                }
            }
//            let device = format+":quartz"
            gvLayout(graphContext, graph, "dot") // TODO: set as for -K CLI flag?
            if gvRenderData(graphContext, graph, format, &renderedData, &renderedLength) == 0 {
                data = Data(bytesNoCopy: renderedData!,
                            count: renderedLength,
                            deallocator: .custom { ptr, _ in
                    gvFreeRenderData(ptr)
                })
            }
            gvFreeLayout(graphContext, graph)
            return data
        } as! Data
    }
}
