//
//  GraphvizApp.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import SwiftUI

let GraphvizErrorDomain = "GraphvizErrorDomain"
enum GraphvizError: Int {
    case OK
    case FileParse
}

@main
struct GraphvizApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: GraphvizDocument()) { file in
            let attributes = Attributes(graph: file.document.graph)
            GraphvizView(document: file.$document, attributes: attributes)
        }
        .defaultSize(width: 800, height: 600)
        .defaultPosition(UnitPoint(x: 0.5, y: 0.1))
    }
}
