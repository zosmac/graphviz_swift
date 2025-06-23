//
//  GraphvizView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import SwiftUI
import PDFKit
import WebKit

struct GraphvizView: View {
    @Binding var document: GraphvizDocument
    @State private var inspectorPresented: Bool = false
    @State private var inspector = "attributes"
    
    var body: some View {
        GraphView(document: $document)
            .inspector(isPresented: $inspectorPresented) {
                InspectorView(inspector: $inspector, document: $document)
                    .inspectorColumnWidth(min: 280, ideal: 280)
            }
            .onChange(of: document.text) {
                print("onChange on GraphView", document.text)
                document.graph.updateGraph(text: document.text)
            }
            .toolbar(id: "maintoolbar") {
                ToolbarItem(id: "attributes") {
                    Button("Attributes", systemImage: "info.circle") {
                        if inspector == "attributes" {
                            inspectorPresented.toggle()
                        } else {
                            inspectorPresented = true
                        }
                        inspector = "attributes"
                    }
                }
                ToolbarItem(id: "file") {
                    Button("Content", systemImage: "text.document") {
                        if inspector == "file" {
                            inspectorPresented.toggle()
                        } else {
                            inspectorPresented = true
                        }
                        inspector = "file"
                    }
                }
                ToolbarItem(id: "in") {
                    Button("Zoom In", systemImage: "plus.magnifyingglass") {
                        document.graph.zoomIn()
                    }
                }
                ToolbarItem(id: "out") {
                    Button("Zoom out", systemImage: "minus.magnifyingglass") {
                        document.graph.zoomOut()
                    }
                }
                ToolbarItem(id: "actual") {
                    Button("Actual Size", systemImage: "1.magnifyingglass") {
                        document.graph.zoomToActual()
                    }
                }
                .defaultCustomization(.hidden)
                ToolbarItem(id: "fit") {
                    Button("Zoom to Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                        document.graph.zoomToFit()
                    }
                }
                .defaultCustomization(.hidden)
                ToolbarItem(id: "print") {
                    Button("Print", systemImage: "printer") {
                        if let pdfView = document.graph.nsView as? PDFView {
                            pdfView.print(with: NSPrintInfo(), autoRotate: true, pageScaling: .pageScaleDownToFit)
                        }
                    }
                }
                .defaultCustomization(.hidden)
            }
    }
}
