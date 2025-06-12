//
//  Attributes.swift
//  GraphvizSwift
//
//  Created by Keefe Hayes on 5/20/25.
//

import AppKit

/// Attribute defines a property for graphs, nodes, or edges
@Observable final class Attribute: Identifiable, Comparable, Hashable, Copyable {
    static func < (lhs: Attribute, rhs: Attribute) -> Bool { // Comparable
        lhs.name < rhs.name
    }
    
    static func == (lhs: Attribute, rhs: Attribute) -> Bool { // Equatable
        lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) { // Hashable
        hasher.combine(name)
    }
    
    var id = UUID()
    var name: String
    var kind: Int?
    var type = ""
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
    
    var defaultValue: String? // from attributes.xml
    var value = "" // value if set in document, and changed by user in UI // TODO: make optional?
    
    init(name: String) {
        self.name = name
    }
    
    // an Observable must be a class, and an attribute may apply to graphs, nodes
    // and/or edges, so for each attribute must be distinct across kinds
    init(copy: Attribute, kind: Int, _ defaultValue: String) { // Copyableq
        self.name = copy.name // don't need self here to disambiguate :)
        self.kind = kind
        self.type = copy.type
        self.options = copy.options
        self.listItemType = copy.listItemType
        self.doc = copy.doc
        
        // these don't matter after attribute copied to specific table
        // only used for recording default value for a complexType
        //        graph = copy.graph
        //        subgraph = copy.subgraph
        //        cluster = copy.cluster
        //        node = copy.node
        //        edge = copy.edge
        
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

class Attributes {
    var overview = "" // overview doc from attributes.xml
    var tables: [[Attribute]] = [[], [], []] // AGRAPH, AGNODE, AGEDGE

    init() {
        let url = Bundle.main.url(forResource: "attributes", withExtension: "xml")
        let data = try! Data(contentsOf: url!)
        let parser = XMLParser(data: data)
        let delegate: AttributesParser = AttributesParser()
        parser.delegate = delegate
        if !parser.parse() {
            print("parse failed \(parser.parserError?.localizedDescription ?? "")")
        }
        overview = delegate.overview
        for attribute in delegate.attributes {
            if attribute.graph != nil {
                tables[AGRAPH].append(Attribute(copy: attribute, kind: AGRAPH, attribute.graph!))
            }
            if attribute.node != nil {
                tables[AGNODE].append(Attribute(copy: attribute, kind: AGNODE, attribute.node!))
            }
            if attribute.edge != nil {
                tables[AGEDGE].append(Attribute(copy: attribute, kind: AGEDGE, attribute.edge!))
            }
        }
        tables[AGRAPH].sort() // graph attributes
        tables[AGNODE].sort() // node attributes
        tables[AGEDGE].sort() // edge attributes
    }
}

class AttributesParser: NSObject, XMLParserDelegate {
    var attributes: [Attribute] = []
    var indices: [String: Int] = [:]
    var simpleTypes: Dictionary<String, [String]> = [:]
    var typesDoc: Dictionary<String, String> = [:]
    var overview = ""
    
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
        for attribute in attributes {
            if let options = simpleTypes[attribute.type] {
                if options.count == 1 {
                    attribute.listItemType = options.first!
                } else {
                    attribute.options = options
                }
            }
            if let doc = typesDoc[attribute.type] {
                attribute.doc += "<p><b>\(attribute.type)</b><p>\(doc)"
            }
        }
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
                    attributes.append(Attribute(name: name))
                }
                let index = indices[name]!
                attributes[index].type = attributeDict["type"] ?? attributes[index].type
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
                if typesDoc[name] == nil {
                    typesDoc[name] = string
                } else {
                    typesDoc[name]! += string
                }
            }
        }
    }
}
