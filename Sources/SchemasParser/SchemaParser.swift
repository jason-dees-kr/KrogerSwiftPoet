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
        let swiftFileBuilders = try definitionBuilder.buildDefinitions(definitions: try ManifestReader(settings: settings).schemaDefinitions)
        swiftFileBuilders.forEach {file in
            _ = file.build().writeTo(settings.outputDirectory)
        }
    }
}

public struct DefinitionsBuilder {
    func buildDefinitions(definitions: [String: Any]) throws -> [SwiftFileBuilder]{
        return try definitions.compactMap {(name, def) in
            guard def is [String: Any] else { return nil }
            let cast = def as! [String: Any]
            let propDict = cast["properties"] as! [String:Any]
            let properties:[Definition.Property] = propDict.map { (key, value) in .init(key: key, value: value as! [String : Any])}
            let definition = Definition(name: .Object(name), properties: properties, required: cast["required"] as? [String], description: cast["description"] as? String)
            return try definition.build()
        }
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

public struct Definition {
    let name: DefinitionType
    let properties: [Property]
    let required: [String]?
    let description: String?
    
    public struct Property {
        let name: String
        let description: String?
        let type: DefinitionType
        let enumValues: [String]?
        let const: String?
        
        //        let pattern: String? = nil
        //        let minItems: Int? = nil
        //        let maxItems: Int? = nil
        
        init(key: String, value:[String: Any]) {
            name = key
            if let ref = value["$ref"] as? String {
                let fileSplit = ref.split(separator: "/")
                let defName = fileSplit[fileSplit.count - 2]
                type = DefinitionType.toDefinitionType(type: String(defName))
            }
            else if let _ = value["enum"] as? [String] {
                type = DefinitionType.toDefinitionType(type: name)
            }
            else if let typeValue = value["type"] as? String {
                if typeValue == "array", let items = value["items"] as? [String: Any] {
                    if let ref = items["$ref"] as? String {
                        let fileSplit = ref.split(separator: "/")
                        let defName = fileSplit[fileSplit.count - 2]
                        type = .Array(DefinitionType.toDefinitionType(type: String(defName)))
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
}

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
    
    func build() throws -> SwiftFileBuilder {
        let structSpecBuilder = TypeSpec.newStruct(name: name.typeAsString)
        let initSpec = MethodSpec.initBuilder()
            .modifiers(.PUBLIC)
        
        try properties.forEach { p in
            let isRequired: Bool = required?.contains(p.name) ?? false
            let type: String = p.type.typeAsString
            
            let field = FieldSpecBuilder(name: p.name, fieldType: "\(type)\(isRequired ? "": "?")")
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
                if isRequired {
                    _ = initSpec.addParam(ParameterSpec.init(p.name, paramType: "\(type)\(isRequired ? "": "?")"))
                }
                else {
                    _ = initSpec.addParam(ParameterSpec.init(p.name, paramType: "\(type)\(isRequired ? "": "?")", defaultValue: "nil"))
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
