//
//  AttributesDocView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 7/2/25.
//

import SwiftUI
import WebKit

@MainActor
struct AttributesDocView: NSViewControllerRepresentable {
    @Bindable var graph: Graph
    @Binding var kind: Int
    @Binding var row: Attribute.ID?

    final class Coordinator: NSViewController { // }, WKUIDelegate {
        init(_ docView: WKWebView) {
            print("init web view")
            super.init(nibName: nil, bundle: nil)
            self.view = docView
        }

        override func loadView() {
            super.loadView()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            print("coder init called for AttributesDocView.Controller")
            fatalError("init(coder:) has not been implemented")
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            print("CONFIGURE WEBVIEW!", webView)
            return webView
        }
        
        func webViewDidClose(_ webView: WKWebView) {
            print("CLOSED WEBVIEW!", webView)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(graph.docView)
    }

    func makeNSViewController(context: Context) -> NSViewController {
        let nsViewController = context.coordinator
//        var nsView: NSView
////        let view = WKWebView()
////        view.uiDelegate = context.coordinator
//        nsView = webView
//
//        nsViewController.view = nsView
        return nsViewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        let nsView = nsViewController.view as! WKWebView
        let table = ParsedAttributes.shared.tables[kind]
        print("UPDATING DOC VIEW", nsView)
        if let row = row,
           let index = table.firstIndex(where: { $0.id == row }) {
            let name = table[index].name
            print(name)
            nsView.evaluateJavaScript("window.location.hash='#\(name)'") { (result: Any?, error: Error?) in
                if let result = result {
                    print("Result from JavaScript: \(result)")
                }
                if let error = error {
                    print("Error evaluating JavaScript: \(error)")
                }
            }
        }
    }
    
    static func dismantleNSViewController(_ nsViewController: NSViewController, coordinator: Coordinator) {
        print("dismantling AttributeDocView", nsViewController.view)
    }
}
