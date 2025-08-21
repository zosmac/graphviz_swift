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
    @ObservedObject var document: GraphvizDocument

    @State private var viewType: UTType = .pdf // TODO: set default in app settings
    @State private var presented: Bool = false
    @State private var inspector = ""
    @State private var zoomScale: CGFloat = 1.0
    @State private var showExportSheet = false
    
    init(document: GraphvizDocument) {
        self.document = document
    }
    
    var body: some View {
        GraphByType(document: document, viewType: $viewType, zoomScale: $zoomScale)
            .inspector(isPresented: $presented) {
                InspectorView(document: document, inspector: $inspector)
                    .inspectorColumnWidth(min: 280, ideal: 280)
            }
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    Picker("Format", selection: $viewType) {
                        ForEach(viewableContentTypes, id: \.self) {
                            let label = $0.preferredFilenameExtension!.uppercased()
                            Text(label).tag(label)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: viewType) {
                        print("viewType selected is \(viewType)")
                        try? document.graph.renderGraph(utType: viewType)
                    }
                    Button("Save \(viewType.preferredFilenameExtension!.uppercased())", systemImage: "square.and.arrow.up") {
                        print("hello")
                    }
                }
                ToolbarItemGroup(placement: .status) {
                    ScrollView {
                        // observee must be an observable class type
                        Text(document.graph.observer.observee.message)
                            .foregroundStyle(.red)
                    }
                    .frame(minWidth:200, idealWidth: 250)
                    .defaultScrollAnchor(.zero)
                }
                ToolbarItemGroup {
                    Button("Zoom in", systemImage: "plus.magnifyingglass") {
                        zoomScale *= 2.0.squareRoot()
                    }
                    Button("Zoom out", systemImage: "minus.magnifyingglass") {
                        zoomScale /= 2.0.squareRoot()
                    }
                    if viewType == .pdf {
                        Button("Zoom to fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                            zoomScale = 0.0 // use as flag to get "sizeToFit"
                        }
                    } else {
                        EmptyView()
                    }
                    Button("Actual size", systemImage: "equal.circle") {
                        zoomScale = 1.0
                    }
                }
                ToolbarItemGroup {
                    Button("Attributes", systemImage: "info.circle") {
                        if inspector == "attributes" {
                            inspector = ""
                            presented = false
                        } else {
                            inspector = "attributes"
                            presented = true
                            openWindow(id: "AttributesDocView")
                        }
                    }
                    Button("Content", systemImage: "text.document") {
                        if inspector == "editor" {
                            inspector = ""
                            presented = false
                        } else {
                            inspector = "editor"
                            presented = true
                        }
                    }
                }
            }
    }
}

//            .focusedSceneValue(\.showExportSheet, $showExportSheet)
//            .sheet(isPresented: $showExportSheet) {
//                ExportSheetView(showExportSheet: $showExportSheet, document: $document, format: $document.docType, graph: $graph)
//            }
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
