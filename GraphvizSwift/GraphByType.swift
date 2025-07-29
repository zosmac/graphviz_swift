//
//  GraphByType.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI
import PDFKit
import WebKit

struct GraphByType: NSViewRepresentable {
    var graph: Graph
    var utType: UTType

    typealias Coordinator = Graph
    func makeCoordinator() -> Coordinator {
        return graph
    }

    func makeNSView(context: Context) -> NSView {
        var nsView: NSView
        switch utType {
        case UTType.svg:
            let view = WKWebView()
            nsView = view
        case UTType.pdf:
            let view = PDFView()
            view.autoScales = true
            nsView = view
        default:
            nsView = NSView()
        }
        graph.renderGraph(nsView: nsView)
        return nsView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if graph.updated {
            print("View of graph updated!")
            graph.renderGraph(nsView: nsView)
        }
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        print("dismantle view controller called")
        let graph = coordinator
        graph.closeGraph()
    }
}


// seems like overkill, but retained in case
//struct GraphRepresentable: NSViewControllerRepresentable {
//    var graph: Graph
//    var utType: UTType
//    
//    final class Coordinator: NSViewController {
//        var graph: Graph
//
//        init(graph: Graph) {
//            self.graph = graph
//            super.init(nibName: nil, bundle: nil)
//        }
//
//        override func loadView() {
//            super.loadView()
//        }
//
//        override func viewDidLoad() {
//            super.viewDidLoad()
//        }
//        
//        @available(*, unavailable)
//        required init?(coder: NSCoder) {
//            print("coder init called for GraphAsPDF.Controller")
//            fatalError("init(coder:) has not been implemented")
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(graph: graph)
//    }
//    
//    func makeNSViewController(context: Context) -> NSViewController {
//        let nsViewController = context.coordinator
//        var nsView: NSView
//        switch utType {
//        case UTType.svg:
//            let view = WKWebView()
//            nsView = view
//        case UTType.pdf:
//            let view = PDFView()
//            view.autoScales = true
//            nsView = view
//        default:
//            nsView = NSView()
//        }
//        graph.renderGraph(nsView: nsView)
//        
//        nsViewController.view = nsView
//        return nsViewController
//    }
//    
//    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
//        if graph.updated {
//            print("PDF View of graph updated!")
//            graph.renderGraph(nsView: nsViewController.view)
//        }
//    }
//    
//    static func dismantleNSViewController(_ nsViewController: NSViewController, coordinator: Coordinator) {
//        print("dismantle view controller called")
//        let graph = coordinator.graph
//        graph.closeGraph()
//    }
//}
