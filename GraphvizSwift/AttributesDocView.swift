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

extension FocusedValues {
    @Entry var attributesKind: Binding<[Attribute]?>?  // by kind: AGRAPH, AGNODE, AGEDGE
    @Entry var attributesRow: Binding<Attribute.ID?>?
}

/// AttributesDocView displays the documentation for attributes from attributes.xml.
struct AttributesDocView: NSViewRepresentable {
    @FocusedBinding(\.attributesKind) private var attributes
    @FocusedBinding(\.attributesRow) private var row
    
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
        var href = "#"
        if let attributes,
           let row,
           let index = attributes?.firstIndex(where: { $0.id == row }),
           let name = attributes?[index].name {
               href += name
        }
        nsView.evaluateJavaScript("window.location.hash='\(href)'")
    }
    
    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        print("dismantling AttributeDocView", nsView)
        nsView.prepareForReuse()
    }
}
