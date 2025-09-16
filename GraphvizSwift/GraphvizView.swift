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
    @AppStorage("textSize") var textSize = defaultTextSize

    @Environment(\.openWindow) var openWindow
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AttributesDocViewLaunch.self) var attributesDocViewLaunch
    
    @Bindable var document: GraphvizDocument
    let url: URL?

    @State private var kind: Int?
    @State private var row: Attribute.ID?
    @State private var zoomScale: CGFloat = 1.0
    @State private var viewScale: CGFloat = 0.0
    @State private var saveViewPresented: Bool = false
    @State private var inspectorPresented: Bool = false
    @State private var viewType = UTType(filenameExtension: UserDefaults.standard.string(forKey: "viewType") ?? defaultViewType)!
    
    var body: some View {
//        VStack {
//            if viewType == .pdf {
//                GraphByType(document: document, viewType: $viewType, zoomScale: $zoomScale, viewScale: $viewScale)
//            } else {
        ViewByType(document: document, viewType: $viewType, zoomScale: $zoomScale, viewScale: $viewScale)
//            }
//        }
        .inspector(isPresented: $inspectorPresented) {
            AttributesView(document: document) // , kind: $kind, row: $row)
                .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
        }
        .focusedSceneValue(\.saveViewPresented, $saveViewPresented)
        .focusedSceneValue(\.saveViewType, $viewType)
        .sheet(isPresented: $saveViewPresented) {
            SaveViewSheet(url: url, viewType: $viewType, graph: $document.graph)
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
                    Picker("View Type", selection: $viewType) {
                        ForEach(viewableContentTypes, id: \.self) {
                            let label = $0.preferredFilenameExtension!
                            Text(label.uppercased()).tag($0)
                        }
                    }
                    .frame(width: 80)
                    .onChange(of: viewType) {
                        document.graph.render(text: document.text, viewType: $1)
                    }
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
                ControlGroup {
                        ScrollView {
                            Text(document.graph.logMessage.message)
                                .foregroundStyle(.red)
                        }
                        .defaultScrollAnchor(.zero)
                } label: {
                    Label("Message", systemImage: "exclamationmark.circle")
                }
                .controlGroupStyle(.menu)
            }
            ToolbarItem(id: "Attributes") {
                Button("Attributes", systemImage: "info.circle") {
                    inspectorPresented.toggle()
                }
            }
        }
    }
}
