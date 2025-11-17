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
    @Environment(\.dismiss) private var dismiss

    @Bindable var document: GraphvizDocument
    let url: URL?
    let viewType: String
    let rendering: Data
    let zoomScale: CGFloat
    @Binding var viewScale: CGFloat

    @State private var saveFailed: Bool = false
    @State private var saveError: Error? = nil

    var body: some View {
        switch UTType(filenameExtension: viewType)! {
        case document.docType:
            TextEditor(text: $document.text)
                .autocorrectionDisabled()
                .font(.system(size: textSize*zoomScale, design: .monospaced))
                .onChange(of: document.text) {
                    print("text changed")
                }
        case .canon, .gv, .json:
            if let text = String(data: rendering, encoding: .utf8) {
                ScrollView {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: textSize*zoomScale))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                Text("Render failed: select Messages Button to view error.")
                    .font(Font.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        default:
            if let image = NSImage(data: rendering) {
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
                Text("Render failed: select Messages Button to view error.")
                    .font(Font.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}
