//
//  GraphvizSwiftApp.swift
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

/// GraphvizSwiftApp creates the graphviz document views and attributes documentation window.
@main struct GraphvizSwiftApp: App {
    @AppStorage("viewType") private var viewType = defaultViewType
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow
    @FocusedBinding(\.saveViewType) private var saveViewType

    private let attributesDocPage = AttributesDocPage()
    @State private var attributesDocLaunched = false

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
            CommandGroup(after: .singleWindowList) {
                 Section {
                     WindowVisibilityToggle(windowID: "AttributesDocView")
                 }
             }
            CommandGroup(replacing: .help) {
                Button("GraphvizSwift Help") {
                    if let url = Bundle.main.url(forResource: "README", withExtension: "html") ?? URL(string: "https://github.com/zosmac/graphviz_swift/#welcome-to-graphvizswift") {
                        NSWorkspace.shared.open(url)
                    }
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
            VStack(spacing: 0.0) {
                HStack {
                    Button("Overview", systemImage: "house") {
                        attributesDocPage.loadHome()
                    }
                    .glassEffect(.regular.tint(Color.accentColor.opacity(0.3)))
                    Spacer()
                }
                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                .background(Rectangle().fill(Color.accentColor.opacity(0.3)))
                WebView(attributesDocPage.page)
            }
        }
        .commandsRemoved()
        .defaultSize(width: 350, height: 500)
        .defaultPosition(.topTrailing)

        Settings {
            SettingsView()
        }
        .defaultSize(width: 300, height: 200)
        .defaultPosition(.topLeading)
    }
}
