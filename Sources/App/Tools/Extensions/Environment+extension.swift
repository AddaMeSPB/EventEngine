//
//  Environment+extension.swift
//  
//
//  Created by Saroar Khandoker on 11.11.2021.
//

import Vapor

extension Environment {
  public static var staging: Environment { .init(name: "staging") }
}
