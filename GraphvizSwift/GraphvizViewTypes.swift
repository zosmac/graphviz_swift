//
//  GraphvizViewTypes.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/21/25.
//

import UniformTypeIdentifiers
import Foundation

extension UTType: @retroactive Identifiable {
    public var id: String { preferredFilenameExtension! }
    static func == (lhs: UTType, rhs: UTType) -> Bool {
        lhs.preferredFilenameExtension! == rhs.preferredFilenameExtension!
    }
    func hash(into hasher: inout Hasher) { // Hashable
        hasher.combine(preferredFilenameExtension!)
    }
}

let viewableContentTypes: [UTType] = {
    var formats = [String]()
    var count: Int32 = 0
    guard let list = gvPluginList(
        graphContext,
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
    return formats.sorted().map {
        UTType(filenameExtension: $0)!
    }
}()
