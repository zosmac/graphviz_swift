//
//  GraphView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI
import PDFKit
import WebKit

struct GraphView: NSViewRepresentable {
    @Binding var document: GraphvizDocument
    var url: URL!

    class Coordinator: NSObject {
        var parent: GraphView
        init(_ parent: GraphView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSView {
        draw()
        return document.graph.nsView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if document.graph.updated {
            DispatchQueue.main.async {
                print("NSView updated!")
                draw()
            }
        }
    }

    func draw() {
        let data = document.graph.renderGraph()
        switch document.graph.nsView {
        case let pdfView as PDFView:
            pdfView.document = PDFDocument(data: data)
        case let svgView as WKWebView:
            svgView.load(
                data,
                mimeType: UTType.svg.preferredMIMEType!,
                characterEncodingName: "UTF-8",
                baseURL: url.deletingLastPathComponent()
            )
        default:
            break
        }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let graph = coordinator.parent.document.graph.graph {
            let layout = coordinator.parent.document.graph.layout
            Graph.closeGraph(graph: graph, layout: layout)
        }
        if let observer = coordinator.parent.document.graph.observer {
            LogInterceptor.shared.ignore(observer: observer)
        }
    }
}
