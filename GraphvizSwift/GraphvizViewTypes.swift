//
//  GraphvizViewTypes.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/21/25.
//

import UniformTypeIdentifiers
import Foundation

let viewableContentTypes: [String] = {
    var formats = [String]()
    var count: Int32 = 0
    guard let list = gvPluginList(
        Graph.context,
        "device",
        &count) else { return [] }
    var set = Set<String>()
    for i in 0..<Int(count) {
        if let device = list[i] {
            if let utType = UTType(filenameExtension: String(cString: device)),
               let fileExtension = utType.preferredFilenameExtension,
               !utType.isDynamic {
                set.insert(fileExtension)
            }
            free(device)
        }
    }
    free(list)
    formats = Array(set)
    return formats.sorted()
}()
