//
//  GraphvizView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

/// GraphvizView displays the rendered graph and the attributes and file contents inspectors.
struct GraphvizView: View {
    @Environment(\.openWindow) var openWindow

    @Binding var document: GraphvizDocument

    @State private var viewType =
        UserDefaults.standard.string(forKey: "viewType") ?? defaultViewType
    @State private var settings = Array(
        repeating: [String: String](),
        count: kindMax
    )
    @State private var zoomScale: CGFloat = 1.0
    @State private var viewScale: CGFloat = 0.0
    @State private var viewSize: CGFloat = 0.0

    @State private var sizeToFit = true
    @State private var saveViewPresented = false
    @State private var inspectorPresented = false
    @State private var messagePresented = false

    @State private var rendering = Data()
    @State private var attributes: Attributes?
    @State private var logMessages = LogMessages()

    var body: some View {
        @Bindable var graph = Graph(text: document.text)

        ViewByType(
            document: $document,
            viewType: viewType,
            rendering: $rendering,
            zoomScale: $zoomScale,
            viewScale: $viewScale,
            viewSize: $viewSize
        )
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    viewScale = value.magnification - 1.0
                }
                .onEnded { value in
                    zoomScale += (value.magnification - 1.0)
                    viewScale = 0.0
                }
        )
        .inspector(isPresented: $inspectorPresented) {
            AttributesView(attributes: $attributes, settings: $settings)
                .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
        }
        .onChange(of: viewType, initial: true) {
            rendering = graph.render(viewType: viewType, settings: settings)
            logMessages = graph.logMessages
            attributes = graph.attributes
        }
        .onChange(of: settings) {
            rendering = graph.render(viewType: viewType, settings: settings)
            logMessages = graph.logMessages
            attributes = graph.attributes
        }
        .onChange(of: document.text) {
            graph = Graph(text: document.text)
            rendering = graph.render(viewType: viewType, settings: settings)
            logMessages = graph.logMessages
            attributes = graph.attributes
        }
        .focusedSceneValue(\.saveViewPresented, $saveViewPresented)
        .focusedSceneValue(\.saveViewType, $viewType)
        .sheet(isPresented: $saveViewPresented) {
            SaveViewSheet(viewType: viewType, rendering: rendering)
        }
        .toolbarBackground(Color.accentColor.opacity(0.3))
        .toolbar(id: "GraphvizViewToolbar") {
            ToolbarItem(id: "View Type") {
                ControlGroup("View Type") {
                    ViewTypePicker(viewType: $viewType)
                    SaveViewButton(viewType: viewType)
                }
            }
            ToolbarItem(id: "Size To Fit") {
                ControlGroup("Size To Fit") {
                    Button(
                        "Size To Fit",
                        systemImage: sizeToFit
                            ? "arrow.down.backward.and.arrow.up.forward.rectangle"
                            : "1.magnifyingglass"
                    ) {
                        zoomScale = sizeToFit ? viewSize : 1.0
                        sizeToFit.toggle()
                    }
                    // "arrow.uturn.left"
                    // "arrow.up.left.and.down.right.magnifyingglass"
                    // "square.arrowtriangle.4.outward"
                }
            }
            ToolbarItem(id: "Messages") {
                ControlGroup("Messages") {
                    Button("Messages", systemImage: "exclamationmark.message") {
                        messagePresented =
                            logMessages.block.isEmpty
                            ? false : !messagePresented
                    }
                    .foregroundStyle(
                        logMessages.block.isEmpty ? .secondary : Color.red
                    )
                    .popover(
                        isPresented: $messagePresented,
                        arrowEdge: .leading
                    ) {
                        ScrollView {
                            Text(logMessages.block)
                                .foregroundStyle(Color.accentColor)
                        }
                        .frame(minWidth: 200)
                        .defaultScrollAnchor(.topLeading)
                    }
                }
            }
            ToolbarItem(id: "Attributes") {
                ControlGroup("Attributes") {
                    Button("Attributes", systemImage: "sidebar.trailing") {
                        inspectorPresented.toggle()
                    }
                }
            }
        }
    }
}
