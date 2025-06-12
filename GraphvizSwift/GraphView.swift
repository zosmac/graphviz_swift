//
//  GraphView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import SwiftUI
import PDFKit

struct GraphView: NSViewRepresentable {
    @Binding var document: GraphvizDocument
    @Binding var pdfView: PDFView

    func makeNSView(context: Context) -> PDFView {
        pdfView.document = PDFDocument(data: document.graph.renderGraph())
        pdfView.autoScales = true
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
    }
}
