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
        VStack {
            HStack {
                Button("Submit") {
                    print("Submit \(String(describing: document.text))")
                }
                Button("Save") {
                    print("Save \(String(describing: document.text))")
                }
                Button("Cancel") {
                    print("Cancel \(String(describing: document.text))")
                }
            }
            TextEditor(text: $document.text)
                .monospaced()
        }
    }
}
