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
        let definitions = try definitionBuilder.buildDefinitionsDictionary(definitions: try ManifestReader(settings: settings).schemaDefinitions)
        
        try definitions.forEach {name, definition in
            _ = try definition.toSwiftFileBuilder().build().writeTo(settings.outputDirectory)
        }
    }
}

public struct DefinitionsBuilder {
    
    func buildDefinition(name: String, cast: [String : Any]) -> Definition {
        let propDict = cast["properties"] as! [String : Any]
        let required = cast["required"] as? [String]
        let allOf = cast["allOf"] as? [Any]
        
        let properties : [Definition.Property] = propDict.map { (key, value) in .init(key: key, value: value as! [String : Any], required: required?.contains(key) ?? false)}
        
        let definition = Definition(name: .Object(name),
                                    properties: properties,
                                    required: required,
                                    allOf: allOf,
                                    description: cast["description"] as? String)
        
        return definition
    }
    
    func buildDefinitionsDictionary(definitions: [String: Any]) throws -> [String: Definition] {
        let defintionsDictionary : [String: Definition] =  Dictionary(uniqueKeysWithValues: definitions.compactMap { key, value in
            guard let cast = value as? [String : Any] else { return nil }
            return (key, buildDefinition(name: key, cast: cast))
        })
        // This entirely sucks
        // Wait until All the definitions are hydrated, go through each definition
        // to see if it has any inherited properties.
        // addInheritedObjects function recursively goes through each object,
        // grabbing the inherited refs and building out an heritance list. This
        // then constructs a new Defintion object based on the current defintion
        // and inherited defition
        return Dictionary(uniqueKeysWithValues: defintionsDictionary.map { (key, value) in
            if value.hasAllOfRef {
                return (key, value.addInheritedObjects(definitions: defintionsDictionary))
            }
            return (key, value)
        })
    }
    
    func buildDefinitions(definitions: [String: Any]) throws -> [Definition]{
        return definitions.compactMap {(name, def) in
            guard let cast = def as? [String : Any] else { return nil }
            return buildDefinition(name: name, cast: cast)
        }
    }
}

public struct Definition {
    let name: DefinitionType
    var properties: [Property]
    let required: [String]?
    let allOf: [Any]?
    let description: String?
    
    public struct Property {
        let name: String
        let description: String?
        let type: DefinitionType
        let enumValues: [String]?
        let const: String?
        let required: Bool
        
        //        let pattern: String? = nil
        //        let minItems: Int? = nil
        //        let maxItems: Int? = nil
        
        init(key: String, value:[String: Any], required: Bool) {
            name = key
            if let ref = value["$ref"] as? String {
                type = DefinitionType.toDefinitionType(type: String(ref.refStringToTypeString()))
            }
            else if let _ = value["enum"] as? [String] {
                type = DefinitionType.toDefinitionType(type: name)
            }
            else if let typeValue = value["type"] as? String {
                if typeValue == "array", let items = value["items"] as? [String: Any] {
                    if let ref = items["$ref"] as? String {
                        type = .Array(DefinitionType.toDefinitionType(type: String(ref.refStringToTypeString())))
                    }
                    else{
                        type = .Array(DefinitionType.toDefinitionType(type: typeValue))
                    }
                }
                else {
                    type = DefinitionType.toDefinitionType(type: typeValue)
                }
            }
            else {
                type = .String
            }
            description = value["description"] as? String
            enumValues = value["enum"] as? [String]
            const = value["const"] as? String
            self.required = required
        }
    }
}

// MARK: `Inheritance` Construction
extension Definition {
    var refs: [String] {
        guard let allOf = self.allOf else { return [] }
        return  allOf.compactMap { entry in
            guard let entry = entry as? [String: String], let refValue = entry["$ref"] else { return nil }
            return refValue.refStringToTypeString()
        }
    }
    
    var hasAllOfRef: Bool {
        return !refs.isEmpty;
    }
    
    func getRefs(definitions: [String: Definition]) -> [Definition] {
        var refDefinitions: [Definition] = []
        // Recursively cycle through each inherited object to build out inheritance object list
        
        // This is also wrong since it doens't take into account the VERSION of the reference vs the version of the manifest.
        // Ideally they are both the same version, but I guess we could conceivably have a SubmitOrderProduct referencing Product 1.0.2
        // and a ProductViewProduct referencing 1.0.5
        // Not sure how else to do it, maybe only do a manifest for Scenarios + MetaData and determine Definitions to load from there
        // Operating under the assumption that we will never have version conflicts like that
        refs.compactMap { definitions[$0] }.forEach { def in
            refDefinitions.append(def)
            refDefinitions.append(contentsOf: def.getRefs(definitions: definitions))
        }
        return refDefinitions
    }
    
    func addInheritedObjects(definitions: [String: Definition]) -> Definition {
        let inheritedObjects = getRefs(definitions: definitions)
        let inheritedProperties = inheritedObjects.flatMap { $0.properties }
        let inheritedAllOf = inheritedObjects.compactMap { $0.allOf }
        return Definition(name: name,
                          properties: inheritedProperties + properties,
                          required: required,
                          allOf: allOf ?? [] + inheritedAllOf,
                          description: description)
    }
}

// MARK: TypeSpec Building
extension Definition {
    func buildEnum(_ name: DefinitionType, values: [String]) throws -> TypeSpecBuilder{
        let enumType = TypeSpec.newEnum(name: name.typeAsString)
            .superClass(superClass: "String", "Encodable", "Equatable")
            .modifier(modifiers: .PUBLIC)
        values.forEach { value in
            let enumConstantSpec = EnumConstantSpec.newEnumValue(name: value.toVariableCamelCase()).value(value: "\"\(value)\"")
            _ = enumType.addEnumConstant(enumConstant: enumConstantSpec.build())
            
        }
        return enumType
    }
    
    func toSwiftFileBuilder() throws -> SwiftFileBuilder {
        let structSpecBuilder = TypeSpec.newStruct(name: name.typeAsString)
            .superClass(superClass: "Validatable")
        let initSpec = MethodSpec.initBuilder()
            .modifiers(.PUBLIC)
        
        try properties.sorted { (f, s) in f.required }.forEach { p in
            let type: String = p.type.typeAsString
            
            let field = FieldSpecBuilder(name: p.name, fieldType: "\(type)\(p.required ? "": "?")")
                .addModifier(fieldModifiers: .PUBLIC)
            if let enums = p.enumValues {
                _ = try structSpecBuilder.addInnerType(typeSpec: buildEnum(p.type, values: enums).build())
            }
            if let const = p.const {
                switch p.type {
                case .Int, .Double:
                    _ = field.initWith(initializer: const)
                default:
                    _ = field.initWith(initializer: "\"\(const)\"")
                }
            }
            else {
                if p.required {
                    _ = initSpec.addParam(ParameterSpec.init(p.name, paramType: "\(type)"))
                }
                else {
                    _ = initSpec.addParam(ParameterSpec.init(p.name, paramType: "\(type)?", defaultValue: "nil"))
                }
            }
            _ = structSpecBuilder.addProperty(propertySpec: field.build())
        }
        
        let structSpec = try structSpecBuilder.addMethod(methodSpec: initSpec.build())
            .modifier(modifiers: .PUBLIC)
            .build()
        
        return SwiftFile
            .newFile(name: name.typeAsString)
            .addType(structSpec)
    }
}

public indirect enum DefinitionType {
    case Int
    case String
    case Double
    case Boolean
    case Object(String)
    case Array(DefinitionType)
    
    public var typeAsString: String {
        switch self {
        case .Int:
            return "Int"
        case .String:
            return "String"
        case .Double:
            return "Double"
        case .Boolean:
            return "Bool"
        case .Object(let customType):
            return customType.toTypedCamelCase()
        case .Array(let innerType):
            return "[\(innerType.typeAsString)]"
        }
    }
    
    public static func toDefinitionType(type: String) -> DefinitionType {
        switch type.lowercased() {
        case "string":
            return .String
        case "integer":
            return .Int
        case "number":
            return .Double
        case "boolean":
            return .Boolean
        default:
            return .Object(type)
        }
    }
}


extension String {
    func toTypedCamelCase() -> String {
        if self.contains("-") || self.contains(" ") {
            return self.replacingOccurrences(of: "-", with: " ").capitalized.replacingOccurrences(of: " ", with: "")
        }
        return String(self.prefix(1).capitalized) + String(self.dropFirst())
    }
    
    func toVariableCamelCase() -> String {
        return String(self.prefix(1)) + String(self.toTypedCamelCase().dropFirst())
    }
    
    func refStringToTypeString() -> String {
        let fileSplit = self.split(separator: "/")
        return String(fileSplit[fileSplit.count - 2])
    }
}
