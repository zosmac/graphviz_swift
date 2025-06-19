//
//  EditorView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/15/25.
//

import SwiftUI

struct EditorView: View {
    @Binding var document: GraphvizDocument
    
    var body: some View {
        TextEditor(text: $document.text)
            .monospaced()
    }
}
