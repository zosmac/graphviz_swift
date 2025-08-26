//
//  GraphvizView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

@Observable final class Sheet {
    var isPresented: Bool = false
}

/// GraphvizView displays the rendered graph and the attributes and file contents inspectors.
struct GraphvizView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @ObservedObject var document: GraphvizDocument
    let url: URL?
    
    @State private var viewType: UTType = .pdf // TODO: set default in app settings
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var inspectorPresented: Bool = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var showExportSheet: Bool = false
    @State private var showExportType: UTType? = nil

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            AttributesView(graph: $document.graph)
                .toolbar(removing: .sidebarToggle)
        }
        detail: {
            ViewByType(document: document, viewType: $viewType, zoomScale: $zoomScale)
                .focusedSceneValue(\.showExportSheet, $showExportSheet)
                .focusedSceneValue(\.showExportType, $viewType)
                .sheet(isPresented: $showExportSheet) {
                    if let url {
                        ExportSheetView(showExportSheet: $showExportSheet, url: url, viewType: $viewType, graph: $document.graph)
                    }
                }
        }
        .toolbar(id: "GraphvizViewToolbar") {
            ToolbarItem(id: "Sidebar", placement: .navigation) {
                Button("Attributes", systemImage: "tablecells") {
                    if sidebarVisibility == .detailOnly {
                        sidebarVisibility = .doubleColumn
                        openWindow(id: "AttributesDocView")
                    } else {
                        sidebarVisibility = .detailOnly
                        dismissWindow(id: "AttributesDocView") // TODO: only dismiss when all attributesviews closed
                    }
                }
            }
            ToolbarItem(id: "View Type", placement: .primaryAction) {
                ControlGroup("View Type") {
                    Picker("View Type", selection: $viewType) {
                        ForEach(viewableContentTypes, id: \.self) {
                            let label = $0.preferredFilenameExtension!.uppercased()
                            Text(label).tag(label)
                        }
                    }
                    ExportSheetButton(viewType: viewType)
                }
            }
            ToolbarSpacer()
            ToolbarItem(id: "Zoom", placement: .primaryAction) {
                ControlGroup("Zoom") {
                    Button("Zoom out", systemImage: "minus.magnifyingglass") {
                        zoomScale /= 2.0.squareRoot()
                    }
                    Button("Actual Size", systemImage: "1.magnifyingglass") {
                        zoomScale = 1.0
                    }
                    Button("Zoom in", systemImage: "plus.magnifyingglass") {
                        zoomScale *= 2.0.squareRoot()
                    }
                }
            }
            .hidden([.dot, .gv, .canon].contains(where: { $0 == viewType }))
            ToolbarItem(id: "Zoom to Fit", placement: .primaryAction) {
                if viewType == .pdf {
                    Button("Zoom to Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                        zoomScale = 0.0 // use as flag to get "sizeToFit"
                    }
                } else {
                    EmptyView()
                }
            }
            .hidden([.dot, .gv, .canon].contains(where: { $0 == viewType }))
            ToolbarItem(id: "Message", placement: .status) {
                ControlGroup("􀁞") {
                    ScrollView {
                        // observee must be an observable class type
                        Text(document.graph.observer.observee.message)
                            .foregroundStyle(.red)
                    }
                    .defaultScrollAnchor(.zero)
                }
                .controlGroupStyle(.menu)
            }
            .hidden(document.graph.observer.observee.message.isEmpty)
        }
    }
}

//                Button("Attributes", systemImage: "info.circle") {
//                    inspectorPresented.toggle()
//                    if inspectorPresented { // TODO: only dismiss when all attributesviews closed
//                        openWindow(id: "AttributesDocView")
//                    } else {
//                        dismissWindow(id: "AttributesDocView")
//                    }
//                }

//                .frame(minWidth: 600, idealWidth: 800, maxWidth: 1000, minHeight: 400, idealHeight: 500, maxHeight: 700, alignment: .center)
//                .inspector(isPresented: $inspectorPresented) {
//                    AttributesView(graph: $document.graph)
//                }

//            .fileExporter(isPresented: $showExportSheet, document: document, contentType: viewType, defaultFilename: document.name) { result in
//                switch result {
//                case .success(let url):
//                    print("file export of \(url) succeeded")
//                case .failure(let error):
//                    print("Failed to export file: \(error)")
//                }
//            }
//            .fileDialogURLEnabled(#Predicate<URL> { $0.pathExtension == viewType.preferredFilenameExtension! })
//            .fileDialogMessage(Text("Export File"))
//            .fileExporterFilenameLabel(
//                Text("Export \(viewType.preferredFilenameExtension!.uppercased()) File:").bold()
//            )
//            .fileDialogConfirmationLabel(
//                Text("Save \(viewType.preferredFilenameExtension!.uppercased())")
//            )
