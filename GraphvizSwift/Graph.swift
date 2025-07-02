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

@Observable final class Graph {
    static func closeGraph(graph: UnsafeMutablePointer<Agraph_t>?, layout: Bool) {
        if graph != nil {
            if layout {
                print("free layout")
                gvFreeLayout(Graph.graphContext, graph)
            }
            print("close and free graph")
            agclose(graph)
        }
    }
    
    deinit {
        print("deinit requested \(self)")
        if let graph = graph {
            if layout {
                print("free layout")
                gvFreeLayout(Graph.graphContext, graph)
            }
            print("close graph")
            agclose(graph)
        }
        if let observer = observer {
            LogInterceptor.shared.ignore(observer: observer)
        }
    }

    nonisolated(unsafe) static let graphContext = gvContext()
    var graph: UnsafeMutablePointer<Agraph_t>?

    var name: String
    var text: String
    var settings: [[String: String]]!
    var attributes: Attributes!
    var observer: NSObjectProtocol!

    var layout = false
    var updated = false
    var message = ""
    
    @MainActor init(document: Binding<GraphvizDocument>) {
        self.name = document.wrappedValue.name
        self.text = document.wrappedValue.text
        self.graph = createGraph(text)
        self.observer = LogInterceptor.shared.observe(name: document.wrappedValue.name, graph: self)
        print("CREATE OBSERVER \(observer.description) for graph \(name)")
        self.settings = {
            guard let graph = self.graph else { return [[:], [:], [:]] }
            var settings: [[String: String]] = [[:], [:], [:]]
            for kind in [AGRAPH, AGNODE, AGEDGE] { // assumes these are 0, 1, 2 ;)
                var nextSymbol: UnsafeMutablePointer<Agsym_t>? = nil
                while let symbol = agnxtattr(graph, Int32(kind), nextSymbol) {
                    let name = String(cString: symbol.pointee.name)
                    let value = String(cString: symbol.pointee.defval)
                    settings[kind][name] = value
                    print("SETTINGS", kind, name, value)
                    nextSymbol = symbol
                }
            }
            return settings
        }()
        self.attributes = Attributes(graph: self)
    }
    
    func createGraph(_ text: String) -> UnsafeMutablePointer<Agraph_t>! {
        if graph != nil {
            if layout {
                print("free layout")
                gvFreeLayout(Graph.graphContext, graph)
            }
            print("close and free graph")
            agclose(graph)
        }

        updated = true
        layout = false
        message = ""
        
        LogInterceptor.shared.writeBeginMarker()
        defer { LogInterceptor.shared.writeEndMarker(name) }
        return agmemread(text + "\0")
    }
    
    func changeAttribute(kind: Int, name: String, value: String) -> Void {
        if graph != nil &&
            (name.withCString { name in
                return value.withCString { value in
                    return agattr(graph, Int32(kind), UnsafeMutablePointer(mutating: name), UnsafeMutablePointer(mutating: value))
                }
            }) != nil {
            updated = true
        }
    }
    
    func renderGraph(utType: UTType) -> Data {
        updated = false
        guard let graph = graph else {
            return Data()
        }
        
        if layout {
            gvFreeLayout(Graph.graphContext, graph);
        }
        
        layout = true
        var renderedData: UnsafeMutablePointer<CChar>?
        var renderedLength: size_t = 0
        var format = "pdf:quartz"
        switch utType {
        case UTType.svg:
            format = "svg"
        case UTType.pdf:
            break
        default:
            break
        }
        
        LogInterceptor.shared.writeBeginMarker()
        // PSinputscale = 72.0  // TODO: set as for -s CLI flag?
        gvLayout(Graph.graphContext, graph, "dot") // TODO: set as for -K CLI flag?
        gvRenderData(Graph.graphContext, graph, format, &renderedData, &renderedLength)
        LogInterceptor.shared.writeEndMarker(name)
        
        // futile attempts to get svg data to autoscale like pdf
        //            if let svgView = nsView as? WKWebView {
        //                let string = String(decoding: data, as: Unicode.UTF8.self)
        //                let string2 = string.replacingOccurrences(
        //                    of: "<svg(.+)width=\"[^\"]+\" height=\"[^\"]+\"(.*)w",
        //                    with: "<svg$1width=\"100%\" height=\"100%\"$2",
        //                    options: [.regularExpression],
        //                    range: nil)
        //                let string3 = string.replacingOccurrences(
        //                    of: "(.*)viewBox=\"([^ ]+) ([^ ]+) ([^ ]+) ([^\"]+)\"(.*)",
        //                    with: "$1viewBox=\"$2 $3 100% 100%\"$6",
        //                    options: [.regularExpression],
        //                    range: nil)
        //                print(string3)
        //                let data = string3.data(using: .utf8)!
        //            }
        
        return Data(bytes:renderedData!, count:renderedLength)
    }
}
//
//extension Graph {
//    func zoomIn() -> Void {
//        (view as! PDFView).zoomIn(nil)
//    }
//}
