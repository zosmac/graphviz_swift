//
//  AttributesDocPage.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 11/14/25.
//

import SwiftUI
import WebKit

@Observable final class AttributesDocPage {
    let page = WebPage()
    var positions: [String: ScrollPosition] = [:]

    init() {
        Task { @MainActor in
            do {
                page.load(html: parsedAttributes.documentation, baseURL: URL(string: "about:blank")!)
                while page.isLoading {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                let result = try await page.callJavaScript("return positions();") as? [[String: Any]]
                for position in result! {
                    guard let y = position["position"] as? CGFloat else { continue }
                    positions[position["name"] as! String] = ScrollPosition(y: y)
                }
                print("AttributesDocPage html anchor positions initialized")
            } catch { print(error) }
        }
    }
}
