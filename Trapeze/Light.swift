//
//  Light.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 30.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

import Foundation

struct Light {

  var color: (Float, Float, Float)
  var direction: (Float, Float, Float)
  // Shininess is not a parameter of light,
  // it’s more like a parameter of the object material.
  // But for the sake of simplicity it is passed with the light data.
  var shininess: Float

  var ambientIntensity: Float
  var diffuseIntensity: Float
  var specularIntensity: Float

  static func size() -> Int {
    return MemoryLayout<Float>.size * 12
  }

  func raw() -> [Float] {
    let raw = [color.0, color.1, color.2, ambientIntensity, direction.0, direction.1, direction.2, diffuseIntensity, shininess, specularIntensity]
    return raw
  }
}
