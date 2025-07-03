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
    @Observable class Coordinator: NSViewController, WKUIDelegate {
        let style = "<style>\np {font-family:sans-serif;font-size:10pt}\n</style>\n"
        var webView: WKWebView!
        
        init() {
            super.init(nibName: nil, bundle: nil)
        }

        override func loadView() {
            webView = WKWebView()
            webView.uiDelegate = self
//            self.webView(webView, didFinish navigation: webView.navigationDelegate?.webView(webView, didStartProvisionalNavigation: webView.backForwardList.currentItem!) ?? .init())
            view = webView
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            print("load web view")
            webView.loadHTMLString("\(style)<p>\(ParsedAttributes.parsedAttributes.overview)</p>", baseURL: URL(filePath: ""))
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

    @Bindable var graph: Graph
    @Binding var kind: Int
    @Binding var row: Attribute.ID?
    @Bindable var coordinator: Coordinator

    init(graph: Bindable<Graph>, kind: Binding<Int>, row: Binding<Attribute.ID?>) {
        _graph = graph
        _kind = kind
        _row = row
        coordinator = Coordinator()
    }

    func makeCoordinator() -> Coordinator {
        return coordinator
    }

    func makeNSViewController(context: Context) -> Coordinator {
        return context.coordinator
    }
    
    func updateNSViewController(_ nsViewController: Coordinator, context: Context) {
        let nsView = nsViewController.view as! WKWebView
        let table = graph.attributes.tables[kind]
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
    
    static func dismantleNSViewController(_ nsViewController: Coordinator, coordinator: Coordinator) {
        print("dismantling AttributeDocView", nsViewController.view)
    }
}
