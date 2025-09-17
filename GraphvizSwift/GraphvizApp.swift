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
    @AppStorage("viewType") var viewType = defaultViewType

    @FocusedValue(\.attributesKind) private var attributesKind
    @FocusedValue(\.attributesRow) private var attributesRow
    @FocusedValue(\.saveViewPresented) private var saveViewPresented
    @FocusedValue(\.saveViewType) private var saveViewType

    @State private var attributesDocViewLaunch = AttributesDocViewLaunch()

    var body: some Scene {
        DocumentGroup(newDocument: { GraphvizDocument() }) {
            GraphvizView(document: $0.document, url: $0.fileURL)
                .environment(attributesDocViewLaunch)
        }
        .commands {
            ToolbarCommands()
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .importExport) {
                SaveViewButton(viewType: (saveViewType?.wrappedValue ?? UTType(filenameExtension: viewType))!)
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

        UtilityWindow("Attributes Documentation", id: "AttributesDocView") {
            AttributesDocView()
                .focusedSceneValue(\.attributesKind, attributesKind)
                .focusedSceneValue(\.attributesRow, attributesRow)
        }
        .defaultPosition(.topTrailing)
        .defaultSize(width: 350, height: 400)

        Settings {
            PreferencesView()
        }
        .defaultPosition(.topLeading)
    }
}
