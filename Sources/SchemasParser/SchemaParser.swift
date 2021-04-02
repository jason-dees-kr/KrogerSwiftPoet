//
//  File.swift
//  
//
//  Created by Jason Dees on 4/2/21.
//

import Foundation
import KrogerSwiftPoet

public final class SchemaParser {
    
    private let arguments: [String]

    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }

    public func run() throws {
        let settings = SchemaSettings()
        
        let definitionBuilder = DefinitionsBuilder()
        try definitionBuilder.buildDefinitions(definitions: try ManifestReader(settings: settings).schemaDefinitions)
    }
}

public struct DefinitionsBuilder {
    func buildDefinitions(definitions: [String: Any]) throws {
        try definitions.forEach {(name, def) in
            guard def is [String: Any] else { return }
            let cast = def as! [String: Any]
            let propDict = cast["properties"] as! [String:Any]
            let properties:[Definition.Property] = propDict.map { (key, value) in .init(key: key, value: value as! [String : Any])}
            let definition = Definition(name: name, properties: properties, required: cast["required"] as? [String], description: cast["description"] as? String)
            try definition.build()
        }
    }
}

public struct Definition {
    let name: String
    let properties: [Property]
    let required: [String]?
    let description: String?
    
    public struct Property {
        let name: String
        let description: String?
        let type: String
        let enumValues: [String]?
        let itemsType: String?
        let const: String?
        
//        let pattern: String? = nil
//        let minItems: Int? = nil
//        let maxItems: Int? = nil
        
        init(key: String, value:[String: Any]) {
            name = key
            if let ref = value["$ref"] as? String {
                let fileSplit = ref.split(separator: "/")
                let defName = fileSplit[fileSplit.count - 2]
                type = String(defName)
            }
            else{
                type = value["type"] as! String
            }
            description = value["description"] as? String
            enumValues = value["enum"] as? [String]
            const = value["const"] as? String
            if let item = value["items"] as? [String: Any] {
                if let ref = item["$ref"] as? String {
                    let fileSplit = ref.split(separator: "/")
                    let defName = fileSplit[fileSplit.count - 2]
                    self.itemsType = String(defName)
                }
                else{
                    self.itemsType = item["type"] as? String
                }
            }else{
                itemsType = nil
            }
        }
    }
}

extension Definition {
    func build() throws {
        let structSpecBuilder = TypeSpec.newStruct(name: name)
        let initSpec = MethodSpec.initBuilder()
        let outputDir = "output/"
        try properties.forEach { p in
            let isRequired: Bool = required?.contains(p.name) ?? false
            let type: String
            if p.type == "array", let itemsType = p.itemsType {
                type = "[\(itemsType)]"
            }
            else {
                type = p.type
            }
            let field = FieldSpecBuilder(name: p.name, fieldType: "\(type)\(isRequired ? "": "?")")
            if let const = p.const {
                _ = field.initWith(initializer: const)
            }
            else {
                _ = initSpec.addParam(ParameterSpec.init(p.name, paramType: "\(type)\(isRequired ? "": "?")", defaultValue: isRequired ? "" : "nil"))
            }
            _ = structSpecBuilder.addProperty(propertySpec: field.build())
                .addMethod(methodSpec: initSpec.build())
            
            let structSpec = try structSpecBuilder.build()
            
            let swiftFile = SwiftFile
                .newFile(name: name)
                .addType(structSpec)
                .build()
                .writeTo(outputDir)
        }
    }
}
