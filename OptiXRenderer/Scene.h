#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

#include "Geometries.h"
#include "Light.h"

struct Scene
{
    // Info about the output image
    std::string outputFilename;
    unsigned int width, height;

    std::string integratorName;

    std::vector<optix::float3> vertices;

    std::vector<Triangle> triangles;
    std::vector<Sphere> spheres;

    std::vector<DirectionalLight> dlights;
    std::vector<PointLight> plights;

    // TODO: add other variables that you need here

    optix::float3 attenuation = optix::make_float3(1.f,0.f,0.f);  // index 0 is constant, index 1 is linear, index 2 is quadratic

    unsigned int maxDepth = 3;
    
    optix::float3 eye;
    optix::float3 u;
    optix::float3 v;
    optix::float3 w;

    float fovy;
    float fovx;



    Scene()
    {
        outputFilename = "raytrace.png";
        integratorName = "raytracer";
    }
};