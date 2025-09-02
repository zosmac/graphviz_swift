//
//  AttributesDocView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 7/2/25.
//

import SwiftUI
import WebKit

@Observable final class AttributesDocViewLaunch {
    var firstTime: Bool = true
}

/// AttributesDocView displays the documentation for attributes from attributes.xml.
struct AttributesDocView: NSViewRepresentable {
    @FocusedValue(\.attributesKind) private var attributesKind
    @FocusedValue(\.attributesRow) private var attributesRow
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(navigationAction.request.url?.absoluteString.hasPrefix("file:///") ?? false ? .allow : .cancel) // prevent navigation away from doc page
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let docView = WKWebView()
        docView.navigationDelegate = context.coordinator
        docView.loadHTMLString(parsedAttributes.documentation, baseURL: URL(filePath: "")) // aka: "file:///"
        return docView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        var name = "#"
        if let kind = attributesKind?.wrappedValue {
           let table = parsedAttributes.kinds[kind].attributes
           if let row = attributesRow?.wrappedValue,
              let index = table.firstIndex(where: { $0.id == row }) {
               name += table[index].name
           }
        }
        nsView.evaluateJavaScript("window.location.hash='\(name)'")
    }
    
    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        //        print("dismantling AttributeDocView", nsView)
        nsView.prepareForReuse()
    }
}
