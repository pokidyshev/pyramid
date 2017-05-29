//
//  Vertex.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 29.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

struct Vertex{

  var x,y,z: Float     // position data
  var r,g,b,a: Float   // color data
  var s,t: Float       // texture coordinates

  func floatBuffer() -> [Float] {
    return [x,y,z,r,g,b,a,s,t]
  }

};
