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
    float3 result = make_float3(0.f, 0.f, 0.f);

    // I think this is right
    size_t2 screen = resultBuffer.size();

    float2 d;
    d.x = tan(fovx / 2.) * (((launchIndex.x + 0.5) - screen.x / 2.) / (screen.x / 2.));
    d.y = tan(fovy / 2.) * (((launchIndex.y + 0.5) - screen.y / 2.) / (screen.y / 2.));

    float3 origin = eye;
    float3 dir = normalize(d.x * U + d.y * V - W);
    float epsilon = 0.001f; 


    Payload payload;
    payload.origin = make_float3(0.f, 0.f, 0.f);
    payload.dir = make_float3(0.f, 0.f, 0.f);
    payload.radiance = make_float3(0.f, 0.f, 0.f);
    payload.specular = make_float3(0.f, 0.f, 0.f);
    payload.done = false;
    bool depthset = false;
    //payload.done = false;

    bool first_pass = true;

    do {
        // Set max depth in the payload
        if (!depthset) {
            payload.depth = 5;
            depthset = true;
        }
        
        // Trace a ray
        /*if (payload.depth < 5) {
           rtPrintf("depth %d O: %f, %f, %f      D: %f, %f, %f\n", payload.depth, origin.x, origin.y, origin.z, dir.x, dir.y, dir.z);
        }*/
        
        Ray ray = make_Ray(origin, dir, 0, epsilon, RT_DEFAULT_MAX);
        rtTrace(root, ray, payload);

        //if (payload.origin.x +  payload.origin.y + payload.origin.z != 0) 
        //    rtPrintf("depth %d  or %f %f %f pay %f %f %f\n", payload.depth, origin.x, origin.y, origin.z,
        //     payload.origin.x, payload.origin.y, payload.origin.z);

        // Accumulate radiance
        if (first_pass) {
            result += payload.radiance;
            first_pass = false;
        }
        else
        {
            result += payload.radiance * payload.specular;
        }

        // Prepare to shoot next ray
        origin = payload.origin;
        dir = payload.dir;
    } while (!payload.done && payload.depth > 0);


    // Write the result
    resultBuffer[launchIndex] = result;
}