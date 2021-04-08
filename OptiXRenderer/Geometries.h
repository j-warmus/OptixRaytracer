#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Attributes
{
    optix::float3 ambient;
    optix::float3 diffuse;
    optix::float3 specular;
    optix::float3 emission;
    float shininess;
};

struct Triangle
{
    optix::float3 vertices[3];
    Attributes attrs;
};

struct Sphere
{
    optix::float3 center;
    float radius;
    optix::Matrix4x4 transforms;
    Attributes attrs;
};

