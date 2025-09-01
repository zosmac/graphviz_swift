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

/// GraphvizApp creates the graphviz document views and attributes documentation window.
@main struct GraphvizApp: App {
    @State private var openSidebarCount = OpenSidebarCount(0)
    @FocusedValue(\.attributesKind) private var attributesKind
    @FocusedValue(\.attributesRow) private var attributesRow
    @FocusedValue(\.saveViewShow) private var saveViewShow
    @FocusedValue(\.saveViewType) private var saveViewType
    @State private var kind: AttributesByKind.ID = AGRAPH
    @State private var row: Attribute.ID?

    var body: some Scene {
        DocumentGroup(newDocument: { GraphvizDocument() }) {
            GraphvizView(document: $0.document, url: $0.fileURL, kind: $kind, row: $row)
                .environment(openSidebarCount)
                .focusedSceneValue(\.attributesKind, $kind)
                .focusedSceneValue(\.attributesRow, $row)
        }
        .commands {
            SidebarCommands()
            ToolbarCommands()
            CommandGroup(replacing: .newItem) {}
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
        
        Window("Attributes", id: "AttributesDocView") {
            AttributesDocView()
                .focusedSceneValue(\.attributesKind, $kind)
                .focusedSceneValue(\.attributesRow, $row)
        }
//        .restorationBehavior(.disabled)
        .defaultPosition(.topTrailing)
        .defaultSize(width: 350, height: 400)
    }
}
