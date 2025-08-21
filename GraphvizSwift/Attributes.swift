//
//  Attributes.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/20/25.
//

import AppKit

/// Attribute reflects a graph, node, or edge property after the graph's setting applied.
struct Attribute: Identifiable {
    let id: UUID
    let name: String /// Attribute name
    let kind: Int    /// Whether this attribute applies to graph, node, or edge
    let value: String /// Attribute's value
    let defaultValue: String?
    let simpleType: String
    let options: [String]?
    let listItemType: String?
    
    init(attribute: ParsedAttribute, value: String) {
        self.id = attribute.id
        self.name = attribute.name
        self.kind = attribute.kind
        self.value = value
        self.defaultValue = attribute.defaultValue
        self.simpleType = attribute.simpleType
        self.options = attribute.options
        self.listItemType = attribute.listItemType
    }
}

/// ParsedAttribute defines a graph, node, or edge property parsed from attributes.xml.
final class ParsedAttribute: Comparable {
    static func < (lhs: ParsedAttribute, rhs: ParsedAttribute) -> Bool { // Comparable
        lhs.name < rhs.name
    }
    static func == (lhs: ParsedAttribute, rhs: ParsedAttribute) -> Bool { // Equatable
        lhs.name == rhs.name
    }
    
    let id = UUID()
    let name: String
    let kind: Int!
    var value: String! // value if set in document, and changed by user in UI
    var defaultValue: String? // from attributes.xml
    var simpleType = ""
    var options: [String]? // option values of enumerated type, true/false for boolean
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
        self.kind = 0
        self.value = ""
    }
    
    // An attribute may apply to a graph, node or edge, so each attribute must be copied to be distinct by kind.
    init(copy: ParsedAttribute, kind: Int, _ defaultValue: String? = nil) { // Copyable
        self.name = copy.name
        self.kind = kind
        self.simpleType = copy.simpleType
        self.options = copy.options
        self.listItemType = copy.listItemType
        self.doc = copy.doc
        
        // for TextField, use defaultValue for field label
        self.defaultValue = copy.defaultValue
        if defaultValue != "" {
            self.defaultValue = defaultValue // graph/node/edge default, if defined, overrides
        }
        // for Picker, set value to identify selection, seeding with defaultValue if defined
        var value = ""
        if self.options != nil {
            if let defaultValue = self.defaultValue {
                value = defaultValue
            } else {
                self.options?.append("")
            }
        }
        self.value = value
    }
}

/// Attributes holds the attribute settings for a graph.
struct Attributes {
    let tables: [[Attribute]] // AGRAPH, AGNODE, AGEDGE

    nonisolated
    init(applying settings: [[AnyHashable: Any]]) {
        var tables = Array(repeating: [Attribute](), count: 3)
        // merge document's attribute settings into attributes
        for kind in [AGRAPH, AGNODE, AGEDGE] {
            for attribute in Graph.attributeDefaults.tables[kind] {
                tables[kind].append(
                    Attribute(attribute: attribute,
                              value: settings[kind][attribute.name] as? String ?? attribute.value))
            }
        }
        self.tables = tables
    }
}

/// ParsedAttributes contains the tables of Graphviz attributes and documentation of the attributes.
final class ParsedAttributes {
    let tables: [[ParsedAttribute]] // by kind: AGRAPH, AGNODE, AGEDGE
    
    init() {
        let url = Bundle.main.url(forResource: "attributes", withExtension: "xml")
        let data = try! Data(contentsOf: url!)
        let parser = XMLParser(data: data)
        let delegate = AttributesParser() // strong here, parser.delegate is unowned(unsafe)
        parser.delegate = delegate
        if !parser.parse() {
            print("parse failed \(parser.parserError?.localizedDescription ?? "")")
        }
        
        Graph.attributeDocumentation += "<h3>Attributes Overview</h3>" + delegate.overviewDoc + "<h3>Attributes Types</h3>"
        for type in delegate.simpleTypeDoc.keys.sorted() {
            Graph.attributeDocumentation += " " + delegate.simpleTypeDoc[type]!
        }
        Graph.attributeDocumentation += "<h3>Attributes</h3>"
        var tables = Array(repeating: [ParsedAttribute](), count: 3)
        for attribute in delegate.attributes.sorted() {
            if let options = delegate.simpleTypes[attribute.simpleType] {
                if options.count == 1 {
                    attribute.listItemType = options.first!
                } else {
                    attribute.options = options
                }
            }
            
            Graph.attributeDocumentation += " " + attribute.doc
            
            if attribute.graph != nil {
                tables[AGRAPH].append(ParsedAttribute(copy: attribute, kind: AGRAPH, attribute.graph!))
            }
            if attribute.node != nil {
                tables[AGNODE].append(ParsedAttribute(copy: attribute, kind: AGNODE, attribute.node!))
            }
            if attribute.edge != nil {
                tables[AGEDGE].append(ParsedAttribute(copy: attribute, kind: AGEDGE, attribute.edge!))
            }
        }
        Graph.attributeDocumentation = Graph.attributeDocumentation.replacingOccurrences(of: "[\t\r]", with: "", options: [.regularExpression])
        self.tables = tables
    }
}

/// AttributesParser reads attributes.xml to produce the tables of Graphviz attributes.
final class AttributesParser: NSObject, XMLParserDelegate {
    var overviewDoc = ""
    var attributes: [ParsedAttribute] = []
    var indices: [String: Int] = [:]
    var simpleTypes: Dictionary<String, [String]> = [:]
    var simpleTypeDoc: Dictionary<String, String> = [:]
    
    // track which XML element within as parsing proceeds
    var attribute: String?
    var simpleType: String?
    var complexType: String?
    var annotation: String?
    var documentation = false
    var anchorTagTail = ">"
    
    func addHTML(stringer: () -> String) {
        let string = stringer()
        if annotation != nil {
            overviewDoc += string
        } else if let name = attribute {
            if attributes[indices[name]!].doc.isEmpty {
                let type = attributes[indices[name]!].simpleType
                if simpleTypeDoc[type] == nil {
                    attributes[indices[name]!].doc = "<h4><a name=\"\(name)\">\(name)</a> <i>\(type)</i></h4>"
                } else {
                    attributes[indices[name]!].doc = "<h4><a name=\"\(name)\">\(name)</a> <a href=\"#\(type)\"><i>\(type)</i></a></h4>"
                }
            }
            attributes[indices[name]!].doc += string
        } else if let name = simpleType {
            if simpleTypeDoc[name] == nil {
                simpleTypeDoc[name] = "<h4><a name=\"\(name)\">\(name)</a></h4>"
            }
            simpleTypeDoc[name]! += string
        }
    }
    
    // complete processing of document
    func parserDidEndDocument(
        _ parser: XMLParser
    ) {
        simpleTypes["xsd:boolean"] = ["true", "false"] // treat boolean as enumerated type
    }
    
    // begin handling for element
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if !elementName.hasPrefix("xsd:") && !documentation {
            return
        }
        switch elementName {
        case "xsd:attribute":
            if let name = attributeDict["name"] {
                attribute = name // started attribute name= section
                if indices[name] == nil {
                    indices[name] = attributes.count
                    attributes.append(ParsedAttribute(name: name))
                }
                let index = indices[name]!
                attributes[index].simpleType = attributeDict["type"] ?? attributes[index].simpleType
                attributes[index].defaultValue = attributeDict["default"]
            } else if let name = attributeDict["ref"] {
                // defaultValue meanings:
                // 1. if nil, this attribute is not for this KIND
                // 2. if among a complexType(i.e. a KIND), set default to non-nil
                // 3. if not blank, the defaultValue FOR THIS KIND overrides any default set by <attribute name=> tag
                let index = indices[name]!
                let defaultValue = attributeDict["default"] ?? ""
                switch complexType! {
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
                // assume simpleType enumerations have multiple values, so options count 1 means "listItemType"
                simpleTypes[simpleType!] = [value]
            }
        case "xsd:enumeration":
            if let value = attributeDict["value"] {
                if simpleTypes[simpleType!] == nil {
                    simpleTypes[simpleType!] = [value]
                } else {
                    simpleTypes[simpleType!]! += [value]
                }
            }
        case "xsd:simpleType":
            if let name = attributeDict["name"] {
                simpleType = name // started simpleType section
            }
        case "xsd:complexType":
            if let name = attributeDict["name"] {
                complexType = name // started complexType section
            }
        case "xsd:documentation":
            documentation = true
        case "xsd:annotation":
            if let id = attributeDict["id"] {
                annotation = id // started special annotation section
                overviewDoc += "<h4><a name=\"\(id)\">\(id)</a></h4>"
            }
            //        case "xsd:restriction":
            //        case "xsd:schema":
        default:
            if elementName.hasPrefix("html:") {
                addHTML {
                    anchorTagTail = ">"
                    var string = "<" + elementName.suffix(elementName.count - 5)
                    for (key, value) in attributeDict {
                        if key == "rel" {
                            anchorTagTail = " href=\"#"
                        } else {
                            string += " \(key)=\"\(value)\""
                        }
                    }
                    string += anchorTagTail
                    return string
                }
            }
        }
    }
    
    // conclude handling for element
    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "xsd:attribute":
            attribute = nil // ended attribute name= element
        case "xsd:simpleType":
            simpleType = nil // ended simpleType element
        case "xsd:complexType":
            complexType = nil // ended complexType element
        case "xsd:documentation":
            documentation = false
        case "xsd:annotation":
            annotation = nil
        default:
            if elementName.hasPrefix("html:") {
                addHTML { "</\(elementName.dropFirst(5))>" }
            }
        }
    }
    
    // foundCharacters are part of the documentation
    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        if anchorTagTail == ">" {
            addHTML { string }
        } else {
            addHTML { string + "\">" + string }
            anchorTagTail = ">"
        }
    }
}
