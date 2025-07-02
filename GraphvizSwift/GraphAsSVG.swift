//
//  GraphAsSVG.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/29/25.
//

import UniformTypeIdentifiers
import SwiftUI
import WebKit

struct GraphAsSVG: NSViewRepresentable {
    @Binding var document: GraphvizDocument
    var url: URL!
    @State var graph: Graph!
    @State var nsView: WKWebView!

    //    class Coordinator: NSObject {
    //        var graph: Graph
    //        init(_ graph: Graph) {
    //            self.graph = graph
    //        }
    //    }
    //
    //    func makeCoordinator() -> Coordinator {
    //        Coordinator(document.graph)
    //    }
    
    func makeNSView(context: Context) -> WKWebView {
        // futile attempts to get svg data to autoscale like pdf
        //                    let configuration = WKWebViewConfiguration()
        //                    configuration.defaultWebpagePreferences = WKWebpagePreferences()
        //                    configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        //                    let svgView = WKWebView(frame: .zero, configuration: configuration)
        //                    svgView.autoresizesSubviews = true
        //                    _nsView = svgView
        self.graph = Graph(document: $document)
        self.nsView = WKWebView()
        draw(graph: graph, nsView: nsView)
        return nsView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        //        if context.coordinator.graph.updated {
        //            DispatchQueue.main.async {
        //                print("NSView updated!")
        //                draw(graph: context.coordinator.graph)
        //            }
        //        }
        if graph.updated {
            DispatchQueue.main.async {
                print("NSView updated!")
                draw(graph: graph, nsView: nsView)
            }
        }
    }
    
    func draw(graph: Graph, nsView: WKWebView) {
        let data = graph.renderGraph(utType: .svg)
        nsView.load(
            data,
            mimeType: UTType.svg.preferredMIMEType!,
            characterEncodingName: "UTF-8",
            baseURL: url.deletingLastPathComponent()
        )
    }
    
    //    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
    //        if let graph = coordinator.graph.graph {
    //            let layout = coordinator.graph.layout
    //            Graph.closeGraph(graph: graph, layout: layout)
    //        }
    //        if let observer = coordinator.graph.observer {
    //            LogInterceptor.shared.ignore(observer: observer)
    //        }
    //    }
    
    
    @MainActor
    func zoomIn(_ utType: UTType) {
        nsView.pageZoom *= 2.0.squareRoot()
    }
    
    @MainActor
    func zoomOut(_ utType: UTType) {
        nsView.pageZoom /= 2.0.squareRoot()
    }
    
    @MainActor
    func zoomToActual(_ utType: UTType) {
        nsView.pageZoom = 1.0
    }
    
    @MainActor
    func zoomToFit(_ utType: UTType) {
        // a futile attempt at guessing the scale to fit svg into frame
        //            var width = view frame width / svg view width
        //            var height = view frame height / svg view height
        //            var scale = min(width, height) // but this is too big!
        //            svgView.pageZoom = scale
        nsView.pageZoom = 2.0 // just guess for now, cannot find a way to scale svg to view size
    }
}
