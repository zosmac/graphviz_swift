//
//  AttributesView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/18/25.
//

import SwiftUI

// TODO: set up Kinds as an enum

struct Kinds: View {
    //    @FocusedValue(\.attributesKind) private var attributesKind
    //
    @Bindable var document: GraphvizDocument
    @Binding var kind: Int?
    @Binding var attributes: [Attribute]?
    @Binding var row: Attribute.ID?
    
    var body: some View {
        HStack {
            Button("Graph", systemImage: "rectangle.2.swap") {
                kind = AGRAPH
                attributes = (document.graph.attributes?.kinds[kind!])
            }
            .foregroundColor(kind == AGRAPH ? .accentColor : .primary)
            Button("Node", systemImage: "oval") {
                kind = AGNODE
                attributes = (document.graph.attributes?.kinds[kind!])
            }
            .foregroundColor(kind == AGNODE ? .accentColor : .primary)
            Button("Edge", systemImage: "stroke.line.diagonal") {
                kind = AGEDGE
                attributes = (document.graph.attributes?.kinds[kind!])
            }
            .foregroundColor(kind == AGEDGE ? .accentColor : .primary)
        }
    }
}

// AttributesView shows the values of graph, node, and edge attributes of a graph.
struct AttributesView: View {
    @Bindable var document: GraphvizDocument
    @State private var kind: Int?
    @State private var attributes: [Attribute]?
    @State private var row: Attribute.ID?
    
    var body: some View {
        VStack(spacing: 10) {
            Kinds(document: document, kind: $kind, attributes: $attributes, row: $row)
                .focusedSceneValue(\.attributesKind, $attributes)
            if let attributes = attributes {
                Table(attributes, selection: $row) {
                    TableColumn("Attribute", value: \.name)
                    TableColumn("Value") { attribute in
                        if let options = attribute.options {
                            OptionView(document: document, kind:
                                        $kind, name: attribute.name, options: options, value: attribute.value)
                        } else {
                            ValueView(document: document, kind: $kind, name: attribute.name, label: attribute.defaultValue ?? "", value: attribute.value) //, isDisabled: !attribute.value.isEmpty)
                        }
                    }
                }
                .focusedSceneValue(\.attributesRow, $row)
            } else {
                Spacer() // pushes Kinds up to top
            }
        }
    }
}

/// OptionView defines a picker for selecting an attribute value from a list of options.
struct OptionView: View {
    @Bindable var document: GraphvizDocument
    @Binding var kind: Int?
    var name: String
    var options: [String]
    @State var value: String
    
    var body: some View {
        Picker(name, selection: $value) {
            ForEach(options, id: \.self) {
                Text($0).tag($0)
            }
        }
        .labelsHidden()
        .onChange(of: value) {
            document.graph.changeAttribute(kind: kind, name: name, value: value)
        }
    }
}

/// ValueView defines a text field for entering an attribute value.
struct ValueView: View {
    @Bindable var document: GraphvizDocument
    @Binding var kind: Int?
    var name: String
    var label: String
    @State var value: String
//    @State var isDisabled: Bool
    
    var body: some View {
        TextField(label, text: $value)
//            .disabled(isDisabled)
            .onSubmit {
                document.graph.changeAttribute(kind: kind, name: name, value: value)
            }
    }
}
