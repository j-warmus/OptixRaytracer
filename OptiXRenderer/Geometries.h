#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Triangle
{
    

    // TODO: define the triangle structure

    
};

struct Sphere
{


    // TODO: define the sphere structure


};

struct Attributes
{
    // material attributes for each object
    optix::float3 ambient = optix::make_float3(0, 0, 0);
    optix::float3 diffuse = optix::make_float3(0, 0, 0);
    optix::float3 specular = optix::make_float3(0, 0, 0);
    optix::float3 emission = optix::make_float3(0, 0, 0);
    optix::float3 shininess = optix::make_float3(0, 0, 0);
};