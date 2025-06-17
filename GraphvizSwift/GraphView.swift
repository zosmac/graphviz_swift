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
        document.graph.renderGraph()
        return document.graph.nsView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}
