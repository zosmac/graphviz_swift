//
//  GraphvizView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI

@Observable final class OpenSidebarCount {
    var count: Int = 0
    init(_ count: Int = 0) {
        self.count = count
    }
}
@Observable final class Sheet {
    var isPresented: Bool = false
}

/// GraphvizView displays the rendered graph and the attributes and file contents inspectors.
struct GraphvizView: View {
    @Environment(\.openWindow) var openWindow
    @Environment(AttributesDocViewLaunch.self) var attributesDocViewLaunch
    @Environment(GraphvizLogHandler.self) var logHandler
    @ObservedObject var document: GraphvizDocument
    let url: URL?
    @Binding var kind: AttributesByKind.ID
    @Binding var row: Attribute.ID?

    @State private var viewType: UTType = .pdf // TODO: set default in app settings
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .detailOnly
    @State private var inspectorPresented: Bool = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var saveViewShow: Bool = false
    @State private var saveViewType: UTType? = nil

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            AttributesView(document: document)
                .focusedSceneValue(\.attributesKind, $kind)
                .focusedSceneValue(\.attributesRow, $row)
                .toolbar(removing: .sidebarToggle)
        }
        detail: {
            ViewByType(document: document, viewType: $viewType, zoomScale: $zoomScale)
                .focusedSceneValue(\.saveViewShow, $saveViewShow)
                .focusedSceneValue(\.saveViewType, $viewType)
                .sheet(isPresented: $saveViewShow) {
                    SaveViewSheet(saveViewShow: $saveViewShow, url: url, viewType: $viewType, graph: $document.graph)
                }
                .coordinateSpace(name: "Image View") // for geometryReader of ViewByType Image View
        }
        .onAppear {
            if attributesDocViewLaunch.firstTime {
                openWindow(id: "AttributesDocView")
            }
            attributesDocViewLaunch.firstTime = false
        }
        .toolbar(id: "GraphvizViewToolbar") {
            ToolbarItem(id: "Sidebar", placement: .navigation) {
                Button("Attributes", systemImage: "tablecells") {
                    if sidebarVisibility == .detailOnly {
                        sidebarVisibility = .doubleColumn
                    } else {
                        sidebarVisibility = .detailOnly
                    }
                }
            }
//            ToolbarItem(id: "Message", placement: .primaryAction) {
//                ControlGroup("􀁞") {
//                    ScrollView {
//                        // logMessage must be an observable class type
//                        Text(document.graph.logMessage.message)
//                            .foregroundStyle(.red)
//                    }
//                    .defaultScrollAnchor(.zero)
//                }
//                .controlGroupStyle(.menu)
//            }
//            .hidden(document.graph.logMessage.message.isEmpty)
            ToolbarSpacer()
            ToolbarItem(id: "View Type", placement: .primaryAction) {
                ControlGroup("View Type") {
                    Picker("View Type", selection: $viewType) {
                        ForEach(viewableContentTypes, id: \.self) {
                            let label = $0.preferredFilenameExtension!.uppercased()
                            Text(label).tag(label)
                        }
                    }
                    .frame(width: 80)
                    SaveViewButton(viewType: viewType)
                }
            }
            ToolbarSpacer()
            ToolbarItem(id: "Zoom", placement: .primaryAction) {
                ControlGroup("Zoom") {
                    Button("Zoom out", systemImage: "minus.magnifyingglass") {
                        if zoomScale == 0.0 { zoomScale = 1.0 }
                        else { zoomScale /= 2.0.squareRoot() }
                    }
                    Button("Actual Size", systemImage: "1.magnifyingglass") {
                        zoomScale = 1.0
                    }
                    Button("Zoom in", systemImage: "plus.magnifyingglass") {
                        if zoomScale == 0.0 { zoomScale = 1.0 }
                        else { zoomScale *= 2.0.squareRoot() }
                    }
                    Button("Zoom to Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                        zoomScale = 0.0 // use as flag to get "sizeToFit"
                    }
                }
            }
//            .hidden([.dot, .gv, .canon].contains(where: { $0 == viewType }))
        }
    }
}
