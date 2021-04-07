//
//  ManifestLoader.swift
//  
//
//  Created by Jason Dees on 4/2/21.
//

import Foundation

public struct Manifest : Codable {
    let name: String
    let description: String
    let version: String
    let schemaRoot: String
    let schemas: [Manifest.Schema]
    
    public struct Schema : Codable {
        let path: String?
        let name: String
        let version: String
    }
}

extension Manifest {
    func load(basePath: String) throws -> [String: Any] {
        var dictionary: [String: Any] = [:]
        try schemas.forEach { dictionary[$0.name] = try $0.load(basePath: "\(basePath)/\(schemaRoot)") }
        return dictionary
    }
}

extension Manifest.Schema {
    func load(basePath: String) throws -> [String: Any] {
        let path: String = self.path ?? "scenarios"
        let fullPath = "\(basePath)/\(path)/\(name)/\(version)/\(name).json"
        let url = URL(string: fullPath)
        let schemaData = try Data(contentsOf: url!)
        //Do recursive ref loading here?
        return try JSONSerialization.jsonObject(with: schemaData) as! [String: Any]
    }
}

public struct ManifestLoader {
    
    let manifest: Manifest
    
    init(manifestFilePath: String) throws {
        let manifestURL = URL(string: manifestFilePath)
        let manifestData = try Data(contentsOf: manifestURL!)
        manifest = try! JSONDecoder().decode(Manifest.self, from: manifestData)
    }
}

public struct ManifestReader {
    
    let loader: ManifestLoader
    let settings: SchemaSettings
    
    let schemaDefinitions: [String: Any]
    
    init(settings: SchemaSettings) throws {
        self.settings = settings
        loader = try .init(manifestFilePath: settings.manifestFile)
        //Filter out definitions that aren't scenarios? Let the Scenario $refs determine what should be loaded
        //For inherited schemas, i don't want to parse them from the allOf array, but I guess I could?
        schemaDefinitions = try loader.manifest.load(basePath: settings.schemaDirectory)
    }
}

//Other loading strategies:
// 1. Have base Schemas (scenarios, metadata in this instance) that reference ($ref) child scenarios (definitions)
// 2. 
