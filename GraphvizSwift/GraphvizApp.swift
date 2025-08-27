//
//  GraphvizApp.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

let GraphvizErrorDomain = "GraphvizErrorDomain"
enum GraphvizError: Int {
    case OK
    case FileParse
}

/// KindRow links the selection of an attribute from a graph, node, edge table and its row, to an anchor in the AttributesDocView.
@Observable final class KindRow {
    var kind: AttributesByKind.ID
    var row: Attribute.ID?
    init(kind: AttributesByKind.ID = AGRAPH, row: Attribute.ID? = nil) {
        self.kind = kind
        self.row = row
    }
}

/// GraphvizApp creates the graphviz document views and attributes documentation window.
@main struct GraphvizApp: App {
    @FocusedValue(\.saveViewShow) private var saveViewShow
    @FocusedValue(\.saveViewType) private var saveViewType
    @State private var kindRow = KindRow() // positions attributes doc window to attribute's doc

    var body: some Scene {
        DocumentGroup(newDocument: { GraphvizDocument() }) {
            GraphvizView(document: $0.document, url: $0.fileURL)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            CommandGroup(replacing: .importExport) {
                SaveViewButton(viewType: saveViewType?.wrappedValue ?? .pdf)
            }
            CommandGroup(replacing: .help) {
                Button("Graphviz Help") {
                    print("Help requested...")
                    if let url = Bundle.main.url(forResource: "graphviz", withExtension: "help") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .defaultSize(width: 800, height: 600)
        .defaultPosition(.top)
        .environment(kindRow)
        
        Window("Attributes", id: "AttributesDocView") {
            AttributesDocView()
        }
        .defaultSize(width: 350, height: 400)
        .defaultPosition(.topLeading)
        .environment(kindRow)
    }
}
