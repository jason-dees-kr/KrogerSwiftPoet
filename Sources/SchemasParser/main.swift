//
//  main.swift
//  
//
//  Created by Jason Dees on 4/2/21.
//
//

import ArgumentParser

public struct SchemaParser: ParsableCommand {
    //"https://gitlab.kroger.com/kat/schema-registry/-/raw/master/schemas"
    @Argument(help: "Parent directory where schemas are stored") var schemaDir: String
    //"https://gitlab.kroger.com/kat/schema-registry/-/raw/master/consumers/sdk-banner-ios/latest/sdk-banner-ios.json"
    @Argument(help: "File with the definitions that need to be built") var manifestFile: String
    @Argument(help: "Where the built Swift structs will go") var outputDir: String
    
    public init(){}
    
    public func run() throws {
        let settings = SchemaSettings(parentDirectory: schemaDir,
                                      manifestFile: manifestFile,
                                      outputDirectory: outputDir)
        
        let definitionBuilder = DefinitionsBuilder()
        let definitions = try definitionBuilder.buildDefinitionsDictionary(definitions: try ManifestReader(settings: settings).schemaDefinitions)
        
        try definitions.forEach {name, definition in
            _ = try definition.toSwiftFileBuilder().build().writeTo(settings.outputDirectory)
        }
    }
    
}


SchemaParser.main()
