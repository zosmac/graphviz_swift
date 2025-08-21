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
        let data = document.graph.renderGraph(nsView: nsView)
        switch nsView {
        case let nsView as WKWebView:
            nsView.load(
                data,
                mimeType: viewType.preferredMIMEType!,
                characterEncodingName: "UTF-8",
                baseURL: URL(filePath: "")
            )
            if nsView.pageZoom != zoomScale {
                nsView.pageZoom = zoomScale
            }
        case let nsView as PDFView:
            nsView.document = PDFDocument(data: data)
            if nsView.scaleFactor != zoomScale {
                if zoomScale == 0.0 { // set in GraphvizView to signal "size to fit"
                    zoomScale = nsView.scaleFactorForSizeToFit
                }
                nsView.scaleFactor = zoomScale
            }
        default:
            if let rect = nsView.superview?.frame {
                let width = rect.width * zoomScale
                let height = rect.height * zoomScale
                let x = rect.origin.x + (rect.width - width) / 2
                let y = rect.origin.y + (rect.height - height) / 2
                nsView.frame = CGRect(x: x, y: y, width: width, height: height)
            }
        }
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
//        print("dismantle view controller called")
        nsView.prepareForReuse()
    }
}
