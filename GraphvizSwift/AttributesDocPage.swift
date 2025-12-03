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
        loadHome()
    }

    func loadHome() {
        page.load(html: parsedAttributes.documentation)
    }
}
