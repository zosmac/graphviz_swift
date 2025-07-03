//
//  GraphAsPDF.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI
import PDFKit

struct GraphAsPDF: NSViewControllerRepresentable {
    @Observable class Coordinator: NSViewController {
        init() {
            super.init(nibName: nil, bundle: nil)
            view = PDFView()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            print("coder init called for GraphAsPDF.Controller")
            fatalError("init(coder:) has not been implemented")
        }
    }

    @Binding var document: GraphvizDocument
    var url: URL!
    @Bindable var graph: Graph
    @Bindable var coordinator: Coordinator

    init(document: Binding<GraphvizDocument>, graph: Bindable<Graph>, url: URL) {
        _document = document
        _graph = graph
        coordinator = Coordinator()
        self.url = url
    }
    
    func makeCoordinator() -> Coordinator {
        return coordinator
    }
    
    func makeNSViewController(context: Context) -> Coordinator {
        let nsView = context.coordinator.view as! PDFView
        nsView.autoScales = true
        draw(graph: graph, nsView: nsView)
        return context.coordinator
    }

    func updateNSViewController(_ nsViewController: Coordinator, context: Context) {
        if graph.updated {
            print("PDF View of graph updated!")
            let nsView = nsViewController.view as! PDFView
            draw(graph: graph, nsView: nsView)
        }
    }

    func draw(graph: Graph, nsView: PDFView) {
        let data = graph.renderGraph(utType: .pdf)
        nsView.document = PDFDocument(data: data)
    }
}
