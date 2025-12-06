//
//  SettingsView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 9/5/25.
//

import UniformTypeIdentifiers
import SwiftUI
import Synchronization

let defaultLayoutEngine = "dot"
let defaultViewType = "pdf"
let defaultTextSize = 12.0
let defaultInputScale = Double(POINTS_PER_INCH)

struct SettingsView: View {
    @AppStorage("layoutEngine") var layoutEngine = defaultLayoutEngine
    @AppStorage("inputScale") var inputScale = defaultInputScale
    @AppStorage("viewType") var viewType = defaultViewType
    @AppStorage("textSize") var textSize = defaultTextSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
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
                    Picker(selection: $layoutEngine) {
                        ForEach(layoutEngines, id: \.self) {
                            Text($0)
                                .frame(width: 60, alignment: .leading)
                        }
                    }
                    label: {
                        Text("Layout Engine")
                            .frame(width: 110, alignment: .leading)
                    }
                }
                Spacer()
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64, alignment: .trailing)
            }
            Slider(value: $textSize, in: 9...32, step: 1) {
                Text("Font Size (\(textSize, specifier: "%.f") pts)")
                    .frame(width: 110, alignment: .leading)
            } minimumValueLabel: {
                Text("9")
            } maximumValueLabel: {
                Text("32")
            }
            HStack {
                Text("Input Scale")
                    .frame(width: 110, alignment: .leading)
                TextField(value: $inputScale, format: .number) {
                    Text(String(defaultInputScale))
                }
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
                .frame(width: 50)
                .onSubmit {
                    print(inputScale)
                    setInputScale(Double(inputScale))
                }
            }
            .padding([.top], 5)
        }
        .padding(10)
    }
}
