//
//  ViewByType.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/23/25.
//

import UniformTypeIdentifiers
import SwiftUI
import PDFKit
import WebKit

struct ViewByType: View {
    @ObservedObject var document: GraphvizDocument
    @Binding var viewType: UTType
    @Binding var zoomScale: CGFloat
    
    var body: some View {
        switch viewType {
        case document.docType:
            TextEditor(text: $document.text)
                .monospaced()
                .font(.system(size: 12*zoomScale)) // TODO: get an accessible default from system?
                .onChange(of: document.text) {
                    _ = document.graph.render(text: document.text, viewType: viewType)
                }
//        case .pdf: // use explicit cases for GraphByType to force recreating when viewType changes
//            GraphByType(document: document, viewType: $viewType, zoomScale: $zoomScale)
//        case .svg: // use explicit cases for GraphByType to force recreating when viewType changes
//            GraphByType(document: document, viewType: $viewType, zoomScale: $zoomScale)
        case .canon, .gv, .dot, .json:
            if let text = String(data: document.graph.render(text: document.text, viewType: viewType), encoding: .utf8) {
                ScrollView {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12*zoomScale)) // TODO: get an accessible default from system?
                }
            } else {
                Text("Render of text type \(viewType.identifier) failed")
                    .font(Font.largeTitle)
            }
        default:
            if let image = NSImage(data: document.graph.render(text: document.text, viewType: viewType)) {
                GeometryReader { geometryProxy in
                    let size = geometryProxy.frame(in: .named("Image View")).size
                    let zoomScale = zoomScale != 0.0 ? zoomScale :
                        min(size.width/image.size.width, size.height/image.size.height)
                    ScrollView([.vertical, .horizontal]) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit() // Scale the image to fit its container
                            .frame(width: image.size.width*zoomScale, height: image.size.height*zoomScale)
                    }
                }
            } else {
                Text("Render of image type \(viewType.identifier) failed")
                    .font(Font.largeTitle)
            }
        }
    }
}
