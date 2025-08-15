//
//  AttributesView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/18/25.
//

import SwiftUI

/// A heading for the AttributesView for each kind of attribute: graph, node, edge.
struct heading: Identifiable, Hashable {
    var id: String { heading }
    var heading: String
    var kind: Int
    init(_ heading: String, _ kind: Int) {
        self.heading = heading
        self.kind = kind
    }
    func hash(into hasher: inout Hasher) { // Hashable
        hasher.combine(heading)
    }
}

let headings: [heading] = [heading("􁁀 Graph", AGRAPH), heading("􀲞 Node", AGNODE), heading("􀫰 Edge", AGEDGE)]

// AttributesView shows the values of graph, node, and edge attributes of a graph.
struct AttributesView: View {
    @Environment(KindRow.self) private var kindRow: KindRow
    @Binding var graph: Graph
    @State private var kind: Int = 0
    @State private var row: Attribute.ID?
    
    var body: some View {
        VStack(spacing: 10) {
            Picker("Kinds", selection: $kind) {
                ForEach(headings) {
                    Text($0.heading).tag($0.kind)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.top, 5.0)
            let table = graph.attributes.tables[kind]
            ScrollViewReader { proxy in
                Table(table, selection: $row) {
                    TableColumn("Attribute", value: \.name)
                    TableColumn("Value") { (attribute: Attribute) in
                        if let options = attribute.options {
                            OptionView(graph: $graph, kind: kind, name: attribute.name, options: options, value: attribute.value)
                        } else {
                            ValueView(graph: $graph, kind: kind, name: attribute.name, label: attribute.defaultValue ?? "", value: attribute.value, enabled: attribute.value.isEmpty)
                        }
                    }
                }
                .onChange(of: kind) { // table kind changed
                    if let index = table.firstIndex(where: { $0.id == row }) {
                        // row in this table kind previously selected, scroll to it
                        // (direct scroll using row itself doesn't work)
                        proxy.scrollTo(table[index].id, anchor: .top)
                    } else if let toprow = table.first {
                        // scroll to top
                        proxy.scrollTo(toprow.id)
                    }
                }
                .onChange(of: row) {
                    kindRow.kind = kind
                    kindRow.row = row
                }
            }
        }
    }
}

/// OptionView defines a picker for selecting an attribute value from a list of options.
struct OptionView: View {
    @Binding var graph: Graph
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
            graph.changeAttribute(kind: kind, name: name, value: value)
        }
    }
}

/// ValueView defines a text field for entering an attribute value.
struct ValueView: View {
    @Binding var graph: Graph
    var kind: Int
    var name: String
    var label: String
    @State var value: String
    @State var enabled: Bool

    var body: some View {
        TextField(label, text: $value)
            .disabled(!enabled)
            .onSubmit {
                enabled = false
                graph.changeAttribute(kind: kind, name: name, value: value)
            }
    }
}
