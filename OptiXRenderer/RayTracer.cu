#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"
#include "Geometries.h"
#include "Light.h"

using namespace optix;

#define epsilon 0.001f

// Declare light buffers
rtBuffer<PointLight> plights;
rtBuffer<DirectionalLight> dlights;

// Declare variables
rtDeclareVariable(Payload, payload, rtPayload, );
rtDeclareVariable(rtObject, root, , );
rtDeclareVariable(float3, attenuation, , );
rtDeclareVariable(uint, tracedepth, , );
// Declare attibutes 
rtDeclareVariable(Attributes, attrib, attribute Attribute, );
rtDeclareVariable(float3, normal, attribute Normal, );
rtDeclareVariable(Ray, ray, rtCurrentRay, );
rtDeclareVariable(float1, t, rtIntersectionDistance, );


/*__device__ float3 getBPMult(float3 intersectPos, float3 lightDir, float distanceToLight) {
    Ray shadowRay = make_Ray(intersectPos, lightDir, 1, epsilon, distanceToLight);
    ShadowPayload shadowPayload;
    rtTrace(root, shadowRay, shadowPayload);


    if (shadowPayload.isVisible) {
        float attenuationMult = attenuation.x +
            attenuation.y * distanceToLight +
            attenuation.z * distanceToLight * distanceToLight;

        float diffuseMult = fmax(dot(normal, lightDir), 0);
        float3 lambert = attrib.diffuse * diffuseMult;

        float blinnphongMult = pow(fmax(dot(normal, normalize(-ray.direction + lightDir)), 0), attrib.shininess);
        float3 blinnphong = attrib.specular * blinnphongMult;

        return (lambert + blinnphong) / attenuationMult;
    }
    else {
        return make_float3(0);
    }
}*/

RT_PROGRAM void closestHit()
{
    float3 result = make_float3(0.f, 0.f, 0.f);
    Ray shadowRay;
    ShadowPayload shadowPayload;

    float3 intersectPos = ray.origin + t.x * ray.direction;

    float3 lightDir = make_float3(0, 0, 0);        // TODO optix::normalize(lightPos - intersectPos)
    float distanceToLight = 0;  // TODO (0 if directional, optix::length(lightPos - intersectPos) if point light)

    //rtPrintf("Casting magic spell to make shadows work. %i\n", 1);

    result += attrib.ambient + attrib.emission;

    // POINT LIGHTS
    for (int i = 0; i < plights.size(); i++) {
        lightDir = normalize(plights[i].position - intersectPos);       // surfaces look closer to how they should when not normalized, but center spheres are still weird.
        distanceToLight = length(plights[i].position - intersectPos);

        shadowRay = make_Ray(intersectPos, lightDir, 1, epsilon, distanceToLight);
        shadowPayload.isVisible = true;
        rtTrace(root, shadowRay, shadowPayload);

        if (shadowPayload.isVisible)
        {
            float attenuationMult = attenuation.x +
                attenuation.y * distanceToLight +
                attenuation.z * distanceToLight * distanceToLight;

            float diffuseMult = fmax(dot(normal, lightDir), 0);
            float3 lambert = attrib.diffuse * diffuseMult;

            float blinnphongMult = pow(fmax(dot(normal, normalize(-ray.direction + lightDir)), 0), attrib.shininess);
            float3 blinnphong = attrib.specular * blinnphongMult;


            float3 totalBP = (lambert + blinnphong) / attenuationMult;
            /*
           *
           *
           *
           */
            result += make_float3(
                plights[i].color.x * totalBP.x,
                plights[i].color.y * totalBP.y,
                plights[i].color.z * totalBP.z
            );
        }
    }






    // DIRECTIONAL
    for (int i = 0; i < dlights.size(); i++) {
        lightDir = normalize(dlights[i].direction);
        distanceToLight = 0;
        //rtPrintf("%f\n",plights[i].color.x);
        //float3 blinnPhong = getBPMult(intersectPos, lightDir, 0); // distance is 0 for directional lights


        /*
        *
        *   BLINN-PHONG CODE
        *
        */

        shadowRay = make_Ray(intersectPos, lightDir, 1, epsilon, distanceToLight);
        shadowPayload.isVisible = true;
        rtTrace(root, shadowRay, shadowPayload);

        if (shadowPayload.isVisible)
        {
            float attenuationMult = attenuation.x +
                attenuation.y * distanceToLight +
                attenuation.z * distanceToLight * distanceToLight;

            float diffuseMult = fmax(dot(normal, lightDir), 0);
            float3 lambert = attrib.diffuse * diffuseMult;

            float blinnphongMult = pow(fmax(dot(normal, normalize(-ray.direction + lightDir)), 0), attrib.shininess);
            float3 blinnphong = attrib.specular * blinnphongMult;

            float3 totalBP = (lambert + blinnphong) / attenuationMult;
            /*
           *
           *
           *
           */

            result += make_float3(
                dlights[i].color.x * totalBP.x,
                dlights[i].color.y * totalBP.y,
                dlights[i].color.z * totalBP.z
            );
        }
    }

    // RECURSIVE
    if (payload.depth < tracedepth){
        float3 refDir = normalize(ray.direction + 2 * (dot(-ray.direction, normal)) * normal);
        float3 refPos = intersectPos + epsilon * refDir;
        payload.depth += 1;
        
        Ray refRay = make_Ray(refPos, refDir, 0, epsilon, RT_DEFAULT_MAX);
        rtTrace(root, refRay, payload);
        
        // Accumulate radiance
        result += attrib.specular * payload.radiance;
        
    }

    payload.radiance = result;
}