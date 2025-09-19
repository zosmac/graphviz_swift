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
    @Environment(AttributesDocViewLaunch.self) var attributesDocViewLaunch
    
    @Bindable var document: GraphvizDocument
    let url: URL?

//    @State private var kind: Int?
//    @State private var row: Attribute.ID?
    @State private var zoomScale: CGFloat = 1.0
    @State private var viewScale: CGFloat = 1.0
    @State private var saveViewPresented: Bool = false
    @State private var inspectorPresented: Bool = false
    @State private var messagePresented: Bool = false
    
    var body: some View {
        ViewByType(document: document, zoomScale: zoomScale, viewScale: $viewScale)
        .inspector(isPresented: $inspectorPresented) {
            AttributesView(document: document) // , kind: $kind, row: $row)
                .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
        }
        .focusedSceneValue(\.saveViewPresented, $saveViewPresented)
        .focusedSceneValue(\.saveViewType, $document.graph.viewType)
        .sheet(isPresented: $saveViewPresented) {
            SaveViewSheet(url: url, graph: document.graph)
        }
        .onAppear {
            if attributesDocViewLaunch.firstTime {
                openWindow(id: "AttributesDocView")
            }
            attributesDocViewLaunch.firstTime = false
        }
        .toolbar(id: "GraphvizViewToolbar") {
            ToolbarItem(id: "View Type") {
                ControlGroup("View Type") {
                    Picker("View Type", selection: $document.graph.viewType) {
                        ForEach(viewableContentTypes, id: \.self) {
                            Text($0.uppercased()).tag($0)
                        }
                    }
                    .frame(width: 80)
                    .onChange(of: document.graph.viewType) {
                        document.graph.render(text: document.text)
                    }
                    SaveViewButton(viewType: document.graph.viewType)
                        .focusedSceneValue(\.saveViewType, $document.graph.viewType)
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
                    messagePresented = document.graph.logMessage.message.isEmpty ? false : !messagePresented
                }
                .foregroundColor(document.graph.logMessage.message.isEmpty ? .primary : .red)
                .popover(isPresented: $messagePresented, arrowEdge: .trailing) {
                    ScrollView {
                        Text(document.graph.logMessage.message)
                            .foregroundStyle(.red)
                    }
                    .frame(minWidth: 200)
                    .defaultScrollAnchor(.topLeading)
                }
            }
            ToolbarItem(id: "Attributes") {
                Button("Attributes", systemImage: "list.dash") {
                    inspectorPresented.toggle()
                }
            }
        }
    }
}
