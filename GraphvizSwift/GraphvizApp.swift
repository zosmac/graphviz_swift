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
    @Entry var saveViewPresented: Binding<Bool>?
    @Entry var saveViewType: Binding<String>?
}

/// GraphvizApp creates the graphviz document views and attributes documentation window.
@main struct GraphvizApp: App {
    @AppStorage("viewType") var viewType = defaultViewType
    @Environment(\.openWindow) var openWindow
    @FocusedBinding(\.saveViewType) private var saveViewType

    private let attributesDocPage = AttributesDocPage()
    @State private var attributesDocLaunched: Bool = false

    var body: some Scene {
        DocumentGroup(newDocument: GraphvizDocument()) {
            GraphvizView(document: $0.$document)
                .environment(attributesDocPage)
                .onAppear {
                    if !attributesDocLaunched {
                        attributesDocLaunched = true
                        openWindow(id: "AttributesDocView")
                    }
                }
        }
        .commands {
            ToolbarCommands()
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .importExport) {
                SaveViewButton(viewType: (saveViewType ?? viewType))
            }
            CommandGroup(replacing: .help) {
                Button("GraphvizSwift Help") {
                    if let url = Bundle.main.url(forResource: "README", withExtension: "html") {
                        NSWorkspace.shared.open(url)
                    }
//                    if let url = URL(string: "https://github.com/zosmac/graphviz_swift/#welcome-to-graphvizswift") {
//                        NSWorkspace.shared.open(url)
//                    }
                }
                Button("Graphviz Help") {
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
