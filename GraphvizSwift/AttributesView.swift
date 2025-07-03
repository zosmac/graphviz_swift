//
//  AttributesView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/18/25.
//

import SwiftUI
import PDFKit
import WebKit

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

struct AttributesView: View {
    @Binding var document: GraphvizDocument
    @Bindable var graph: Graph
    @Binding var kind: Int
    @State var row: Attribute.ID?

    var body: some View {
        VStack {
            Picker("Kinds", selection: $kind) {
                ForEach(headings) { heading in
                    Text(heading.heading).tag(heading.kind)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.top, 5.0)
            Spacer()
            VStack {
                let table = graph.attributes.tables[kind]
                ScrollViewReader { proxy in
                    Table(table, selection: $row) {
                        TableColumn("Attribute", value: \.name)
                        TableColumn("Value") { (attribute: Attribute) in
                            @Bindable var attribute = attribute
                            if let options = attribute.options {
                                Picker(attribute.name, selection: $attribute.value) {
                                    ForEach(options, id:\.self) { option in
                                        Text(option)
                                    }
                                }
                                .labelsHidden()
                                .onChange(of: attribute.value) {
                                    graph.changeAttribute(kind: kind, name: attribute.name, value: attribute.value)
                                }
                            } else {
                                TextField(attribute.defaultValue ?? "", text: $attribute.value)
                                    .onSubmit {
                                        graph.changeAttribute(kind: kind, name: attribute.name, value: attribute.value)
                                    }
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
                }
                AttributesDocView(graph: $graph, kind: $kind, row: $row)
                    .frame(height: 200.0)
            }
        }
    }
}
