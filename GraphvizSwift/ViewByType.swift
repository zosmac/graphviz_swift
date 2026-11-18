//
//  ViewByType.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/23/25.
//

import SwiftUI
import UniformTypeIdentifiers
import WebKit

struct ViewByType: View {
    @AppStorage("textSize") var textSize = defaultTextSize
    @Environment(\.documentConfiguration) private var configuration:
        DocumentConfiguration?

    @Binding var document: GraphvizDocument
    let viewType: String
    @Binding var rendering: Data
    @Binding var zoomScale: CGFloat
    @Binding var viewScale: CGFloat
    @Binding var viewSize: CGFloat

    @State private var saveFailed: Bool = false
    @State private var saveError: Error? = nil
    @State private var page = WebPage()

    var body: some View {
        switch UTType(filenameExtension: viewType)! {
        case document.docType:
            TextEditor(text: $document.text)
                .autocorrectionDisabled()
                .font(
                    .system(
                        size: textSize * (zoomScale + viewScale),
                        design: .monospaced
                    )
                )
                .padding(10)
                .onChange(of: document.text) {
                    print(
                        "text changed for file \(configuration?.fileURL, default: "?")"
                    )
                }
        case .canon, .gv, .json:
            if let text = String(data: rendering, encoding: .utf8) {
                ScrollView {
                    Text(text)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: textSize * (zoomScale + viewScale)))
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                        .padding(10)
                }
            } else {
                ErrorMessageView(
                    message:
                        "Render failed: select Messages Button to view error."
                )
            }
        case .svg:  // large SVG files do not display successfully with NSImage
            if let mimeType = UTType(filenameExtension: viewType)?
                .preferredMIMEType
            {
                WebView(page)
                    .onChange(of: rendering, initial: true) {
                        page.load(
                            rendering,
                            mimeType: mimeType,
                            characterEncoding: .utf8,
                            baseURL: URL(string: "about:blank")!
                        )
                    }
            }
        default:
            if let image = NSImage(data: rendering) {
                GeometryReader { _ in
                    ScrollView([.vertical, .horizontal]) {
                        Image(nsImage: image)
                            .resizable()
                            .frame(
                                width: image.size.width
                                    * (zoomScale + viewScale),
                                height: image.size.height
                                    * (zoomScale + viewScale)
                            )
                            .background(.white)
                    }
                }
                .background(.gray.opacity(0.2))
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: {
                    viewSize = min(
                        $0.width / image.size.width,
                        $0.height / image.size.height
                    )
                }
            } else {
                ErrorMessageView(
                    message:
                        "Render failed: select Messages Button to view error."
                )
            }
        }
    }
}

struct ErrorMessageView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(
                .system(
                    size: 18,
                    weight: .semibold
                )
            )
            .foregroundStyle(.red)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .padding(10)
    }
}
