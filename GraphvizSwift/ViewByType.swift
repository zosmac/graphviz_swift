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
    @AppStorage("textSize") var textSize = defaultTextSize
    
    @Bindable var document: GraphvizDocument
    @Binding var viewType: UTType
    @Binding var zoomScale: CGFloat
    @Binding var viewScale: CGFloat
    
    var body: some View {
        switch viewType {
        case document.docType:
            TextEditor(text: $document.text)
                .autocorrectionDisabled()
                .font(.system(size: textSize*zoomScale, design: .monospaced))
                .onChange(of: document.text) { oldValue, newValue in
                    print("text changed")
                    document.graph.render(text: newValue, viewType: viewType)
                }
        case .canon, .gv, .dot, .json:
            if let text = String(data: document.graph.data, encoding: .utf8) {
                ScrollView {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: textSize*zoomScale))
                }
            } else {
                Text("Render of text type \(viewType.identifier) failed")
                    .font(Font.title)
            }
        default:
            if let image = NSImage(data: document.graph.data) {
                GeometryReader { geometryProxy in
                    ScrollView([.vertical, .horizontal]) {
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: image.size.width*zoomScale, height: image.size.height*zoomScale)
                    }
                }
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                }
                action: { viewSize in
                    viewScale = min(viewSize.width/image.size.width, viewSize.height/image.size.height)
                }
            } else {
                Text("Render of image type \(viewType.identifier) unsupported")
                    .font(Font.title)
            }
        }
    }
}
