#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>

#include "Payloads.h"

using namespace optix;

rtBuffer<float3, 2> resultBuffer; // used to store the render result

rtDeclareVariable(rtObject, root, , ); // Optix graph

rtDeclareVariable(uint2, launchIndex, rtLaunchIndex, ); // a 2d index (x, y)

rtDeclareVariable(int1, frameID, , );

// Camera info 

// TODO:: delcare camera varaibles here

rtDeclareVariable(float3, eye, , );
rtDeclareVariable(float3, U, , );
rtDeclareVariable(float3, V, , );
rtDeclareVariable(float3, W, , );
rtDeclareVariable(float, fovx, , );
rtDeclareVariable(float, fovy, , );

RT_PROGRAM void generateRays()
{
    float3 result = make_float3(0.f);

    // I think this is right
    size_t2 screen = resultBuffer.size();

    float2 d;
    d.x = tan(fovx / 2.) * (((launchIndex.x + 0.5) - screen.x / 2.) / (screen.x / 2.));
    d.y = tan(fovy / 2.) * (((launchIndex.y + 0.5) - screen.y / 2.) / (screen.y / 2.));

    float3 dir = normalize(d.x * U + d.y * V + W);
    float epsilon = 0.001f; 

    // TODO: modify the following lines if you need
    // Shoot a ray to compute the color of the current pixel
    Ray ray = make_Ray(eye, dir, 0, epsilon, RT_DEFAULT_MAX);
    Payload payload;
    rtTrace(root, ray, payload);

    // Write the result
    resultBuffer[launchIndex] = payload.radiance;
}