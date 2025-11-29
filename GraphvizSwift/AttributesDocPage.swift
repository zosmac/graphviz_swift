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

    init() {
        page.load(html: parsedAttributes.documentation, baseURL: URL(string: "about:blank")!)
    }
}
