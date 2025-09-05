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
    @Environment(\.openWindow) var openWindow
    @Environment(AttributesDocViewLaunch.self) var attributesDocViewLaunch
    @Environment(\.colorScheme) private var colorScheme

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
    @State private var viewScale: CGFloat = 1.0

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            AttributesView(document: document)
                .focusedSceneValue(\.attributesKind, $kind)
                .focusedSceneValue(\.attributesRow, $row)
                .toolbar(removing: .sidebarToggle)
        }
        detail: {
            switch viewType {
            case document.docType:
                TextEditor(text: $document.text)
                    .font(.system(size: 12*zoomScale, design: .monospaced)) // TODO: get an accessible default from system?
                    .onChange(of: document.text) {
                        _ = document.graph.render(text: document.text, viewType: viewType)
                    }
            case .canon, .gv, .dot, .json:
                if let text = String(data: document.graph.render(text: document.text, viewType: viewType), encoding: .utf8) {
                    ScrollView {
                        Text(text)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 12*zoomScale)) // TODO: get an accessible default from system?
                    }
                } else {
                    Text("Render of text type \(viewType.identifier) failed")
                        .font(Font.title)
                }
            default:
                if let image = NSImage(data: document.graph.render(text: document.text, viewType: viewType)) {
                    GeometryReader { geometryProxy in
                        ScrollView([.vertical, .horizontal]) {
                            Image(nsImage: image)
                                .resizable()
                                .frame(width: image.size.width*zoomScale, height: image.size.height*zoomScale)
                                .background(colorScheme == .light ? Color.gray : Color.white)
                        }
                    }
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    }
                    action: { size in
                        viewScale = min(size.width/image.size.width, size.height/image.size.height)
                    }
                } else {
                    Text("Render of image type \(viewType.identifier) unsupported")
                        .font(Font.title)
                }
            }
        }
//        .background(Color.secondary.opacity(0.5))
        .focusedSceneValue(\.saveViewShow, $saveViewShow)
        .focusedSceneValue(\.saveViewType, $viewType)
        .sheet(isPresented: $saveViewShow) {
            SaveViewSheet(saveViewShow: $saveViewShow, url: url, viewType: $viewType, graph: $document.graph)
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
                        zoomScale /= 2.0.squareRoot()
                    }
                    Button("Actual Size", systemImage: "1.magnifyingglass") {
                        zoomScale = 1.0
                    }
                    Button("Zoom in", systemImage: "plus.magnifyingglass") {
                        zoomScale *= 2.0.squareRoot()
                    }
                    Button("Zoom to Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                        zoomScale = viewScale
                    }
                }
            }
        }
//        .toolbarBackground(Color.primary.opacity(0.5))
    }
}
