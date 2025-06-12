//
//  GraphvizView.swift
//  Graphviz
//
//  Created by Keefe Hayes on 5/10/25.
//

import SwiftUI
import PDFKit

struct GraphvizView: View {
    @Binding var document: GraphvizDocument
    @State private var pdfView = PDFView()
    @State private var inspectorPresented: Bool = false
    @State private var inspector = "attributes"

    var body: some View {
        GraphView(document: $document, pdfView: $pdfView)
            .inspector(isPresented: $inspectorPresented) {
                InspectorView(inspector: $inspector, document: $document, pdfView: $pdfView)
                    .inspectorColumnWidth(min: 280, ideal: 280)
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
                        pdfView.zoomIn(self)
                    }
                }
                ToolbarItem(id: "out") {
                    Button("Zoom out", systemImage: "minus.magnifyingglass") {
                        pdfView.zoomOut(self)
                    }
                }
                ToolbarItem(id: "actual") {
                    Button("Actual Size", systemImage: "1.magnifyingglass") {
                        pdfView.scaleFactor = 1.0
                    }
                }
                .defaultCustomization(.hidden)
                ToolbarItem(id: "fit") {
                    Button("Zoom to Fit", systemImage: "arrow.up.left.and.down.right.magnifyingglass") {
                        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
                    }
                }
                .defaultCustomization(.hidden)
                ToolbarItem(id: "print") {
                    Button("Print", systemImage: "printer") {
                        pdfView.print(with: NSPrintInfo(), autoRotate: true, pageScaling: .pageScaleDownToFit)
                    }
                }
                .defaultCustomization(.hidden)
            }
    }
}
