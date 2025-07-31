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
    nonisolated(unsafe) static let graphContext = gvContext()
    let name: String
    let text: String

    var graph: UnsafeMutablePointer<Agraph_t>?
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

    // For completeness. This actually only gets called if the NSViewRepresentable
    // using this graph calls dismantleNSView to run closeGraph.
    deinit {
        print("deinit requested \(self)")
        closeGraph()
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
    
    func closeGraph() {
        if let graph = graph {
            if layout {
                print("free layout")
                gvFreeLayout(Graph.graphContext, graph)
            }
            print("close and free graph")
            agclose(graph)
        }
        graph = nil
        if let observer = observer {
            LogInterceptor.shared.ignore(observer: observer)
        }
        observer = nil
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
    
    @MainActor
    func renderGraph(nsView: NSView) -> Void {
        updated = false
        guard let graph = graph else {
            return
        }
        
        if layout {
            gvFreeLayout(Graph.graphContext, graph);
        }
        
        layout = true
        var renderedData: UnsafeMutablePointer<CChar>?
        var renderedLength: size_t = 0
        
        var format: String
        switch nsView {
        case nsView as WKWebView:
            format = "svg"
        case nsView as PDFView:
            format = "pdf:quartz"
        default:
            return
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
        
        let data = Data(bytes:renderedData!, count:renderedLength)
        switch nsView {
        case let nsView as WKWebView:
            nsView.load(
                data,
                mimeType: UTType.svg.preferredMIMEType!,
                characterEncodingName: "UTF-8",
                baseURL: URL(filePath: "")
            )
        case let nsView as PDFView:
            nsView.document = PDFDocument(data: data)
        default:
            break
        }

    }
}
//
//extension Graph {
//    func zoomIn() -> Void {
//        (view as! PDFView).zoomIn(nil)
//    }
//}
