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
        case let nsView as PDFView:
            nsView.document = PDFDocument(data: data)
        case let nsView as WKWebView:
            nsView.load(
                data,
                mimeType: UTType.svg.preferredMIMEType!,
                characterEncodingName: "UTF-8",
                baseURL: URL(filePath: "http://www.graphviz.org/")
            )
        default:
            break
        }
    }
}
