//
//  ViewTypePicker.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 8/21/25.
//

import UniformTypeIdentifiers
import SwiftUI

struct ViewTypePicker: View {
    @Binding var viewType: String

    var body: some View {
        Picker(selection: $viewType) {
            ForEach(viewableContentTypes, id: \.self) {
                Text($0.uppercased()).tag($0)
                    .frame(width: 60, alignment: .leading)
            }
        }
        label: {
            Text("View Type")
                .frame(width: 110, alignment: .leading)
        }
    }
}

let layoutEngines: [String] = {
    var count: Int32 = 0
    let context = gvContext()
    defer { gvFreeContext(context) }

    guard let list = gvPluginList(context, "layout", &count) else { return [] }
    var set = Set<String>()
    for i in 0..<Int(count) {
        if let layoutEngine = list[i] {
            set.insert(String(cString: layoutEngine))
            free(layoutEngine)
        }
    }
    free(list)
    print(set)
    return Array(set).sorted()
}()

let viewableContentTypes: [String] = {
    var count: Int32 = 0
    let context = gvContext()
    defer { gvFreeContext(context) }

    guard let list = gvPluginList(context, "device", &count) else { return [] }
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
    // Remove dot as it is problematic because it collides with a Microsoft reserved format. Also, image types from the plugin list device formats that quartz does not support.
    set = set.subtracting(["dot", "eps", "icns", "ico", "pict", "ps", "sgi"])
    // If the Dynamic UTTypes filtering removed, then several types work with text rendering. Add them to the UTType extension in GraphvizDocument and the switch case for text view types in ViewByType: .json0, .plain, .plain-ext, .svg_inline, .xdot
    //    set = set.subtracting(["cgimage", "cmap", "cmapx", "cmapx_np", "dot_json", "fig", "imap", "ismap", "pov", "ps2", "tk", "xdot_json"])
    return Array(set).sorted()
}()
