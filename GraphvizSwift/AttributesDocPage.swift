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
                let result = try await page.callJavaScript("""
            function position(elem) {
                var rect = elem.getBoundingClientRect(),
                scrollTop = window.pageYOffset || document.documentElement.scrollTop;
                return rect.top + scrollTop
            }
            const anchors = document.querySelectorAll('a');
            return [...anchors].map(anchor => ({
              name: anchor.name,
              position: position(anchor)
            }));
            """) as? [[String: Any]]
                for position in result! {
                    guard let y = position["position"] as? CGFloat else { continue }
                    positions[position["name"] as! String] = ScrollPosition(y: y)
                }
            } catch { print(error) }

            for (name, position) in positions {
                print(name, position.y!)
            }
        }
    }
}
