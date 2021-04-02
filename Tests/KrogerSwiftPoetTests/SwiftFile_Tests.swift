//
//  SwiftFile_Tests.swift
//  SwiftPoet
//
//  Created by Jupiter on 9/16/16.
//  Copyright © 2016 Jupiter. All rights reserved.
//

import XCTest
@testable import Kroger_Swift_Poet

class SwiftFile_Tests: XCTestCase {
    let testOutputDir = "test_results/"
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func test_shouldEmitSimpleClass() {
        let classSpec = try? TypeSpec.newClass(name: "TestClass")
            .addProperty(propertySpec: FieldSpecBuilder(name: "field01", fieldType: "Int").initWith(initializer: "1").build())
            .addProperty(propertySpec: FieldSpecBuilder(name: "field02", fieldType: "String").initWith(initializer: "\"abc\"").build())
            .addProperty(propertySpec: FieldSpecBuilder(name: "field03").modifiable().initWith(initializer: "\"abc\"").build())
            .addMethod(methodSpec: MethodSpec.initBuilder().addParam(ParameterSpec("name", paramType: "String")).build())
            .build()
        
        let swiftFile = SwiftFile
            .newSingleClass(name: "sample_class01_output", classSpec: classSpec!)
            .build()
            .writeTo(testOutputDir)
        
        XCTAssertTrue(isSourceFileEqual(path1: getResourceFilePath(fileName: "sample_class01")!, path2: swiftFile!))
    }
    
    func test_shouldEmitClassWithMethod() {
        let classSpecBuilder = TypeSpec.newClass(name: "TestClass")
            .addProperty(propertySpec: FieldSpecBuilder(name: "field01", fieldType: "Int").initWith(initializer: "1").build())
            .addProperty(propertySpec: FieldSpecBuilder(name: "field02", fieldType: "String").initWith(initializer: "\"abc\"").build())
            .addProperty(propertySpec: FieldSpecBuilder(name: "field03").modifiable().initWith(initializer: "\"abc\"").build())
            .addMethod(methodSpec: MethodSpec.initBuilder().addParam(ParameterSpec("name", paramType: "String")).build())
            .addMethod(methodSpec: MethodSpec.methodBuilder(name: "testFunc").build())
            .superClass(superClass: "SuperClass")
        let codeBlock = CodeBlock.newCodeBlock() { codeBlock in
            _ = codeBlock.beginControlFlow("if (param == \"test\")")
                .statement("return 123")
                .nextControlFlow("else")
                .statement("return 456")
                .endControlFlow()
        }
        let method = MethodSpec.methodBuilder(name: "testFunc1")
            .addParam(ParameterSpec("param", paramType: "String"))
            .returnType("Int")
            .code(codeBlock)
            .build()
        _ = classSpecBuilder.addMethod(methodSpec: method)
        let methodWithCode = MethodSpec.methodBuilder(name: "testFunc2")
            .addParam(ParameterSpec("param", paramType: "String", defaultValue: "\"abc\""))
            .addParam(ParameterSpec("param2", paramType: "Int", isInOut: true))
            .code("print(\"abc\")\n")
            .build()
        
        _ = classSpecBuilder.addMethod(methodSpec: methodWithCode)
        let classSpec = try? classSpecBuilder.build()
        let swiftFile = SwiftFile
            .newSingleClass(name: "sample_class02_output", classSpec: classSpec!)
            .build()
            .writeTo(testOutputDir)
        
        XCTAssertTrue(isSourceFileEqual(path1: getResourceFilePath(fileName: "sample_class02")!, path2: swiftFile!))
        
    }
    
    func test_shouldEmitGenericMethodAndClass() {
        let genericMethod = MethodSpec
            .methodBuilder(name: "findIndex")
            .genericType("T")
            .addParam(ParameterSpec("valueToFind", paramType: "T", argLabel: "of"))
            .addParam(ParameterSpec("array", paramType: "[T]", argLabel: "in"))
            .returnType("Int?")
            .code("return nil\n")
            .build()
        let pushMethod = MethodSpec
            .methodBuilder(name: "push")
            .modifiers(TypeModifier.MUTATING)
            .addParam(ParameterSpec("item", paramType: "Element", argLabel: "_"))
            .code("items.append(item)\n")
            .build()
        
        let popMethod = MethodSpec
            .methodBuilder(name: "pop")
            .modifiers(TypeModifier.MUTATING)
            .returnType("Element")
            .code("return items.removeLast()\n")
            .build()
        
        let genericStruct = try? TypeSpec.newStruct(name: "Stack")
            .genericClause(genericClause: "Element")
            .addProperty(propertySpec: FieldSpecBuilder(name: "items").modifiable().initWith(initializer: "[Element]()").build())
            .addMethod(methodSpec: pushMethod)
            .addMethod(methodSpec: popMethod)
            .build()
        
        let swiftFile = SwiftFile
            .newFile(name: "sample_class03_output")
            .addMethod(method: genericMethod)
            .addType(genericStruct!)
            .build()
            .writeTo(testOutputDir)
        
        XCTAssertTrue(isSourceFileEqual(path1: getResourceFilePath(fileName: "sample_class03")!, path2: swiftFile!))
    }
    
    func test_shouldEmitProtocol() {
        let classSpec = try? TypeSpec.newProtocol(name: "TestProtocol")
            .addMethod(methodSpec: MethodSpec.abstractMethodBuilder(name: "testProtocolFunc").build())
            .addMethod(methodSpec: MethodSpec.abstractMethodBuilder(name: "testProtocolFunc").addParam(ParameterSpec("value", paramType: "Int")).build())
            .addMethod(methodSpec: MethodSpec.abstractMethodBuilder(name: "testProtocolFunc").addParam(ParameterSpec("value", paramType: "String", defaultValue: "\"abc\"")).build())
            .build()
        
        let swiftFile = SwiftFile.newSingleClass(name: "sample_protocol01_output", classSpec: classSpec!)
            .build().writeTo(testOutputDir)
        
        XCTAssertTrue(isSourceFileEqual(path1: getResourceFilePath(fileName: "sample_protocol01")!, path2: swiftFile!))
    }
    
    func test_shouldEmitProtocolWithSuper() {
        do {
            let classSpec = try TypeSpec.newProtocol(name: "TestProtocol")
                .superClass(superClass: "SuperTestProtocol", "SuperTestProtocol2")
                .addMethod(methodSpec: MethodSpec.abstractMethodBuilder(name: "testProtocolFunc").build())
                .addMethod(methodSpec: MethodSpec.abstractMethodBuilder(name: "testProtocolFunc").addParam(ParameterSpec("value", paramType: "Int")).build())
                .addMethod(methodSpec: MethodSpec.abstractMethodBuilder(name: "testProtocolFunc").addParam(ParameterSpec("value", paramType: "String", defaultValue: "\"abc\"")).build())
                .build()
            let swiftFile = SwiftFile.newSingleClass(name: "sample_protocol02_output", classSpec: classSpec)
                .build().writeTo(testOutputDir)
            
            XCTAssertTrue(isSourceFileEqual(path1: getResourceFilePath(fileName: "sample_protocol02")!, path2: swiftFile!))
        } catch let error {
            print(error)
        }
        
    }
    
    func test_shouldEmitExtension() {
        do {
            let method = MethodSpec
                .methodBuilder(name: "prepend")
                .modifiers(TypeModifier.PUBLIC)
                .addParam(ParameterSpec("string", paramType: "String"))
                .code(CodeBlock.newCodeBlock(initialCode: "return string + self\n"))
                .returnType("String")
                .build()
            
            let method2 = MethodSpec
                .methodBuilder(name: "append")
                .modifiers(TypeModifier.PUBLIC)
                .addParam(ParameterSpec("string", paramType: "String"))
                .code(CodeBlock.newCodeBlock(initialCode: "return self + string\n"))
                .returnType("String")
                .build()
            
            let classSpec = try TypeSpec.newExtension(ofType: "String")
                .addMethod(methodSpec: method)
                .addMethod(methodSpec: method2)
                .build()
            
            let operatorMethod = MethodSpec.methodBuilder(name: "*")
                .addParam(ParameterSpec("left", paramType: "String"))
                .addParam(ParameterSpec("right", paramType: "Int"))
                .returnType("String")
                .code(CodeBlock.newCodeBlock() { codeBlock in
                    _ = codeBlock.beginControlFlow("if right <= 0")
                        .statement("return \"\"")
                        .endControlFlow()
                        .statement("var result = left")
                        .beginControlFlow("for _ in 1..<right")
                        .statement("result += left")
                        .endControlFlow()
                        .statement("return result")
                })
                .build()
            let swiftFile = SwiftFile
                .newFile(name: "sample_extension01_output")
                .addType(classSpec)
                .addMethod(method: operatorMethod)
                .build()
                .writeTo(testOutputDir)
            
            XCTAssertTrue(isSourceFileEqual(path1: getResourceFilePath(fileName: "sample_extension01")!, path2: swiftFile!))
        } catch let error {
            print(error)
        }
        
    }
    
    func test_shouldEmitSimpleEnum() {
        do {
            let classSpec = try TypeSpec.newEnum(name: "CompassPoint")
                .superClass(superClass: "Int")
                .addEnumConstant(enumConstant: EnumConstantSpec.newEnumValue(name: "north").value(value: "1").build())
                .addEnumConstant(enumConstant: EnumConstantSpec.newEnumValue(name: "south").build())
                .addEnumConstant(enumConstant: EnumConstantSpec.newEnumValue(name: "east").build())
                .addEnumConstant(enumConstant: EnumConstantSpec.newEnumValue(name: "west").build())
                .build()
            let swiftFile = SwiftFile.newSingleClass(name: "sample_enum01_output", classSpec: classSpec)
                .build().writeTo(testOutputDir)
            
            XCTAssertTrue(isSourceFileEqual(path1: getResourceFilePath(fileName: "sample_enum01")!, path2: swiftFile!))
        } catch let error {
            print(error)
        }
        
    }
    
    func test_shouldEmitEnumWithTuple() {
        do {
            let enumConstant = EnumConstantSpec.newEnumValue(name: "upc")
                .addTuple(tupleSpec: EnumTupleSpec(type: "Int"))
                .addTuple(tupleSpec: EnumTupleSpec(type: "Int"))
                .addTuple(tupleSpec: EnumTupleSpec(type: "Int"))
                .addTuple(tupleSpec: EnumTupleSpec(type: "Int"))
                .build()
            let classSpec = try TypeSpec.newEnum(name: "Barcode")
                .addEnumConstant(enumConstant: enumConstant)
                .addEnumConstant(enumConstant: EnumConstantSpec.newEnumValue(name: "qrCode").addTuple(tupleSpec: EnumTupleSpec(name: "code", type: "String")).build())
                .build()
            let swiftFile = SwiftFile.newSingleClass(name: "sample_enum02_output", classSpec: classSpec)
                .build().writeTo(testOutputDir)
            
            XCTAssertTrue(isSourceFileEqual(path1: getResourceFilePath(fileName: "sample_enum02")!, path2: swiftFile!))
        } catch let error {
            print(error)
        }
        
    }
    
    
    func isSourceFileEqual(path1: String, path2: String) -> Bool {
        if let aStreamReader = StreamReader(path: path1), let aStreamReader2 = StreamReader(path: path2) {
            defer {
                aStreamReader.close()
            }
            var lineNo = 1
            while let line = aStreamReader.nextLine() {
                if let similarLine = aStreamReader2.nextLine() {
                    if (line.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                            != similarLine.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)) {
                        print("assert fail at line:\(lineNo)\n-->\(line)\n-->\(similarLine)")
                        return false
                    }
                } else {
                    return false
                }
                lineNo = lineNo + 1
            }
        } else {
            return false
        }
        return true
    }
    
    private func getResourceFilePath(fileName: String) -> String? {
        //return Bundle.init(for: SwiftFile_Tests.self).path(forResource: fileName, ofType: "txt")
        return Bundle.module.url(forResource: fileName, withExtension: "txt")?.path

    }
    
    
    
}
