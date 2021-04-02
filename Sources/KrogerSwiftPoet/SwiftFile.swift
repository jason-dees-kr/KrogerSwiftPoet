//
//  SwiftFile.swift
//  SwiftPoet
//
//  Created by Jupiter on 8/22/16.
//  Copyright © 2016 Jupiter. All rights reserved.
//

import Foundation

protocol PoetOutputStream {
  func write(text: String)
}

public class FileOutputStream : PoetOutputStream {
    let fileOutputStream: OutputStream
    init(outputStream: OutputStream) {
        self.fileOutputStream = outputStream
    }
    
    func write(text: String) {
        fileOutputStream.write(text, maxLength: text.lengthOfBytes(using: String.Encoding.utf8))
    }
}

public class StringOutputStream : PoetOutputStream {
    var fileContent = ""
    func write(text: String) {
        fileContent += text
    }
    
    func toString() -> String {
        return fileContent
    }
}

public class SwiftFile {
    let fileName: String
    var fileComment: String = ""
    var imports = [String]()
    let components: [SwiftComponentWriter]
    
    init(fileName: String, importList: [String] = [], components: [SwiftComponentWriter] = []) {
        self.fileName = fileName
        self.imports = importList
        self.components = components
    }
    
    public func writeTo(_ directory: String) -> String? {
        let outputFilePath = NSURL.fileURL(withPathComponents: [directory, fileName])
        if let outputFilePath = outputFilePath {
            var isDir: ObjCBool = false
            let fm = FileManager()
            if !fm.fileExists(atPath: directory, isDirectory: &isDir) {
                try! fm.createDirectory(atPath: directory, withIntermediateDirectories: false, attributes: nil)
            }
            fm.createFile(atPath: outputFilePath.path, contents: nil, attributes: nil)
            
            let outputStream = OutputStream(toFileAtPath: outputFilePath.path, append: false)!
            outputStream.open()
            let codeWriter = CodeWriter(outputStream: FileOutputStream(outputStream: outputStream))
            emit(codeWriter)
            outputStream.close()
        }
        return outputFilePath?.path ?? nil
    }
    
    private func emit(_ codeWriter: CodeWriter) {
        imports.forEach { (importType) in
            _ = codeWriter.emit(code: "import \(importType)")
        }
        
        components.forEach { (component) in
            component.emit(codeWriter: codeWriter)
            if !(component is VariableSpec) {
                _ = codeWriter.emit(code: "\n")
            }
        }
    }
    
    public static func newSingleClass(name: String, classSpec: TypeSpec) -> SwiftFileBuilder {
        return SwiftFileBuilder(fileName: name).addType(classSpec)
    }
    
    public static func newFile(name: String) -> SwiftFileBuilder {
        return SwiftFileBuilder(fileName: name)
    }
}

public class SwiftFileBuilder {
    let fileName: String
    var fileComponents = [SwiftComponentWriter]()
    var importList = [String]()
    
    public init(fileName: String) {
        self.fileName = fileName + ".swift"
    }
    
    public func addProperty(property: VariableSpec) -> SwiftFileBuilder {
        addComponent(property)
        return self
    }
    
    public func addMethod(method: MethodSpec) -> SwiftFileBuilder {
        addComponent(method)
        return self
    }
    
    public func addType(_ type: TypeSpec) -> SwiftFileBuilder {
        addComponent(type)
        return self
    }
    
    public func addImport(importType: String) -> SwiftFileBuilder {
        importList.append(importType)
        return self
    }
    
    public func addCodeBlock(codeBlock: CodeBlock) -> SwiftFileBuilder {
        addComponent(codeBlock)
        return self
    }
    
    private func addComponent(_ component: SwiftComponentWriter) {
        fileComponents.append(component)
    }
    
    public func build() -> SwiftFile {
        return SwiftFile(fileName: fileName, importList: importList, components: fileComponents)
    }
    
}













