#pragma once

#include <optixu/optixu_math_namespace.h>
#include "Geometries.h"

/**
 * Structures describing different payloads should be defined here.
 */

struct Payload
{
    optix::float3 radiance;
    bool done;
    // TODO: add more variable to payload if you need to
    optix::float3 origin;
    optix::float3 dir;
    optix::float3 specular;
    int depth;
};

struct ShadowPayload
{
    int isVisible;
};