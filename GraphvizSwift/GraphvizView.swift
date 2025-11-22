//
//  GraphvizView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

/// GraphvizView displays the rendered graph and the attributes and file contents inspectors.
struct GraphvizView: View {
    @Environment(\.openWindow) var openWindow
//    @FocusedValue(\.docPagePosition) private var docPagePosition

    @Binding var document: GraphvizDocument
    let url: URL?

    @State private var viewType = UserDefaults.standard.string(forKey: "viewType") ?? defaultViewType
    @State private var settings = Array(repeating: [String: String](), count: 3)
    @State private var zoomScale: CGFloat = 1.0
    @State private var viewScale: CGFloat = 1.0

    @State private var attributesDocLaunched: Bool = false
    @State private var saveViewPresented: Bool = false
    @State private var inspectorPresented: Bool = false
    @State private var messagePresented: Bool = false

    @State private var rendering = Data()
    @State private var attributes: Attributes?
    @State private var logMessage = LogMessage()

    var body: some View {
        @Bindable var graph = Graph(text: document.text)

        ViewByType(document: $document, viewType: viewType, rendering: $rendering, zoomScale: zoomScale, viewScale: $viewScale)
            .inspector(isPresented: $inspectorPresented) {
                AttributesView(graph: graph, attributes: $attributes, settings: $settings)
                    .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
            }
            .onAppear {
                if !attributesDocLaunched {
                    attributesDocLaunched = true
                    openWindow(id: "AttributesDocView")
                }
            }
            .onChange(of: viewType, initial: true) {
                zoomScale = 1.0
                rendering = graph.render(viewType: viewType, settings: settings)
                logMessage = graph.logMessage
                attributes = graph.attributes
            }
            .onChange(of: settings) {
                rendering = graph.render(viewType: viewType, settings: settings)
                logMessage = graph.logMessage
                attributes = graph.attributes
            }
            .onChange(of: document.text) {
                graph = Graph(text: document.text)
                rendering = graph.render(viewType: viewType, settings: settings)
                logMessage = graph.logMessage
                attributes = graph.attributes
            }
            .focusedSceneValue(\.saveViewPresented, $saveViewPresented)
            .focusedSceneValue(\.saveViewType, $viewType)
            .sheet(isPresented: $saveViewPresented) {
                SaveViewSheet(url: url, viewType: viewType, rendering: rendering)
            }
            .toolbarBackground(Color.accentColor.opacity(0.3))
            .toolbar(id: "GraphvizViewToolbar") {
                ToolbarItem(id: "View Type") {
                    ControlGroup("View Type") {
                        Picker("View Type", selection: $viewType) {
                            ForEach(viewableContentTypes, id: \.self) {
                                Text($0.uppercased()).tag($0)
                            }
                        }
                        .frame(width: 80)
                        SaveViewButton(viewType: viewType)
                    }
                }
                ToolbarItem(id: "Zoom") {
                    ControlGroup("Zoom") {
                        Button("Zoom out", systemImage: "minus.magnifyingglass") { // "arrow.down.right.and.arrow.up.left") {
                            zoomScale /= 2.0.squareRoot()
                        }
                        Button("Actual Size", systemImage: "1.magnifyingglass") { // "arrow.uturn.left") {
                            zoomScale = 1.0
                        }
                        Button("Zoom in", systemImage: "plus.magnifyingglass") { // "arrow.up.left.and.arrow.down.right") {
                            zoomScale *= 2.0.squareRoot()
                        }
                        Button("Zoom to Fit", systemImage: "square.arrowtriangle.4.outward") { // "arrow.up.left.and.down.right.magnifyingglass") { // "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left") {
                            zoomScale = viewScale
                        }
                    }
                }
                ToolbarItem(id: "Message") {
                    Button("Message", systemImage: "exclamationmark.message") {
                        messagePresented = logMessage.message.isEmpty ? false : !messagePresented
                    }
                    .foregroundStyle(logMessage.message.isEmpty ? .secondary : Color.red)
                    .popover(isPresented: $messagePresented, arrowEdge: .trailing) {
                        ScrollView {
                            Text(logMessage.message)
                                .foregroundStyle(Color.accentColor)
                        }
                        .frame(minWidth: 200)
                        .defaultScrollAnchor(.topLeading)
                    }
                }
                ToolbarItem(id: "Attributes") {
                    Button("Attributes", systemImage: "sidebar.trailing") {
                        inspectorPresented.toggle()
                    }
                }
            }
    }
}
