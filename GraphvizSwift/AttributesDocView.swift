//
//  AttributesDocView.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 7/2/25.
//

import SwiftUI
import WebKit

@MainActor
struct AttributesDocView: NSViewRepresentable {
    @Environment(KindRow.self) private var kindRow: KindRow

//    @Binding var kind: Int
//    @Binding var row: Attribute.ID?
    
//    typealias Coordinator = Graph
//    func makeCoordinator() -> Coordinator {
//        return graph
//    }
//    
    func makeNSView(context: Context) -> NSView {
        let docView = WKWebView()
        docView.loadHTMLString(ParsedAttributes.shared.overview, baseURL: URL(filePath: ""))

//        let url = URL(string: "data:text/html;charset=utf8,\(ParsedAttributes.shared.overview.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
//        docView.load(URLRequest(url: url!))

        return docView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        let nsView = nsView as! WKWebView
        let kind = kindRow.kind
        let row = kindRow.row
        let table = ParsedAttributes.shared.tables[kind]
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
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        print("dismantling AttributeDocView", nsView)
        nsView.prepareForReuse()
    }
}

// seems like overkill, but retained in case
//@MainActor
//struct AttributesDocViewRepresentable: NSViewControllerRepresentable {
//    var graph: Graph
//    @Binding var kind: Int
//    @Binding var row: Attribute.ID?
//
//    final class Coordinator: NSViewController, WKUIDelegate {
//        var graph: Graph
//        var webView: WKWebView!
//
//        init(graph: Graph) {
//            self.graph = graph
//            super.init(nibName: nil, bundle: nil)
//        }
//
//        override func loadView() {
//            webView = WKWebView()
//            view = webView
//        }
//
//        override func viewDidLoad() {
//            super.viewDidLoad()
//            webView.uiDelegate = self
//            webView.loadHTMLString(ParsedAttributes.shared.overview, baseURL: URL(filePath: ""))
//        }
//        
//        @available(*, unavailable)
//        required init?(coder: NSCoder) {
//            print("coder init called for GraphAsPDF.Controller")
//            fatalError("init(coder:) has not been implemented")
//        }
//        
//        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
//            print("CONFIGURE WEBVIEW!", webView)
//            return webView
//        }
//        
//        func webViewDidClose(_ webView: WKWebView) {
//            print("CLOSED WEBVIEW!", webView)
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(graph: graph)
//    }
//
//    func makeNSViewController(context: Context) -> NSViewController {
//        return context.coordinator
//    }
//    
//    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
//        let nsView = nsViewController.view as! WKWebView
//        let table = ParsedAttributes.shared.tables[kind]
//        print("UPDATING DOC VIEW", nsView)
//        if let row = row,
//           let index = table.firstIndex(where: { $0.id == row }) {
//            let name = table[index].name
//            print(name)
//            nsView.evaluateJavaScript("window.location.hash='#\(name)'") { (result: Any?, error: Error?) in
//                if let result = result {
//                    print("Result from JavaScript: \(result)")
//                }
//                if let error = error {
//                    print("Error evaluating JavaScript: \(error)")
//                }
//            }
//        }
//    }
//
//    static func dismantleNSViewController(_ nsViewController: NSViewController, coordinator: Coordinator) {
//        print("dismantling AttributeDocViewRepresentable", nsViewController.view)
//    }
//}
