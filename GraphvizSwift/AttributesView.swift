//
//  AttributesView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/18/25.
//

import SwiftUI

extension FocusedValues {
    @Entry var attributesKind: Binding<AttributesByKind.ID>?
    @Entry var attributesRow: Binding<Attribute.ID?>?
}

// AttributesView shows the values of graph, node, and edge attributes of a graph.
struct AttributesView: View {
    @FocusedValue(\.attributesKind) private var attributesKind
    @FocusedValue(\.attributesRow) private var attributesRow
    @ObservedObject var document: GraphvizDocument
    @State private var kind: AttributesByKind.ID = AGRAPH
    @State private var row: Attribute.ID?
    
    var body: some View {
        VStack(spacing: 10) {
            Picker("Kinds", selection: $kind) {
                ForEach(parsedAttributes.kinds, id: \.self) {
                    Text($0.label).tag($0.kind)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.top, 5.0)
            let table = document.graph.attributes.attributesByKind[kind]
            ScrollViewReader { proxy in
                Table(table, selection: $row) {
                    TableColumn("Attribute", value: \.name)
                    TableColumn("Value") { attribute in
                        if let options = attribute.options {
                            OptionView(document: document, kind: kind, name: attribute.name, options: options, value: attribute.value)
                        } else {
                            ValueView(document: document, kind: kind, name: attribute.name, label: attribute.defaultValue ?? "", value: attribute.value, enabled: attribute.value.isEmpty)
                        }
                    }
                }
                .onChange(of: kind) { // table kind changed
                    attributesKind?.wrappedValue = kind
                    if let index = table.firstIndex(where: { $0.id == row }) {
                        // row in this table kind previously selected, scroll to it
                        // (direct scroll using row itself doesn't work)
                        attributesRow?.wrappedValue = row!
                        proxy.scrollTo(table[index].id, anchor: .center)
                    } else if let toprow = table.first {
                        // scroll to top
                        attributesRow?.wrappedValue = nil
                        proxy.scrollTo(toprow.id, anchor: .top)
                    }
                }
                .onChange(of: row) {
                    attributesKind?.wrappedValue = kind
                    attributesRow?.wrappedValue = row!
                }
            }
        }
    }
}

/// OptionView defines a picker for selecting an attribute value from a list of options.
struct OptionView: View {
    @ObservedObject var document: GraphvizDocument
    var kind: Int
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
    @ObservedObject var document: GraphvizDocument
    var kind: Int
    var name: String
    var label: String
    @State var value: String
    @State var enabled: Bool

    var body: some View {
        TextField(label, text: $value)
            .disabled(!enabled)
            .onSubmit {
                document.graph.changeAttribute(kind: kind, name: name, value: value)
            }
    }
}
