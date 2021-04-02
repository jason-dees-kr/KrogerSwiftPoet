//
//  MethodSpec.swift
//  SwiftPoet
//
//  Created by Jupiter on 9/14/16.
//  Copyright © 2016 Jupiter. All rights reserved.
//

import Foundation

public enum MethodType: String {
    case INIT = "init"
    case OPTIONAL_INIT = "init?"
    case SUBSCRIPT = "subscript"
    case NORMAL = "normal"
    case ABSTRACT = "abstract"
}

//For method
public class MethodSpec : SwiftComponentWriter {
    let methodType: MethodType
    let name:String
    let modifiers: [TypeModifier]
    let parameters: [ParameterSpec]?
    let returnType: String?
    let methodBlock: CodeBlock?
    let genericClause: String?
    let whereClause: String?
    let isErrorThrown: Bool
    
    init(_ methodType: MethodType, name: String, modifiers: [TypeModifier] = [], parameters: [ParameterSpec]? = nil,
         returnType: String? = nil, genericClause: String? = nil, whereClause: String? = nil, methodBlock: CodeBlock? = nil, isErrorThrown : Bool = false) {
        self.methodType = methodType
        self.name = name
        self.modifiers = modifiers
        self.parameters = parameters
        self.returnType = returnType
        self.methodBlock = methodBlock
        self.genericClause = genericClause
        self.whereClause = whereClause
        self.isErrorThrown = isErrorThrown
    }
    
    public static func methodBuilder(name: String) -> MethodSpecBuilder {
        return MethodSpecBuilder(MethodType.NORMAL, name: name)
    }
    
    public static func abstractMethodBuilder(name: String) -> MethodSpecBuilder {
        return MethodSpecBuilder(MethodType.ABSTRACT, name: name)
    }
    
    public static func initBuilder() -> MethodSpecBuilder {
        return MethodSpecBuilder(MethodType.INIT, name: "init")
    }
    
    public static func optionalInitBuilder() -> MethodSpecBuilder {
        return MethodSpecBuilder(MethodType.OPTIONAL_INIT, name: "init?")
    }
    
    public static func subscriptBuilder() -> MethodSpecBuilder {
        return MethodSpecBuilder(MethodType.SUBSCRIPT, name: "subscript")
    }
    
    func emit(codeWriter: CodeWriter) {
        _ = codeWriter.emitModifiers(modifiers)
        if (methodType == .NORMAL || methodType == .ABSTRACT) {
            _ = codeWriter.emit(code: "func \(name)")
        } else {
            _ = codeWriter.emit(code: methodType.rawValue)
        }
        if let genericClause = genericClause {
            _ = codeWriter.emit(code: "<\(genericClause)>")
        }
        
        _ = codeWriter.emit(code: "(")
        
        var delimeter = ""
        parameters?.forEach{ (param) in
            _ = codeWriter.emit(code: delimeter)
            param.emit(codeWriter: codeWriter)
            delimeter = ", "
        }
        
        _ = codeWriter.emit(code: ")")
        
        if (isErrorThrown) {
            _ = codeWriter.emit(code: " throws")
        }
        if let returnType = returnType {
            _ = codeWriter.emit(code: " -> \(returnType)")
        }
        if let whereClause = whereClause {
            _ = codeWriter.emit(code: " where \(whereClause)")
        }
        if (methodType != .ABSTRACT) {
            _ = codeWriter.emit(code: " {\n")
            if let methodBlock = methodBlock {
                _ = codeWriter.indent()
                methodBlock.emit(codeWriter: codeWriter)
                _ = codeWriter.unindent()
            }
            _ = codeWriter.emit(code: "}\n")
        }
    }
}

public class MethodSpecBuilder {
    let methodType: MethodType
    let name: String
    var returnType: String?
    var paramList: [ParameterSpec] = [ParameterSpec]()
    var modifiers = [TypeModifier]()
    var methodCode: CodeBlock?
    var genericTypeClause: String?
    var whereClause: String?
    var isErrorThrown = false
    
    init(_ methodType: MethodType = .NORMAL, name: String) {
        self.methodType = methodType
        self.name = name
    }
    
    public func returnType(_ returnType: String) -> MethodSpecBuilder {
        self.returnType = returnType
        return self
    }
    
    public func addParam(_ param: ParameterSpec) -> MethodSpecBuilder {
        paramList.append(param)
        return self
    }
    
    public func modifiers(_ modifiers: TypeModifier...) -> MethodSpecBuilder {
        self.modifiers.append(contentsOf: modifiers)
        return self
    }
    
    public func genericType(_ genericClause: String) -> MethodSpecBuilder {
        self.genericTypeClause = genericClause
        return self
    }
    
    public func whereClause(_ whereClause: String) -> MethodSpecBuilder {
        self.whereClause = whereClause
        return self
    }
    
    public func willThrowError() -> MethodSpecBuilder {
        self.isErrorThrown = true
        return self
    }
    
    public func code(_ codeString:String) -> MethodSpecBuilder {
        return self.code(CodeBlock.newCodeBlock(initialCode: codeString))
    }
    
    public func code(_ code: CodeBlock) -> MethodSpecBuilder {
        self.methodCode = code
        return self
    }
    
    public func build() -> MethodSpec {
        return MethodSpec(methodType, name: name, modifiers: modifiers,
                          parameters: paramList, returnType: returnType, genericClause: genericTypeClause, whereClause: whereClause, methodBlock: methodCode, isErrorThrown: isErrorThrown)
    }
}

public class ParameterSpec : SwiftComponentWriter {
    let name:String?
    let paramType: String
    let defaultValue: String?
    var argLabel: String?
    let isInOut: Bool
    
    public init(_ name:String?, paramType: String, defaultValue: String? = nil, argLabel: String? = nil, isInOut: Bool = false) {
        self.name = name
        self.paramType = paramType
        self.defaultValue = defaultValue
        if (argLabel == nil && name == nil) {
            self.argLabel = "_"
        } else {
            self.argLabel = argLabel
        }
        self.isInOut = isInOut
    }
    
    func emit(codeWriter: CodeWriter) {
        _ = codeWriter
            .emit(code: argLabel?.append(string: " ") ?? "")
            .emit(code: name ?? "")
            .emit(code: ":")
            .emit(code: isInOut ? " inout" : "")
            .emit(code: " \(paramType)")
        
        if let defaultValue = defaultValue {
            _ = codeWriter.emit(code: " = \(defaultValue)")
        }
    }
}
