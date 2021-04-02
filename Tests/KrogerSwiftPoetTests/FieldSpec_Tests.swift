//
//  FieldSpecTest.swift
//  SwiftPoet
//
//  Created by Jupiter on 9/14/16.
//  Copyright © 2016 Jupiter. All rights reserved.
//

import XCTest
@testable import KrogerSwiftPoet

class FieldSpec_Tests: XCTestCase {
  let outputStream = StringOutputStream()
  var codeWriter: CodeWriter {
    get {
      return CodeWriter(outputStream: outputStream)
    }
  }
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func test_shouldEmitVarIfModifiable() {
    let fieldSpec = FieldSpecBuilder(name: "field")
                      .modifiable()
        .addModifier(fieldModifiers: FieldModifier.PRIVATE)
                      .build()
    fieldSpec.emit(codeWriter: codeWriter)
    XCTAssertEqual(outputStream.toString(), "private var field")
    
  }
  
  func test_shouldEmitLetIfNotModifiable() {
    let fieldSpec = FieldSpecBuilder(name: "field")
        .initWith(initializer: "1")
        .addModifier(fieldModifiers: FieldModifier.PRIVATE)
      .build()
    fieldSpec.emit(codeWriter: codeWriter)
    XCTAssertEqual(outputStream.toString(), "private let field = 1")
  }
  
  func test_shouldEmitInitBlock() {
    let fieldSpec = FieldSpecBuilder(name: "field", fieldType: "Int")
        .getter(codeBlock: CodeBlock.newCodeBlock(initialCode: "return 0"))
      .build()
    fieldSpec.emit(codeWriter: codeWriter)
    XCTAssertEqual(outputStream.toString(), "let field: Int {\nget {\nreturn 0\n}\n}")
  }
  
  func test_shouldEmitModifiersInOrder() {
    let fieldSpec = FieldSpecBuilder(name: "field")
        .addModifier(fieldModifiers: FieldModifier.PRIVATE, FieldModifier.LAZY, FieldModifier.DYNAMIC)
      .build()
    fieldSpec.emit(codeWriter: codeWriter)
    XCTAssertEqual(outputStream.toString(), "private lazy dynamic let field")
  }
  
}
