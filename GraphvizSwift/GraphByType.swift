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

/// GraphByType displays Graphviz PDF and SVG renders in SwiftUI.
struct GraphByType: NSViewRepresentable {
    @ObservedObject var document: GraphvizDocument
    @Binding var viewType: UTType
    @Binding var zoomScale: CGFloat

    func makeNSView(context: Context) -> NSView {
        print("making a view with frame \(NSView().frame)")
        switch viewType {
        case .svg:
            let webView = WKWebView()
            webView.allowsMagnification = true
            return webView
        case .pdf:
            let pdfView = PDFView()
            pdfView.autoScales = true
            return pdfView
        default:
            return NSView()
        }
    }
        
    func updateNSView(_ nsView: NSView, context: Context) {
        print("viewtype is \(viewType) \(nsView.frame)")
        switch nsView {
        case let nsView as WKWebView:
            if viewType != .svg {
                return
            }
            document.graph.render(text: document.text, viewType: viewType)
            nsView.load(
                document.graph.data,
                mimeType: viewType.preferredMIMEType!,
                characterEncodingName: "UTF-8",
                baseURL: URL(filePath: "")
            )
            if nsView.pageZoom != zoomScale {
                nsView.pageZoom = zoomScale
            }
        case let nsView as PDFView:
            if viewType != .pdf {
                return
            }
            document.graph.render(text: document.text, viewType: viewType)
            nsView.document = PDFDocument(data: document.graph.data)
            if nsView.scaleFactor != zoomScale {
                if zoomScale == 0.0 { // set in GraphvizView to signal "size to fit"
                    zoomScale = nsView.scaleFactorForSizeToFit
                }
                nsView.scaleFactor = zoomScale
            }
        default:
            return
        }
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        print("dismantle view controller called \(nsView)")
        nsView.prepareForReuse()
    }
}
