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
    @Entry var attributesKind: Binding<Int?>?  // by kind: AGRAPH, AGNODE, AGEDGE
    @Entry var attributesRow: Binding<Attribute.ID?>?
}

/// AttributesDocView displays the documentation for attributes from attributes.xml.
struct AttributesDocView: NSViewControllerRepresentable {
    @FocusedBinding(\.attributesKind) private var kind
    @FocusedBinding(\.attributesRow) private var row

    typealias NSViewControllerType = Coordinator

    class Coordinator: NSViewController, WKNavigationDelegate {
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

    func makeNSViewController(context: Context) -> NSViewControllerType {
        let docView = WKWebView()
        docView.navigationDelegate = context.coordinator
        docView.loadHTMLString(parsedAttributes.documentation, baseURL: URL(filePath: "")) // aka: "file:///"
        context.coordinator.view = docView
        return context.coordinator
    }
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        var href = "#"
        if let kind,
           let row {
           let attributes = parsedAttributes.kinds[kind!]
            if let index = attributes.firstIndex(where: { $0.id == row }) {
                href += attributes[index].name
            }
        }
        (nsViewController.view as! WKWebView).evaluateJavaScript("window.location.hash='\(href)'")
    }

    static func dismantleNSViewController(_ nsViewController: NSViewControllerType, coordinator: Coordinator) {
        print("dismantling AttributeDocView", nsViewController)
        nsViewController.view.prepareForReuse()
    }
}
