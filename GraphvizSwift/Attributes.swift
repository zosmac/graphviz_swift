//
//  Attributes.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/20/25.
//

import AppKit

/// Attribute defines a property for graphs, nodes, or edges
@Observable final class Attribute: Identifiable, Equatable {
    static func == (lhs: Attribute, rhs: Attribute) -> Bool { // Equatable
        lhs.name == rhs.name
    }
    let id = UUID()
    let name: String
    let kind: Int
    var value: String
    let defaultValue: String?
    let simpleType: String
    let options: [String]?
    let listItemType: String?
    let doc: String
    
    init(attribute: ParsedAttribute) {
        self.name = attribute.name
        self.kind = attribute.kind
        self.value = attribute.value
        self.defaultValue = attribute.defaultValue
        self.simpleType = attribute.simpleType
        self.options = attribute.options
        self.listItemType = attribute.listItemType
        self.doc = attribute.doc
    }
}

/// Attribute defines a property for graphs, nodes, or edges
final class ParsedAttribute: Comparable {
    static func < (lhs: ParsedAttribute, rhs: ParsedAttribute) -> Bool { // Comparable
        lhs.name < rhs.name
    }
    static func == (lhs: ParsedAttribute, rhs: ParsedAttribute) -> Bool { // Equatable
        lhs.name == rhs.name
    }
    
    var name: String
    var kind: Int!
    var value = "" // value if set in document, and changed by user in UI
    var defaultValue: String? // from attributes.xml
    var simpleType = ""
    var options: [String]? // option values of enumerated type, true/false for boolean
    var listItemType: String?
    var doc = ""
    
    // identify attribute's complexType membership, and whether it has a default value
    // these values are only used during parsing
    var graph: String?
    var subgraph: String?
    var cluster: String?
    var node: String?
    var edge: String?
    
    init(name: String) {
        self.name = name
    }
    
    // an Observable must be a class, and an attribute may apply to graphs, nodes
    // and/or edges, so for each attribute must be distinct across kinds
    init(copy: ParsedAttribute, kind: Int, _ defaultValue: String? = nil) { // Copyable
        self.name = copy.name // don't need self here to disambiguate :)
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
        if self.options != nil {
            if let defaultValue = self.defaultValue {
                self.value = defaultValue
            }
        }
    }
}

@Observable final class Attributes {
    let overview: String
    let tables: [[Attribute]] // AGRAPH, AGNODE, AGEDGE
    
    init(graph: Graph) {
        let attributes = ParsedAttributes.parsedAttributes
        self.overview = attributes.overview
        var tables = Array(repeating: [Attribute](), count: 3)
        // merge document's attribute settings into attributes
        for kind in [AGRAPH, AGNODE, AGEDGE] {
            for attribute in attributes.tables[kind] {
                tables[kind].append(Attribute(attribute: attribute))
                if let value = graph.settings[kind][attribute.name] {
                    tables[kind].last!.value = value
                }
            }
        }
        self.tables = tables
    }
}

final class ParsedAttributes {
    nonisolated(unsafe) static let parsedAttributes = ParsedAttributes()

    var overview = "" // overview doc from attributes.xml
    var tables: [[ParsedAttribute]] = [[], [], []] // AGRAPH, AGNODE, AGEDGE
    
    init() {
        let url = Bundle.main.url(forResource: "attributes", withExtension: "xml")
        let data = try! Data(contentsOf: url!)
        let parser = XMLParser(data: data)
        let delegate = AttributesParser() // strong here, parser.delegate is unowned(unsafe)
        parser.delegate = delegate
        if !parser.parse() {
            print("parse failed \(parser.parserError?.localizedDescription ?? "")")
        }

        self.overview = delegate.overview
        for attribute in delegate.attributes {
            if let options = delegate.simpleTypes[attribute.simpleType] {
                if options.count == 1 {
                    attribute.listItemType = options.first!
                } else {
                    attribute.options = options
                }
            }
            if let doc = delegate.simpleTypeDoc[attribute.simpleType] {
                attribute.doc += "<p><b>\(attribute.simpleType)</b><p>\(doc)"
            }
            if attribute.graph != nil {
                tables[AGRAPH].append(ParsedAttribute(copy: attribute, kind: AGRAPH, attribute.graph!))
            }
            if attribute.node != nil {
                tables[AGNODE].append(ParsedAttribute(copy: attribute, kind: AGNODE, attribute.node!))
            }
            if attribute.edge != nil {
                tables[AGEDGE].append(ParsedAttribute(copy: attribute, kind: AGEDGE, attribute.edge!))
            }
            tables[AGRAPH].sort() // graph attributes
            tables[AGNODE].sort() // node attributes
            tables[AGEDGE].sort() // edge attributes
        }
    }
}

class AttributesParser: NSObject, XMLParserDelegate {
    var overview = ""
    var attributes: [ParsedAttribute] = []
    var indices: [String: Int] = [:]
    var simpleTypes: Dictionary<String, [String]> = [:]
    var simpleTypeDoc: Dictionary<String, String> = [:]
    
    // track which element within as parsing proceeds
    var attribute: String?
    var simpleType: String?
    var complexType: String?
    var annotation: String?
    var documentation = false

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
                overview += "<p><b>\(id)</b><p>"
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
            break
        }
    }
    
    // foundCharacters are part of the documentation
    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        if annotation != nil { // id'd annotations provide attributes overview
            overview += string
        }
        if documentation {
            if let name = attribute {
                attributes[indices[name]!].doc += string
            } else if let name = simpleType {
                if simpleTypeDoc[name] == nil {
                    simpleTypeDoc[name] = string
                } else {
                    simpleTypeDoc[name]! += string
                }
            }
        }
    }
}
