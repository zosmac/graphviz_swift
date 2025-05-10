//
//  ContentView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: GraphvizSwiftDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(GraphvizSwiftDocument()))
}
