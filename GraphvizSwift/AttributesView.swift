//
//  AttributesView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/18/25.
//

import SwiftUI

// TODO: set up Kinds as an enum

struct Kinds: View {
    @Binding var kind: Int?

    var body: some View {
        HStack {
            Button("Graph", systemImage: "rectangle.2.swap") {
                kind = AGRAPH
            }
            .foregroundStyle(kind == AGRAPH ? Color.accentColor : .primary)
            Button("Node", systemImage: "oval") {
                kind = AGNODE
            }
            .foregroundStyle(kind == AGNODE ? Color.accentColor : .primary)
            Button("Edge", systemImage: "stroke.line.diagonal") {
                kind = AGEDGE
            }
            .foregroundStyle(kind == AGEDGE ? Color.accentColor : .primary)
        }
    }
}

// AttributesView shows the values of graph, node, and edge attributes of a graph.
struct AttributesView: View {
    @FocusedBinding(\.attributesKind) private var attributesKind
    @FocusedBinding(\.attributesRow) private var attributesRow
    
    @Bindable var graph: Graph
    @Binding var settings: [[String: String]]
    @State private var kind: Int?
    @State private var attributes: [Attribute]?
    @State private var row: Attribute.ID?
    @State private var scrollRow = ScrollPosition(idType: Attribute.ID.self)
    
    var body: some View {
        VStack(spacing: 10) {
            Kinds(kind: $kind)
                .focusedSceneValue(\.attributesKind, $kind)
            if let kind,
               let attributes = graph.attributes?.kinds[kind] {
                ScrollViewReader { proxy in
                    Table(attributes, selection: $row) {
                        TableColumn("Attribute", value: \.name)
                        TableColumn("Value") { attribute in
                            if attribute.options == nil {
                                ValueView(settings: $settings, kind: kind, attribute: attribute, label: attribute.defaultValue ?? "", value: attribute.value) //, isDisabled: !attribute.value.isEmpty)
                            } else {
                                OptionView(settings: $settings, kind: kind, attribute: attribute, value: attribute.value)
                            }
                        }
                    }
                    .onChange(of: kind) {
                        if let index = attributes.firstIndex(where: { $0.id == row }) {
                            proxy.scrollTo(attributes[index].id, anchor: .center)
                        } else {
                            proxy.scrollTo(attributes[0].id, anchor: .top)
                        }
                    }
                    .onChange(of: row) {
                        proxy.scrollTo($1, anchor: .center)
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
    @Binding var settings: [[String: String]]
    let kind: Int?
    let attribute: Attribute
    let label: String
    @State var value: String
    //    @State var isDisabled: Bool
    
    var body: some View {
        TextField(label, text: $value)
        //            .disabled(isDisabled)
            .onSubmit {
                if let kind {
                    settings[kind][attribute.name] = value
                }
            }
    }
}

/// OptionView defines a picker for selecting an attribute value from a list of options.
struct OptionView: View {
    @Binding var settings: [[String: String]]
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
            if let kind {
                settings[kind][attribute.name] = value
            }
        }
    }
}
