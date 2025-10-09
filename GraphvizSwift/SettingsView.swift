//
//  SettingsView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 9/5/25.
//

import UniformTypeIdentifiers
import SwiftUI

// TODO: define settings corresponding to graphviz command line options
// e.g: PSinputscale = 72.0 for -s (scale) flag, -K for layout engine (default "dot")

let defaultViewType = "pdf"
let defaultTextSize = 12.0

struct SettingsView: View {
    @AppStorage("viewType") var viewType = defaultViewType
    @AppStorage("textSize") var textSize = defaultTextSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("View Type", selection: $viewType) {
                ForEach(viewableContentTypes, id: \.self) {
                    Text($0.uppercased()).tag($0)
                }
            }
            Slider(value: $textSize, in: 9...32, step: 1) {
                Text("Font Size (\(textSize, specifier: "%.f") pts)")
            } minimumValueLabel: {
                Text("9")
            } maximumValueLabel: {
                Text("32")
            }
        }
        .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 30))
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 64, height: 64)
    }
}
