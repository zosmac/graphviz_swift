//
//  GraphvizApp.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import UniformTypeIdentifiers
import SwiftUI
import WebKit

let GraphvizErrorDomain = "GraphvizErrorDomain"
enum GraphvizError: Int {
    case OK
    case FileParse
}

@Observable class KindRow {
    var kind: Int
    var row: Attribute.ID?
    init(kind: Int = AGRAPH, row: Attribute.ID? = nil) {
        self.kind = kind
        self.row = row
    }
}

@main
struct GraphvizApp: App {
    @State private var kindRow = KindRow()
    
    var body: some Scene {
        DocumentGroup(newDocument: GraphvizDocument()) { file in
            GraphvizView(document: file.$document,
                         graph: Graph(document: file.$document),
                         utType: .pdf)
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("Graphviz Help") {
                    print("Help requested...")
                    if let url = Bundle.main.url(forResource: "graphviz", withExtension: "help") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .defaultSize(width: 800, height: 600)
        .defaultPosition(UnitPoint(x: 0.5, y: 0.1))
        .environment(kindRow)
        
        Window("Attributes", id: "AttributesDocView") {
            AttributesDocView()
                .frame(minWidth: 400, minHeight: 500)
        }
        .defaultSize(width: 400, height: 500)
        .defaultPosition(UnitPoint(x: 0.7, y: 0.1))
        .environment(kindRow)
    }
}
