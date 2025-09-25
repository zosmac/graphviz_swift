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
    guard let list = gvPluginList(Graph.context, "device", &count) else { return [] }
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
    // Remove dot as it is problematic because it collides with a Microsoft reserved format, and image types from the plugin list device formats that quartz does not support.
    set = set.subtracting(["dot", "eps", "icns", "ico", "pict", "ps", "sgi"])
    // If the Dynamic UTTypes filtering removed, then several types work with text rendering. Add them to the UTType extension in GraphvizDocument and the switch case for text view types in ViewByType: .json0, .plain, .plain-ext, .svg_inline, .xdot
    //    set = set.subtracting(["cgimage", "cmap", "cmapx", "cmapx_np", "dot_json", "fig", "imap", "ismap", "pov", "ps2", "tk", "xdot_json"])
    formats = Array(set)
    return formats.sorted()
}()
