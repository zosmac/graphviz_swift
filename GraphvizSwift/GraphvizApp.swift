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

extension FocusedValues {
    @Entry var docPagePosition: Binding<ScrollPosition>?
    @Entry var saveViewPresented: Binding<Bool>?
    @Entry var saveViewType: Binding<String>?
}

/// GraphvizApp creates the graphviz document views and attributes documentation window.
@main struct GraphvizApp: App {
    @AppStorage("viewType") var viewType = defaultViewType
    @FocusedBinding(\.saveViewType) private var saveViewType
    @FocusedValue(\.docPagePosition) private var docPagePosition
//    @FocusedValue(\.attributesKind) private var attributesKind
//    @FocusedValue(\.attributesRow) private var attributesRow

    private let attributesDocPage = AttributesDocPage()
    @State private var position = ScrollPosition()

    var body: some Scene {
        DocumentGroup(newDocument: GraphvizDocument()) {
            GraphvizView(document: $0.$document, url: $0.fileURL)
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
        .defaultPosition(UnitPoint(x: 0.3, y: 0.1))

        UtilityWindow("Attributes Documentation", id: "AttributesDocView") {
            WebView(attributesDocPage.page)
                .webViewScrollPosition((docPagePosition ?? $position))
//            AttributesDocView()
//                .focusedSceneValue(\.attributesKind, attributesKind)
//                .focusedSceneValue(\.attributesRow, attributesRow)
        }
        .defaultSize(width: 350, height: 400)
        .defaultPosition(UnitPoint(x: 0.95, y: 0.5))

        Settings {
            SettingsView()
                .frame(minWidth: 280, maxWidth: 280, minHeight: 150, maxHeight: 150)
        }
        .defaultPosition(UnitPoint(x: 0.05, y: 0.5))
    }
}
