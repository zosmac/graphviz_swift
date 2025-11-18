//
//  GraphvizApp.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI
import WebKit

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
    @FocusedBinding(\.saveViewType) private var saveViewType

    @State private var attributesDocViewLaunch = AttributesDocViewLaunch()
    @State private var attributesDocPage = AttributesDocPage()
    @State private var docPagePosition = ScrollPosition()

    var body: some Scene {
        DocumentGroup(newDocument: { GraphvizDocument() }) {
            GraphvizView(document: $0.document, url: $0.fileURL, docPagePosition: $docPagePosition)
                .environment(attributesDocViewLaunch)
                .environment(attributesDocPage)
        }
        .commands {
            ToolbarCommands()
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .importExport) {
                SaveViewButton(viewType: (saveViewType ?? viewType))
            }
            CommandGroup(replacing: .help) {
                Button("GraphvizSwift Help") {
                    if let url = Bundle.main.url(forResource: "Help", withExtension: "html") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .defaultSize(width: 800, height: 600)
        .defaultPosition(.top)

        UtilityWindow("Attributes Documentation", id: "AttributesDocView") {
            //            AttributesDocView()
            //                .focusedSceneValue(\.attributesKind, attributesKind)
            //                .focusedSceneValue(\.attributesRow, attributesRow)
            WebView(attributesDocPage.page)
                .webViewScrollPosition($docPagePosition)
        }
        .defaultPosition(.trailing)
        .defaultSize(width: 350, height: 400)

        Settings {
            SettingsView()
                .frame(minWidth: 280, maxWidth: 280, minHeight: 150, maxHeight: 150)
        }
        .defaultPosition(.topLeading)
    }
}
