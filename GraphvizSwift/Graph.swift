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

@Observable final class Graph: @unchecked Sendable {
    @MainActor
    static let graphContext = gvContext()
    
    @MainActor
    static func closeGraph(graph: UnsafeMutablePointer<Agraph_t>?, layout: Bool) {
        if graph != nil {
            if layout {
                print("free layout")
                gvFreeLayout(Graph.graphContext, graph)
            }
            print("close graph")
            agclose(graph)
        }
    }
    
    private var graph: UnsafeMutablePointer<Agraph_t>? = nil
    private var utType = UTType.pdf
    private var layout = false
    private let beginMarker = LogReader.beginMarker.data(using: .utf8)!
    private let endMarker: Data!
    private let stderr: FileHandle!
    private var observer: NSObjectProtocol?
    var name: String = ""
    var updated = false
    var message = ""
    
    private var _nsView: NSView? = nil
    @MainActor
    var nsView: NSView {
        get {
            if _nsView == nil {
                switch utType {
                case UTType.pdf:
                    let pdfView = PDFView()
                    pdfView.autoScales = true
                    _nsView = pdfView
                case UTType.svg:
                    // futile attempts to get svg data to autoscale like pdf
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
    
    private var _settings: [[String: String]]?
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
                    print("SETTINGS", kind, name, value)
                    nextSymbol = symbol
                }
            }
            _settings = settings
            return settings
        }
    }
    
    private var _attributes: Attributes?
    var attributes: Attributes {
        get {
            if let attributes = _attributes {
                return attributes
            }
            _attributes = Attributes(graph: self)
            return _attributes!
        }
    }
    
    init() {
        self.endMarker = nil
        self.stderr = nil
    }

    init(name: String, text: String, utType: UTType = UTType.pdf) {
        self.name = name
        self.utType = utType
        self.endMarker = "\(LogReader.endMarker)\(name)\n".data(using: .utf8)!
        //        let stderr = FileHandle.standardError
        self.stderr = FileHandle(fileDescriptor: LogReader.fileNumber)
        self.observer = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GraphvizSwift.LogReader.\(name)\n"),
            object: nil, queue: nil) {
                self.message = $0.object as! String
            }
        self.graph = createGraph(text)
    }

    func createGraph(_ text: String) -> UnsafeMutablePointer<Agraph_t>? {
        updated = true
        layout = false
        message = ""

        try? stderr.write(contentsOf: beginMarker)
        let graph = agmemread(text + "\0")
        try? stderr.write(contentsOf: endMarker)

        if graph == nil {
            _settings = [[:], [:], [:]]
        } else {
            _settings = nil
            _attributes = nil
        }
        return graph
    }

    deinit {
        let graph = self.graph
        let layout = self.layout
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
        DispatchQueue.main.async {
            Graph.closeGraph(graph: graph, layout: layout)
        }
    }
    
    @MainActor
    func updateGraph(text: String) {
        Graph.closeGraph(graph: graph, layout: layout)
        graph = createGraph(text)
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
                updated = true
                print("Updated value of \(String(cString: symbol.pointee.name))(\(symbol.pointee.kind)) is \"\(String(cString: symbol.pointee.defval))\"")
            }
        }
    }
    
    @MainActor
    func renderGraph() -> Data {
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

        try? stderr.write(contentsOf: beginMarker)
        // PSinputscale = 72.0  // TODO: set as for -s CLI flag?
        gvLayout(Graph.graphContext, graph, "dot") // TODO: set as for -K CLI flag?
        gvRenderData(Graph.graphContext, graph, format, &renderedData, &renderedLength)
        try? stderr.write(contentsOf: endMarker)

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
    
    @MainActor
    func zoomIn() {
        switch nsView {
        case let nsView as PDFView:
            nsView.zoomIn(self)
        case let nsView as WKWebView:
            nsView.pageZoom *= 1.1
        default:
            break
        }
    }
    
    @MainActor
    func zoomOut() {
        switch nsView {
        case let nsView as PDFView:
            nsView.zoomOut(self)
        case let nsView as WKWebView:
            nsView.pageZoom /= 1.1
        default:
            break
        }
    }
    
    @MainActor
    func zoomToActual() {
        switch nsView {
        case let nsView as PDFView:
            nsView.scaleFactor = 1.0
        case let nsView as WKWebView:
            nsView.pageZoom = 1.0
        default:
            break
        }
    }
    
    @MainActor
    func zoomToFit() {
        switch nsView {
        case let nsView as PDFView:
            nsView.scaleFactor = nsView.scaleFactorForSizeToFit
        case let nsView as WKWebView:
            // a futile attempt at guessing the scale to fit svg into frame
            //            var width = view frame width / svg view width
            //            var height = view frame height / svg view height
            //            var scale = min(width, height) // but this is too big!
            //            svgView.pageZoom = scale
            nsView.pageZoom = 2.0 // just guess for now, cannot find a way to scale svg to view size
        default:
            break
        }
    }
}
