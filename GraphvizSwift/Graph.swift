//
//  Graph.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/12/25.
//

import UniformTypeIdentifiers
import SwiftUI
import PDFKit
import WebKit

nonisolated(unsafe) let graphContext = gvContext()

/// Graph bridges a Graphviz document to its views.
@Observable final class Graph {
    var text: String!
    var viewType: UTType!
    var data: Data!

    var attributes: Attributes!
    var settings: [[String: String]]!

    nonisolated
    init(text: String, viewType: UTType, settings: [[String: String]] = [[:], [:], [:]]) {
        self.text = text
        self.settings = settings
        self.viewType = viewType
        self.data = render(text: text, viewType: viewType, attributeChanged: true)
    }

    func changeAttribute(kind: Int, name: String, value: String) -> Void {
        settings[kind][name] = value
        attributes = Attributes(applying: settings)
        print("update attribute \(kind) \(name) \(value)")
        data = render(text: text, viewType: viewType, attributeChanged: true)
    }

    nonisolated
    func render(text: String, viewType: UTType, attributeChanged: Bool = false) -> Data {
        if !attributeChanged && self.viewType == viewType {
            return self.data
        }
        self.viewType = viewType

        self.data = GraphvizLogHandler.capture(logMessage: LogMessage()) {
            guard let format = viewType.preferredFilenameExtension,
                  let graph = agmemread(text + "\n") else { return Data() }
            print("RENDER \(viewType) \(graph, default: "nil")")
            for kind in parsedAttributes.kinds { // assumes these are 0, 1, 2 ;)
                var nextSymbol: UnsafeMutablePointer<Agsym_t>? = nil
                while let symbol = agnxtattr(graph, Int32(kind.kind), nextSymbol) {
                    let name = String(cString: symbol.pointee.name)
                    let value = String(cString: symbol.pointee.defval)
                    settings[kind.kind][name] = value
                    nextSymbol = symbol
                }
            }
            self.settings = settings
            self.attributes = Attributes(applying: settings)

            var renderedData: UnsafeMutablePointer<CChar>?
            var renderedLength: size_t = 0
            // PSinputscale = 72.0  // TODO: set as for -s CLI flag using Settings View
            for (kind, settings) in settings.enumerated() {
                for (name, value) in settings {
                    _ = name.withCString { name in
                        value.withCString { value in
                            // withCString's sends in an UnsafePointer. Because agattr does not declare
                            // its parameters as const, must recast argument to UnsafeMutablePointer.
                            return agattr_text(graph, Int32(kind), UnsafeMutablePointer(mutating: name), UnsafeMutablePointer(mutating: value))
                        }
                    }
                }
            }
            gvLayout(graphContext, graph, "dot") // TODO: set as for -K CLI flag?
            defer { gvFreeLayout(graphContext, graph) }
            if gvRenderData(graphContext, graph, format, &renderedData, &renderedLength) == 0 {
                return Data(bytesNoCopy: renderedData!,
                            count: renderedLength,
                            deallocator: .custom { ptr, _ in
                    gvFreeRenderData(ptr) // presumably frees up render memory
                })
            }
            return Data()
        } as? Data
        
        return self.data
    }
}
