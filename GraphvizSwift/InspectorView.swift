//
//  InspectorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/19/25.
//

import SwiftUI
import WebKit

/// InspectorView displays either the graph's attributes or the files contents
struct InspectorView: View {
    @Binding var inspector: String
    @Binding var document: GraphvizDocument
    @State var kind: Int = AGRAPH
    @State var webView = WKWebView()

    var body: some View {
        if inspector == "attributes" {
            AttributesView(document: $document, kind: $kind, webView: $webView)
        } else {
            EditorView(document: $document)
        }
    }
}
