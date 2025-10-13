//
//  ViewByType.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/23/25.
//

import UniformTypeIdentifiers
import SwiftUI

struct ViewByType: View {
    @AppStorage("textSize") var textSize = defaultTextSize
    
    @Bindable var document: GraphvizDocument
    @Bindable var graph: Graph
    let zoomScale: CGFloat
    @Binding var viewScale: CGFloat

    var body: some View {
        switch UTType(filenameExtension: graph.viewType)! {
        case document.docType:
            TextEditor(text: $document.text)
                .autocorrectionDisabled()
                .font(.system(size: textSize*zoomScale, design: .monospaced))
        case .canon, .gv, .json:
            if let text = String(data: graph.data, encoding: .utf8) {
                ScrollView {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: textSize*zoomScale))
                }
            } else {
                Text("Render of \(graph.viewType) failed\n\(graph.logMessage.message)")
                    .font(Font.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        default:
            if let image = NSImage(data: graph.data) {
                GeometryReader { geometryProxy in
                    ScrollView([.vertical, .horizontal]) {
                        Image(nsImage: image)
                            .resizable()
                            .frame(width: image.size.width*zoomScale, height: image.size.height*zoomScale)
                            .background(.white)
                    }
                }
                .background(.gray.opacity(0.2))
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                }
                action: { viewSize in
                    viewScale = min(viewSize.width/image.size.width, viewSize.height/image.size.height)
                }
            } else {
                Text("Render of \(graph.viewType) failed\n\(graph.logMessage.message)")
                    .font(Font.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
