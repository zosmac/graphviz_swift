//
//  AttributesView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/18/25.
//

import SwiftUI

// TODO: set up Kinds as an enum

struct Kinds: View {
    @Bindable var document: GraphvizDocument
    @Binding var kind: Int
    @Binding var attributes: [Attribute]?
    
    var body: some View {
        HStack {
            Button("Graph", systemImage: "rectangle.2.swap") {
                kind = AGRAPH
                attributes = document.graph.attributes?.kinds[kind]
            }
            .foregroundColor(kind == AGRAPH ? .accentColor : .primary)
            Button("Node", systemImage: "oval") {
                kind = AGNODE
                attributes = document.graph.attributes?.kinds[kind]
            }
            .foregroundColor(kind == AGNODE ? .accentColor : .primary)
            Button("Edge", systemImage: "stroke.line.diagonal") {
                kind = AGEDGE
                attributes = document.graph.attributes?.kinds[kind]
            }
            .foregroundColor(kind == AGEDGE ? .accentColor : .primary)
        }
    }
}

// AttributesView shows the values of graph, node, and edge attributes of a graph.
struct AttributesView: View {
    @FocusedBinding(\.attributesKind) private var attributesKind
    @FocusedBinding(\.attributesRow) private var attributesRow
    
    @Bindable var document: GraphvizDocument
    @State private var kind: Int = AGRAPH
    @State private var attributes: [Attribute]?
    @State private var row: Attribute.ID?
    @State private var scrollRow = ScrollPosition(idType: Attribute.ID.self)
    
    var body: some View {
        VStack(spacing: 10) {
            Kinds(document: document, kind: $kind, attributes: $attributes)
                .focusedSceneValue(\.attributesKind, $kind)
            if let attributes {
                ScrollViewReader { proxy in
                    Table(attributes, selection: $row) {
                        TableColumn("Attribute", value: \.name)
                        TableColumn("Value") { attribute in
                            if attribute.options == nil {
                                ValueView(document: document, kind: kind, attribute: attribute, label: attribute.defaultValue ?? "", value: attribute.value) //, isDisabled: !attribute.value.isEmpty)
                            } else {
                                OptionView(document: document, kind: kind, attribute: attribute, value: attribute.value)
                            }
                        }
                    }
                    .onChange(of: kind) {
                        print("onChange of kind: \($0) -> \($1)")
                        if let index = attributes.firstIndex(where: { $0.id == row }) {
                            proxy.scrollTo(attributes[index].id, anchor: .top)
                            print("row: \(index)")
                        } else {
                            proxy.scrollTo(attributes[0].id, anchor: .top)
                        }
                    }
                    .onChange(of: row) {
                        proxy.scrollTo($1, anchor: .top)
                    }
                    .focusedSceneValue(\.attributesRow, $row)
                }
            } else {
                Spacer() // pushes Kinds up to top
            }
        }
    }
}

/// ValueView defines a text field for entering an attribute value.
struct ValueView: View {
    @Bindable var document: GraphvizDocument
    let kind: Int?
    let attribute: Attribute
    let label: String
    @State var value: String
    //    @State var isDisabled: Bool
    
    var body: some View {
        TextField(label, text: $value)
        //            .disabled(isDisabled)
            .onSubmit {
                document.graph.changeAttribute(kind: kind, name: attribute.name, value: value)
            }
    }
}

/// OptionView defines a picker for selecting an attribute value from a list of options.
struct OptionView: View {
    @Bindable var document: GraphvizDocument
    let kind: Int?
    let attribute: Attribute
    @State var value: String
    
    var body: some View {
        Picker(attribute.name, selection: $value) {
            ForEach(attribute.options!, id: \.self) {
                Text($0).tag($0)
            }
        }
        .labelsHidden()
        .onChange(of: value) {
            document.graph.changeAttribute(kind: kind, name: attribute.name, value: value)
        }
    }
}
