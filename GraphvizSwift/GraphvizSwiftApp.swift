//
//  GraphvizSwiftApp.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/10/25.
//

import SwiftUI

@main
struct GraphvizSwiftApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: GraphvizSwiftDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
