#include <optix.h>
#include <optix_device.h>

#include "Payloads.h"

using namespace optix;

rtDeclareVariable(Payload, payload, rtPayload, );
rtDeclareVariable(float3, backgroundColor, , );
rtDeclareVariable(Ray, ray, rtCurrentRay, );

RT_PROGRAM void miss()
{
    // Set the result to be the background color if miss
    // TODO: change the color to backgroundColor
    // payload.radiance = backgroundColor;
    //if (payload.depth < 5) {
    //    printf("missed\n");
    //}

    payload.radiance = backgroundColor;
    payload.specular = make_float3(1.f, 1.f, 1.f);
     
    if (ray.ray_type == 0) {
        payload.done = true;
    }
}

RT_PROGRAM void exception()
{
    // Print any exception for debugging
    const unsigned int code = rtGetExceptionCode();
    rtPrintExceptionDetails();
}

rtDeclareVariable(ShadowPayload, shadowPayload, rtPayload, );
rtDeclareVariable(float1, t, rtIntersectionDistance, );

RT_PROGRAM void anyHit()
{
    shadowPayload.isVisible = false;
    rtTerminateRay();
}