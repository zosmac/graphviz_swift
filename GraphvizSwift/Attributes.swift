//
//  Attributes.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/20/25.
//

import Foundation

let parsedAttributes = ParsedAttributes()

/// Attribute reflects a graph, node, or edge property after the graph's setting applied.
struct Attribute: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String /// Attribute name
    let value: String /// Attribute's value
    let defaultValue: String?
    let simpleType: String
    let enumeration: [String]?
    let listItemType: String?

    init(attribute: ParsedAttribute, value: String) {
        self.id = attribute.id
        self.name = attribute.name
        self.value = value
        self.defaultValue = attribute.defaultValue
        self.simpleType = attribute.simpleType
        self.enumeration = attribute.enumeration
        self.listItemType = attribute.listItemType
    }

    func hash(into hasher: inout Hasher) { // Hashable
        hasher.combine(id)
    }
}

/// ParsedAttribute defines a graph, node, or edge property parsed from attributes.xml.
final class ParsedAttribute: Comparable {
    static func < (lhs: ParsedAttribute, rhs: ParsedAttribute) -> Bool { // Comparable
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
    static func == (lhs: ParsedAttribute, rhs: ParsedAttribute) -> Bool { // Equatable
        lhs.name == rhs.name
    }

    let id = UUID()
    let name: String
    var value: String! // value if set in document, and changed by user in UI
    var defaultValue: String? // from attributes.xml
    var simpleType = ""
    var enumeration: [String]? // option values of enumerated type, true/false for boolean
    var listItemType: String?
    var doc = ""

    // Identify attribute's complexType membership, and whether it has a default value.
    // These values are only used during parsing.
    var graph: String?
    var subgraph: String?
    var cluster: String?
    var node: String?
    var edge: String?

    init(name: String) {
        self.name = name
        self.value = ""
    }

    // An attribute may apply to a graph, node or edge, so each attribute must be copied to be distinct by kind.
    init(copy: ParsedAttribute, kind: Int, _ defaultValue: String? = nil) { // Copyable
        self.name = copy.name
        self.simpleType = copy.simpleType
        self.enumeration = copy.enumeration
        self.listItemType = copy.listItemType
        self.doc = copy.doc

        // for TextField, use defaultValue for field label
        self.defaultValue = copy.defaultValue
        if defaultValue != "" {
            self.defaultValue = defaultValue // graph/node/edge default, if defined, overrides
        }
        // for Picker, set value to identify selection, seeding with defaultValue if defined
        var value = ""
        if self.enumeration != nil {
            if let defaultValue = self.defaultValue {
                value = defaultValue
            } else {
                self.enumeration?.insert("", at: 0)
            }
        }
        self.value = value
    }
}

/// Attributes holds the attribute settings for a graph.
struct Attributes {
    let kinds: [[Attribute]] // by kind: AGRAPH, AGNODE, AGEDGE

    init(applying settings: [[AnyHashable: Any]]) {
        var kinds = Array(repeating: [Attribute](), count: 3)
        // merge document's attribute settings into its attributes
        for (kind, attributes) in parsedAttributes.kinds.enumerated() {
            for attribute in attributes {
                kinds[kind].append(
                    Attribute(attribute: attribute,
                              value: settings[kind][attribute.name] as? String ?? attribute.value))
            }
        }
        self.kinds = kinds
    }
}

/// ParsedAttributes contains Graphviz attributes, by kind of graph, node, or edge, and documentation of the attributes.
final class ParsedAttributes {
    let kinds: [[ParsedAttribute]] // by kind: AGRAPH, AGNODE, AGEDGE
    let documentation: String

    init() {
        let url = Bundle.main.url(forResource: "attributes", withExtension: "xml")
        let data = try! Data(contentsOf: url!)
        let parser = XMLParser(data: data)
        let delegate = AttributesParser() // strong here, parser.delegate is unowned(unsafe)
        parser.delegate = delegate
        if !parser.parse() {
            print("parse failed \(parser.parserError?.localizedDescription ?? "")")
        }
        var documentation = """
<style>
    :root {
        color-scheme: light dark; /* Enables support for light-dark() */
        --background-color: light-dark(#ffffff, #333333);
        --text-color: light-dark(#000000, #ffffff);
        --link-color: light-dark(#0000FF, #8888FF);
    }
    table {
        border-collapse: collapse; /* Collapse borders for a clean grid */
    }
    th, td {
        border: 2px solid #888;
        padding: 4px; /* Add some padding inside cells */
    }
    * {
        background-color: var(--background-color);
        color: var(--text-color);
        font-family: sans-serif;
        font-size: 10pt;
    }
    h1 {
        font-size: 13pt;
        font-weight: bold;
    }
    h2 {
        font-size: 12pt;
    }
    a[href] {
        font-family: Menlo,monospace;
        font-size: 9pt;
        color: var(--link-color);
    }
    code {
        font-family: Menlo,monospace;
        font-size: 9pt;
    }
</style>
<html><body id="home">
    <h1>Overview</h1>
        \(delegate.overviewDoc)
    <h1>Attribute Types</h1>
"""
        for key in delegate.simpleTypeDoc.keys.sorted() {
            print(key)
            if let simpleTypeDoc = delegate.simpleTypeDoc[key], !simpleTypeDoc.isEmpty {
                documentation += simpleTypeDoc
            }
            if let listItemType = delegate.listItemType[key] {
                documentation += "<p>A list of <a href=\"#\(listItemType)\">\(listItemType)</a> values.</p>"
            }
            for attribute in delegate.enumeration.filter({ $0.0 == key }) {
                documentation += "Valid values for <code>\(key)</code> are<ul>"
                for type in attribute.value {
                    documentation += "<li><code>\(type)</code></li>"
                }
                documentation += "</ul>"
            }
            documentation += "<code>\(key)</code> is a valid type for<ul>"
            for attribute in delegate.attributes.filter({ $0.simpleType == key }) {
                print("\t\(attribute.name)")
                documentation += "<li><a href=\"#\(attribute.name)\">\(attribute.name)</a></li>"
            }
            documentation += "</ul>"
        }

        documentation += "<h1>Attributes</h1>"
        var kinds = Array(repeating: [ParsedAttribute](), count: 3)
        for attribute in delegate.attributes.sorted() {
            attribute.enumeration = delegate.enumeration[attribute.simpleType]
            attribute.listItemType = delegate.listItemType[attribute.simpleType]
            documentation += "\n" + attribute.doc

            if attribute.graph != nil {
                kinds[AGRAPH].append(ParsedAttribute(copy: attribute, kind: AGRAPH, attribute.graph!))
            }
            if attribute.node != nil {
                kinds[AGNODE].append(ParsedAttribute(copy: attribute, kind: AGNODE, attribute.node!))
            }
            if attribute.edge != nil {
                kinds[AGEDGE].append(ParsedAttribute(copy: attribute, kind: AGEDGE, attribute.edge!))
            }
        }

        self.documentation = documentation + "</body></html>"
        self.kinds = kinds
    }
}

/// AttributesParser reads attributes.xml and parses out the Graphviz attributes.
final class AttributesParser: NSObject, XMLParserDelegate {
    var overviewDoc = ""
    var attributes = [ParsedAttribute]()
    var indices = [String: Int]()
    var listItemType = Dictionary<String, String>()
    var enumeration = Dictionary<String, [String]>()
    var simpleTypeDoc = Dictionary<String, String>()

    // track which XML element within as parsing proceeds
    var inAttribute: String?
    var inSimpleType: String?
    var inComplexType: String?
    var inAnnotation: String?
    var inDocumentation = false

    func addHTML(stringer: () -> String) {
        let string = stringer()
        if inAnnotation != nil {
            overviewDoc += string
        } else if let name = inAttribute {
            if attributes[indices[name]!].doc.isEmpty {
                let type = attributes[indices[name]!].simpleType
                if simpleTypeDoc[type] == nil {
                    attributes[indices[name]!].doc = "<h2 id=\"\(name)\">\(name) <i>\(type)</i></h2>\n"
                } else {
                    attributes[indices[name]!].doc = "<h2 id=\"\(name)\">\(name) <a href=\"#\(type)\"><i>\(type)</i></a></h2>\n"
                }
            }
            attributes[indices[name]!].doc += string
        } else if let name = inSimpleType {
            if simpleTypeDoc[name] == nil {
                simpleTypeDoc[name] = "<h2 id=\"\(name)\">\(name)</h2>\n"
            }
            simpleTypeDoc[name]! += string
        }
    }

    // complete processing of document
    func parserDidEndDocument(
        _ parser: XMLParser
    ) {
    }

    // begin handling for element
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
//        print("startelement", elementName, attributeDict)
        if !elementName.hasPrefix("xsd:") && !inDocumentation {
            print("============ non xsd found!================== \(elementName)")
            return
        }
        switch elementName {
        case "xsd:attribute":
            if let name = attributeDict["name"] {
                inAttribute = name // started attribute name= section
                if indices[name] == nil {
                    indices[name] = attributes.count
                    attributes.append(ParsedAttribute(name: name))
                }
                let index = indices[name]!
                attributes[index].simpleType = attributeDict["type"] ?? attributes[index].simpleType
                attributes[index].defaultValue = attributeDict["default"]
            } else if let name = attributeDict["ref"],
                      let index = indices[name] {
//                print(name)
                // defaultValue meanings:
                // 1. if nil, this attribute is not for this KIND
                // 2. if among a complexType(i.e. a KIND), set default to non-nil
                // 3. if not blank, the defaultValue FOR THIS KIND overrides any default set by <attribute name=> tag
                let defaultValue = attributeDict["default"] ?? ""
                switch inComplexType! {
                case "graph":
                    attributes[index].graph = defaultValue
                case "subgraph":
                    attributes[index].subgraph = defaultValue
                case "cluster":
                    attributes[index].cluster = defaultValue
                case "node":
                    attributes[index].node = defaultValue
                case "edge":
                    attributes[index].edge = defaultValue
                default:
                    break
                }
            }
        case "xsd:list":
            if let value = attributeDict["itemType"] {
                listItemType[inSimpleType!] = value
            }
        case "xsd:enumeration":
            if let value = attributeDict["value"] {
                if enumeration[inSimpleType!] == nil {
                    enumeration[inSimpleType!] = [value]
                } else {
                    enumeration[inSimpleType!]! += [value]
                }
            }
        case "xsd:simpleType":
            if let name = attributeDict["name"] {
                inSimpleType = name // started simpleType section
            }
        case "xsd:complexType":
            if let name = attributeDict["name"] {
                inComplexType = name // started complexType section
            }
        case "xsd:documentation":
            inDocumentation = true
        case "xsd:annotation":
            if let id = attributeDict["id"] {
                // only top level annotations in the "overview" (special annotation section) have id, to create an anchor target.
                inAnnotation = id // started special annotation section
                overviewDoc += "<h2 id=\"\(id)\">\(id)</h2>\n"
            }
            //        case "xsd:restriction":
            //        case "xsd:schema":
        default:
            break
        }
    }

    // conclude handling for element
    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
//        print("endelement", elementName)
        switch elementName {
        case "xsd:attribute":
            inAttribute = nil // ended attribute name= element
        case "xsd:simpleType":
            inSimpleType = nil // ended simpleType element
        case "xsd:complexType":
            inComplexType = nil // ended complexType element
        case "xsd:documentation":
            inDocumentation = false
        case "xsd:annotation":
            inAnnotation = nil
        default:
            break
        }
    }

    // CDATA are blocks of html documentation
    func parser(
        _ parser: XMLParser,
        foundCDATA CDATABlock: Data
    ) {
        if let string = String(data: CDATABlock, encoding: .utf8) {
            addHTML { string }
        }
    }

    // foundCharacters are betwen tags, and probably a mistake.
    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        if string.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
            print("Found Unexpected Characters: |\(string)|")
        }
    }
}
