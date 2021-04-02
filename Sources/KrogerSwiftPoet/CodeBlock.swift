//
//  CodeBlock.swift
//  SwiftPoet
//
//  Created by Jupiter on 9/20/16.
//  Copyright © 2016 Jupiter. All rights reserved.
//

import Foundation
//For codeblock, closure
public class CodeBlock : SwiftComponentWriter {
    var codeStatements = [String]()
    
    private init(initialCode: String? = nil) {
        if let initialCode = initialCode {
            codeStatements.append(initialCode)
        }
    }
    
    public func statement(_ statement: String) -> CodeBlock {
        addStatement(statement + "\n")
        return self
    }
    
    public func block(_ codeBlock: CodeBlock) -> CodeBlock {
        addStatements(codeBlock.codeStatements)
        return self
    }
    
    public func beginControlFlow(_ statement: String) -> CodeBlock {
        addStatement("\(statement) {\n")
        indent()
        return self
    }
    
    public func nextControlFlow(_ statement: String) -> CodeBlock {
        unindent()
        addStatement("} \(statement) {\n")
        indent()
        return self
    }
    
    public func endControlFlow(_ statement: String? = nil) -> CodeBlock {
        unindent()
        addStatement("\(statement ?? "}")\n")
        return self
    }
    
    private func indent() {
        addStatement("$>$")
    }
    
    private func unindent() {
        addStatement("$<$")
    }
    
    fileprivate func addStatements(_ statementList: [String]) {
        codeStatements.append(contentsOf: statementList)
    }
    
    fileprivate func addStatement(_ statements: String...) {
        self.addStatements(statements)
    }
    
    func emit(codeWriter: CodeWriter) {
        codeStatements.forEach { (statement) in
            switch (statement) {
            case "$>$":
                _ = codeWriter.indent()
            case "$<$":
                _ = codeWriter.unindent()
            default:
                _ = codeWriter.emit(code: statement)
            }
        }
    }
    
    public static func newCodeBlock(initialCode: String? = nil, initCode: (inout CodeBlock) -> ()) -> CodeBlock {
        var codeBlock = CodeBlock(initialCode: initialCode)
        initCode(&codeBlock)
        return codeBlock
    }
    
    public static func newCodeBlock(initialCode: String? = nil) -> CodeBlock {
        return CodeBlock(initialCode: initialCode)
    }
}

func +(left:CodeBlock, statement: String) -> CodeBlock {
    left.addStatement(statement)
    return left
}

func +=( left:inout CodeBlock, statement: String) {
    left.addStatement(statement)
}

func +(left:CodeBlock, right:CodeBlock) -> CodeBlock {
    _ = left.block(right)
    return left
}

precedencegroup Faketive { associativity: left
    higherThan: AdditionPrecedence
}

infix operator -|: Faketive
infix operator |-: Faketive

func -| (left: CodeBlock, beginFlowString: String) -> CodeBlock {
    _ = left.beginControlFlow(beginFlowString)
    return left
}

func |- (left: CodeBlock, endFlowString: String) -> CodeBlock {
    _ = left.endControlFlow(endFlowString)
    return left
}

//let newBlock = CodeBlock.newCodeBlock { a in
//    a = a
//        +  "let a = \"abc\""
//        +  "let b = 'abc'"
//        -| "for abc in 0..1"
//        -| ""
//        +  ""
//        +  "left"
//}
