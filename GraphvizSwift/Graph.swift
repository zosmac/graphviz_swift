//
//  Graph.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 6/12/25.
//

import UniformTypeIdentifiers
import SwiftUI

nonisolated(unsafe) let graphContext = gvContext()

/// Graph bridges a Graphviz document to its views.
@Observable final class Graph {
    var text: String!

    private var sceneViewType: UTType?
    var viewType: UTType! {
        get {
            sceneViewType
        }
        set {
            self.sceneViewType = newValue
            render(text: text, viewType: newValue, attributeChanged: true)
        }
    }
    var data = Data()
    var settings: [[String: String]] = [[:], [:], [:]]
    var attributes: Attributes! // set in render

    nonisolated
    init(text: String) {
        self.text = text
        self.viewType = UTType(filenameExtension: UserDefaults.standard.string(forKey: "viewType")!)
    }

    func changeAttribute(kind: Int, name: String, value: String) -> Void {
        settings[kind][name] = value
        print("update attribute \(kind) \(name) \(value)")
        render(text: text, viewType: viewType, attributeChanged: true)
    }

    nonisolated
    func render(text: String, viewType: UTType, attributeChanged: Bool = false) -> Void {
        print("RENDER requested for \(viewType) (attributeChanged: \(attributeChanged), current: \(sceneViewType, default: "nil"))")
        if !attributeChanged && sceneViewType == viewType {
            return
        }
        sceneViewType = viewType

        data = GraphvizLogHandler.capture() {
            guard let format = viewType.preferredFilenameExtension,
                  let graph = agmemread(text + "\n") else { return Data() }
            print("RENDER performed for \(viewType) \(graph, default: "nil")")
            for kind in parsedAttributes.kinds { // assumes these are 0, 1, 2 ;)
                var nextSymbol: UnsafeMutablePointer<Agsym_t>? = nil
                while let symbol = agnxtattr(graph, Int32(kind.kind), nextSymbol) {
                    let name = String(cString: symbol.pointee.name)
                    let value = String(cString: symbol.pointee.defval)
                    settings[kind.kind][name] = value
                    nextSymbol = symbol
                }
            }
            attributes = Attributes(applying: settings)

            var renderedData: UnsafeMutablePointer<CChar>?
            var renderedLength: size_t = 0
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
        } as! Data
    }
}
