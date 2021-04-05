//
//  FieldSpec.swift
//  SwiftPoet
//
//  Created by Jupiter on 9/13/16.
//  Copyright © 2016 Jupiter. All rights reserved.
//

import Foundation

public class VariableSpec : SwiftComponentWriter {
    public let name: String
    
    let fieldType:String?
    let initializer: CodeBlock?
    let modifiers:[FieldModifier]
    var canBeModified: Bool
    let initCodeBlock : [String: CodeBlock?]?
    let comments: [String]
    
    init(name:String, fieldType:String? = nil, initializer:CodeBlock? = nil, modifiers:[FieldModifier] = [], canBeModified:Bool = false,
         initBlock: [String: CodeBlock?]? = nil, comments: [String] = []) {
        self.name = name
        self.fieldType = fieldType
        self.initializer = initializer
        self.modifiers = modifiers
        self.canBeModified = canBeModified
        self.initCodeBlock = initBlock
        self.comments = comments
    }
    
    func emit(codeWriter: CodeWriter) {
        let codeWriter = codeWriter
        comments.forEach { comment in
            _ = codeWriter.emit(code: "/// \(comment)\n")
        }
        _ = codeWriter.emitModifiers(modifiers)
            .emit(code: canBeModified ? "var " : "let ")
            .emit(code: name)
            .emit(code: fieldType?.prepend(string: ": ") ?? "")
        if let initializer = initializer {
            _ = codeWriter
                .emit(code: " = ")
                .emit(codeBlock: initializer)
            
        }
        if !(initCodeBlock?.isEmpty ?? true) {
            _ = codeWriter.emit(code: " {\n")
            initCodeBlock?.forEach({ (string, codeBlock) in
                _ = codeWriter.emit(code: string)
                if let codeBlock = codeBlock {
                    _ = codeWriter.emit(code: " {\n")
                        .emit(codeBlock: codeBlock)
                        .emit(code: "\n}\n")
                }
            })
            _ = codeWriter.emit(code: "}")
        }
    }
}

public class FieldSpecBuilder {
    let name: String
    let fieldType: String?
    var initializer: CodeBlock?
    var modifiers = [FieldModifier]()
    var canBeModified = false
    var initCodeBlock = [String: CodeBlock?]()
    var comments = [String]()
    
    public init(name:String, fieldType: String? = nil) {
        self.name = name
        self.fieldType = fieldType
    }
    
    public func initWith(initializer: CodeBlock?) -> FieldSpecBuilder {
        self.initializer = initializer
        return self
    }
    
    public func initWith(initializer: String?) -> FieldSpecBuilder {
        self.initializer = CodeBlock.newCodeBlock(initialCode: initializer)
        return self
    }
    
    public func modifiable() -> FieldSpecBuilder {
        self.canBeModified = true
        return self
    }
    
    public func addModifier(fieldModifiers: FieldModifier...) -> FieldSpecBuilder {
        self.modifiers.append(contentsOf: fieldModifiers)
        return self
    }
    
    public func getter(codeBlock: CodeBlock?) -> FieldSpecBuilder {
        initCodeBlock["get"] = codeBlock
        return self
    }
    
    public func setter(varName: String? = nil, codeBlock: CodeBlock?) -> FieldSpecBuilder {
        _ = initCodeBlock["set".append(string: varName != nil ? "(\(String(describing: varName)))" : "")] = codeBlock
        return self
    }
    
    public func willSet(varName: String? = nil, codeBlock: CodeBlock?) -> FieldSpecBuilder {
        _ = initCodeBlock["willSet".append(string: varName != nil ? "(\(String(describing: varName)))" : "")] = codeBlock
        return self
    }
    
    public func didSet(codeBlock: CodeBlock) -> FieldSpecBuilder {
        initCodeBlock["didSet"] = codeBlock
        return self
    }
    
    public func comment(comments: String...) -> FieldSpecBuilder {
        self.comments.append(contentsOf: comments)
        return self
    }
    
    public func build() -> VariableSpec {
        return VariableSpec(name: name, fieldType: fieldType, initializer: initializer,modifiers: modifiers, canBeModified: canBeModified, initBlock: initCodeBlock, comments: comments)
    }
    
}

