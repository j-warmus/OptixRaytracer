#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Triangle
{
    optix::float3 vertices[3];
};

struct Sphere
{
    optix::float3 center;
    float radius;
};

struct Attributes
{
    

    // TODO: define the attributes structure
};