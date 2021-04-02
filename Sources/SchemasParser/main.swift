//
//  File.swift
//  
//
//  Created by Jason Dees on 4/2/21.
//

import Foundation

do {
    try SchemaParser().run()
} catch {
    print("Whoops! An error occurred: \(error)")
}
