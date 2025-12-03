//
//  AttributesView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/18/25.
//

import SwiftUI

// AttributesView shows the values of graph, node, and edge attributes of a graph.
struct AttributesView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appearsActive) private var appearsActive
    @Environment(AttributesDocPage.self) var attributesDocPage

    @Bindable var graph: Graph
    @Binding var attributes: Attributes?
    @Binding var settings: [[String: String]]

    @State private var kind: Int = AGRAPH
    @State private var row: Attribute.ID?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Graph", systemImage: "rectangle.2.swap") {
                    kind = AGRAPH
                }
                .glassEffect(.regular.tint(tint(kind == AGRAPH)))
                Button("Node", systemImage: "oval") {
                    kind = AGNODE
                }
                .glassEffect(.regular.tint(tint(kind == AGNODE)))
                Button("Edge", systemImage: "stroke.line.diagonal") {
                    kind = AGEDGE
                }
                .glassEffect(.regular.tint(tint(kind == AGEDGE)))
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            .background(Rectangle().fill(Color.accentColor.opacity(0.3)))
            .focusedSceneValue(\.attributesKind, $kind)

            if let attributes = attributes?.kinds[kind] {
                ScrollViewReader { proxy in
                    Table(attributes, selection: $row) {
                        TableColumn("Attribute", value: \.name)
                        TableColumn("Value") { attribute in
                            if attribute.enumeration == nil {
                                ValueView(settings: $settings, kind: kind, attribute: attribute, label: attribute.defaultValue ?? "", value: attribute.value) //, isDisabled: !attribute.value.isEmpty)
                            } else {
                                EnumerationView(settings: $settings, kind: kind, attribute: attribute, value: attribute.value)
                            }
                        }
                    }
                    .onChange(of: appearsActive) {
                        if $1 {
                            if let index = attributes.firstIndex(where: { $0.id == row }) {
                                proxy.scrollTo(attributes[index].id, anchor: .center)
                            } else {
                                proxy.scrollTo(attributes[0].id, anchor: .top)
                            }
                            docPagePosition(attributes: attributes, row: row)
                        }
                    }
                    .onChange(of: kind, initial: true) {
                        if let index = attributes.firstIndex(where: { $0.id == row }) {
                            proxy.scrollTo(attributes[index].id, anchor: .center)
                        } else {
                            proxy.scrollTo(attributes[0].id, anchor: .top)
                        }
                        docPagePosition(attributes: attributes, row: row)
                    }
                    .onChange(of: row) {
                        proxy.scrollTo($1, anchor: .center)
                        docPagePosition(attributes: attributes, row: $1)
                    }
                }
            }
        }
    }

    func tint(_ accent: Bool) -> Color {
        accent ? Color.accentColor.opacity(0.3) : colorScheme == .light ? Color.white : Color.black
    }

    func docPagePosition(attributes: [Attribute], row: Attribute.ID?) -> Void {
        var href = "#"
        if let index = attributes.firstIndex(where: { $0.id == row }) {
            href += attributes[index].name
        }
        do {
            Task { @MainActor in
                do {
                    try await attributesDocPage.page.callJavaScript("window.location.hash='\(href)'")
                } catch { print(error) }
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

/// EnumerationView defines a picker for selecting an attribute value from a list of options.
struct EnumerationView: View {
    @Binding var settings: [[String: String]]
    let kind: Int?
    let attribute: Attribute
    @State var value: String

    var body: some View {
        Picker(attribute.name, selection: $value) {
            ForEach(attribute.enumeration!, id: \.self) {
                Text($0)
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
