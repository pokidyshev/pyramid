//
//  Shaders.metal
//  Trapeze
//
//  Created by Nikita Pokidyshev on 28.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
  packed_float3 position;
  packed_float3 normal;
};

struct VertexOut {
  float4 position [[position]];
  float3 fragmentPosition;
  float3 normal;
};

struct Light {
  packed_float3 color;      // 0 - 2
  float ambientIntensity;   // 3
  packed_float3 direction;  // 4 - 6
  float diffuseIntensity;   // 7
  float shininess;          // 8
  float specularIntensity;  // 9

  /*
   _______________________
   |0 1 2 3|4 5 6 7|8 9    |
   -----------------------
   |       |       |       |
   | chunk0| chunk1| chunk2|
   */
};

struct Uniforms {
  float4x4 modelMatrix;
  float4x4 projectionMatrix;
  Light light;
};

vertex VertexOut basic_vertex(const device VertexIn* vertex_array [[ buffer(0) ]],
                              const device Uniforms&  uniforms    [[ buffer(1) ]],
                              unsigned int vid [[ vertex_id ]])
{
  float4x4 mv_Matrix = uniforms.modelMatrix;
  float4x4 proj_Matrix = uniforms.projectionMatrix;

  VertexIn VertexIn = vertex_array[vid];

  VertexOut VertexOut;
  VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);
  VertexOut.fragmentPosition = (mv_Matrix * float4(VertexIn.position,1)).xyz;
  VertexOut.normal = (mv_Matrix * float4(VertexIn.normal, 0.0)).xyz;

  return VertexOut;
}

fragment float4 basic_fragment(VertexOut interpolated [[stage_in]],
                               const device Uniforms&  uniforms    [[ buffer(1) ]])
{
  // Ambient
  Light light = uniforms.light;
  float4 ambientColor = float4(light.color * light.ambientIntensity, 1);

  // Diffuse
  float diffuseFactor = max(0.0,dot(interpolated.normal, light.direction));
  float4 diffuseColor = float4(light.color * light.diffuseIntensity * diffuseFactor, 1.0);

  // Specular
  float3 eye = normalize(interpolated.fragmentPosition);
  float3 reflection = reflect(light.direction, interpolated.normal);
  float specularFactor = pow(max(0.0, dot(reflection, eye)), light.shininess);
  float4 specularColor = float4(light.color * light.specularIntensity * specularFactor, 1.0);

  float4 color = float4(0.5, 0.5, 0.5, 1.0);
  return color * (ambientColor + diffuseColor + specularColor);
}
