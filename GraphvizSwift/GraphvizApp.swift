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
    @Entry var attributesKind: Binding<Int>?  // by kind: AGRAPH, AGNODE, AGEDGE
    @Entry var docPagePosition: Binding<ScrollPosition>?
    @Entry var saveViewPresented: Binding<Bool>?
    @Entry var saveViewType: Binding<String>?
}

/// GraphvizApp creates the graphviz document views and attributes documentation window.
@main struct GraphvizApp: App {
    @AppStorage("viewType") var viewType = defaultViewType
    @FocusedBinding(\.saveViewType) private var saveViewType
    @FocusedValue(\.docPagePosition) private var docPagePosition

    private let attributesDocPage = AttributesDocPage()
    @State private var position = ScrollPosition()

    var body: some Scene {
        DocumentGroup(newDocument: GraphvizDocument()) {
            GraphvizView(document: $0.$document)
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
        .defaultPosition(UnitPoint(x: 0.4, y: 0.1))

        UtilityWindow("Attributes Documentation", id: "AttributesDocView") {
            WebView(attributesDocPage.page)
                .webViewScrollPosition((docPagePosition ?? $position))
        }
        .defaultSize(width: 350, height: 400)
        .defaultPosition(.topTrailing)

        Settings {
            SettingsView()
        }
        .defaultSize(width: 280, height: 180)
        .defaultPosition(.topLeading)
    }
}
