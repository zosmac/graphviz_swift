//
//  AttributesDocView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 7/2/25.
//

import SwiftUI
import WebKit

/// AttributesDocView displays the documentation for attributes from attributes.xml.
struct AttributesDocView: NSViewRepresentable {
    @Environment(KindRow.self) private var kindRow: KindRow
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
        ) {
            if let baseURL = webView.url,
               baseURL.absoluteString.hasPrefix("file:///") {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel) // prevent navigation away from doc page
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let docView = WKWebView()
        docView.navigationDelegate = context.coordinator
        docView.loadHTMLString(Attributes.defaults.attributesdoc, baseURL: URL(filePath: ""))
        return docView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let kind = kindRow.kind
        let row = kindRow.row
        let table = Attributes.defaults.tables[kind]
        if let row,
           let index = table.firstIndex(where: { $0.id == row }) {
            let name = table[index].name
            nsView.evaluateJavaScript("window.location.hash='#\(name)'") { (result: Any?, error: Error?) in
                if let result {
                    print("Result from JavaScript: \(result)")
                }
                if let error = error {
                    print("Error evaluating JavaScript: \(error)")
                }
            }
        }
    }
    
    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        print("dismantling AttributeDocView", nsView)
        nsView.prepareForReuse()
    }
}
