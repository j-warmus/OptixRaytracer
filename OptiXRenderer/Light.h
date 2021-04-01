#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different light sources should be defined here.
 */

struct PointLight
{
    PointLight(optix::float3 pos, optix::float3 col) { position = pos; color = col; }
    PointLight() { position = optix::make_float3(0, 0, 0); color = optix::make_float3(0, 0, 0); }

    optix::float3 position;
    optix::float3 color;
};

struct DirectionalLight
{
    DirectionalLight(optix::float3 dir, optix::float3 col) { direction = dir; color = col; }
    DirectionalLight() { direction = optix::make_float3(0, 0, 0); color = optix::make_float3(0, 0, 0); }

    optix::float3 direction;
    optix::float3 color;
};