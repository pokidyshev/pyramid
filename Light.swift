//
//  Light.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 29.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

import Foundation

struct Light {

  var color: (Float, Float, Float)
  var ambientIntensity: Float

  static func size() -> Int {
    return MemoryLayout<Float>.size * 4
  }

  func raw() -> [Float] {
    let raw = [color.0, color.1, color.2, ambientIntensity]
    return raw
  }
}
