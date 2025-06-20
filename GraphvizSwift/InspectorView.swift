//
//  InspectorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/19/25.
//

import SwiftUI
import PDFKit

/// InspectorView displays either the graph's attributes or the files contents
struct InspectorView: View {
    @Binding var inspector: String
    @Binding var document: GraphvizDocument
    @State var kind: Int = 0

    var body: some View {
        if inspector == "attributes" {
            AttributesView(document: $document, kind: $kind)
        } else {
            EditorView(document: $document)
        }
    }
}
