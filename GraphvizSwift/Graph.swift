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

class Graph: @unchecked Sendable {
    nonisolated(unsafe) static let graphContext = gvContext()
    
    private var graph: UnsafeMutablePointer<Agraph_t>?
    private var layout = false
    private var utType: UTType
    private var _nsView: NSView?
    @MainActor var nsView: NSView {
        get {
            if _nsView == nil {
                switch utType {
                case UTType.pdf:
                    let pdfView = PDFView()
                    pdfView.autoScales = true
                    _nsView = pdfView
                case UTType.svg:
//                    let configuration = WKWebViewConfiguration()
//                    configuration.defaultWebpagePreferences = WKWebpagePreferences()
//                    configuration.defaultWebpagePreferences.preferredContentMode = .desktop
//                    let svgView = WKWebView(frame: .zero, configuration: configuration)
//                    svgView.autoresizesSubviews = true
//                    _nsView = svgView
                    _nsView = WKWebView()
                default:
                    _nsView = NSView()
                }
            }
            return _nsView!
        }
    }
    
    init(text: String, utType: UTType = UTType.pdf) {
        self.utType = utType
        let stderr = FileHandle.standardError
        try? stderr.write(contentsOf: "============\n".data(using: .utf8)!)
        self.graph = agmemread(text + "\0")
        try? stderr.write(contentsOf: "============\n".data(using: .utf8)!)
        if self.graph == nil {
            _settings = [[:], [:], [:]]
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
    func renderGraph() -> Void {
        if graph != nil {
            if layout {
                gvFreeLayout(Graph.graphContext, graph);
            }
            // PSinputscale = 72.0  // TODO: set as for -s CLI flag?
            gvLayout(Graph.graphContext, graph, "dot") // TODO: set as for -K CLI flag?
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
            
            gvRenderData(Graph.graphContext, graph, format, &renderedData, &renderedLength)
            let data = Data(bytes:renderedData!, count:renderedLength)
            
            if let pdfView = nsView as? PDFView {
                pdfView.document = PDFDocument(data: data)
            } else if let svgView = nsView as? WKWebView {
                let svgMimeType = UTType.svg.preferredMIMEType ?? "image/svg+xml"
                let utf8EncodingName = "UTF-8"
                let string = String(decoding: data, as: Unicode.UTF8.self)
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

                svgView.load(data, mimeType: svgMimeType, characterEncodingName: utf8EncodingName, baseURL: URL(filePath: "http://www.graphviz.org/")
                )
            }
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
    
    @MainActor
    func zoomIn() {
        if let pdfView = nsView as? PDFView {
            pdfView.zoomIn(self)
        } else if let svgView = nsView as? WKWebView {
            svgView.pageZoom *= 1.1
        }
    }
    
    @MainActor
    func zoomOut() {
        if let pdfView = nsView as? PDFView {
            pdfView.zoomOut(self)
        } else if let svgView = nsView as? WKWebView {
            svgView.pageZoom /= 1.1
        }
    }
    
    @MainActor
    func zoomToActual() {
        if let pdfView = nsView as? PDFView {
            pdfView.scaleFactor = 1.0
        } else if let svgView = nsView as? WKWebView {
            svgView.pageZoom = 1.0
        }
    }
    
    @MainActor
    func zoomToFit() {
        if let pdfView = nsView as? PDFView {
            pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
        } else if let svgView = nsView as? WKWebView {
            //            var width = view frame width/svg view width
            //            var height = view frame height/svg view height
            //            var scale = min(width, height) // but this is too big!
            //            svgView.pageZoom = scale
            svgView.pageZoom = 2.0 // a guess for now, cannot find a way to scale svg to view size
        }
    }
}
