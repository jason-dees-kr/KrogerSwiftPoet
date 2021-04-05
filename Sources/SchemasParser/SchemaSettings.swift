//
//  File.swift
//  
//
//  Created by Jason Dees on 4/2/21.
//

import Foundation

public struct SchemaSettings {
    let parentDirectory: String
    let manifestFile: String
    let outputDirectory: String
    
    init(parentDirectory: String = "https://gitlab.kroger.com/kat/schema-registry/-/raw/master/schemas",
         manifestFile: String = "https://gitlab.kroger.com/kat/schema-registry/-/raw/master/consumers/sdk-banner-ios/latest/sdk-banner-ios.json",
         outputDirectory: String = "/Users/jd26163/Desktop/output") {
        
        self.parentDirectory = parentDirectory
        self.manifestFile = manifestFile
        self.outputDirectory = outputDirectory
        
    }
}
