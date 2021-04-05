//
//  SchemaSettings.swift
//  
//
//  Created by Jason Dees on 4/2/21.
//

import Foundation

public struct SchemaSettings {
    let schemaDirectory: String
    let manifestFile: String
    let outputDirectory: String
    
    init(parentDirectory: String,
         manifestFile: String,
         outputDirectory: String) {
        
        self.schemaDirectory = parentDirectory
        self.manifestFile = manifestFile
        self.outputDirectory = outputDirectory
        
    }
}
