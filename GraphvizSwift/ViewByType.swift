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
    let zoomScale: CGFloat
    @Binding var viewScale: CGFloat

    var body: some View {
        switch UTType(filenameExtension: document.graph.viewType)! {
        case document.docType:
            TextEditor(text: $document.text)
                .autocorrectionDisabled()
                .font(.system(size: textSize*zoomScale, design: .monospaced))
                .onChange(of: document.text) { oldValue, newValue in
                    print("text changed")
                    document.graph.render(text: newValue)
                }
        case .canon, .gv, .json:
            if let text = String(data: document.graph.data, encoding: .utf8) {
                ScrollView {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: textSize*zoomScale))
                }
            } else {
                Text("Render of \(document.graph.viewType) failed\n\(document.graph.logMessage.message)")
                    .font(Font.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        default:
            if let image = NSImage(data: document.graph.data) {
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
                Text("Render of \(document.graph.viewType) failed\n\(document.graph.logMessage.message)")
                    .font(Font.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
