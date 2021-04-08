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
    float3 result = make_float3(0.f,0.f,0.f);
    
    
    float3 intersectPos = ray.origin + t.x * ray.direction;

    float3 lightDir;        // TODO optix::normalize(lightPos - intersectPos)
    float distanceToLight;  // TODO (0 if directional, optix::length(lightPos - intersectPos) if point light)
    //rtPrintf("%i", plights.size());

    // POINT LIGHTS
    for (int i = 0; i < plights.size(); i++) {
        lightDir = normalize(plights[i].position - intersectPos);
        distanceToLight = length(plights[i].position - intersectPos);

        //float3 blinnPhong = getBPMult(intersectPos, lightDir, distanceToLight);


        /*
        *
        *   BLINN-PHONG CODE
        *
        */
        //Ray shadowRay = make_Ray(intersectPos, lightDir, 1, epsilon, distanceToLight);
        //ShadowPayload shadowPayload;
        //rtTrace(root, shadowRay, shadowPayload);
        //if (shadowPayload.isVisible){
            float attenuationMult = attenuation.x +
                attenuation.y * distanceToLight +
                attenuation.z * distanceToLight * distanceToLight;

            float diffuseMult = fmax(dot(normal, lightDir), 0);
            float3 lambert = attrib.diffuse * diffuseMult;

            float blinnphongMult = pow(fmax(dot(normal, normalize(-ray.direction + lightDir)), 0), attrib.shininess);
            float3 blinnphong = attrib.specular * blinnphongMult;


            float3 blinnPhongMult = (lambert + blinnphong) / attenuationMult;
            /*
           *
           *
           *
           */
            result += make_float3(
                plights[i].color.x * blinnPhongMult.x,
                plights[i].color.y * blinnPhongMult.y,
                plights[i].color.z * blinnPhongMult.z
            );
        //}
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
        float attenuationMult = attenuation.x +
            attenuation.y * distanceToLight +
            attenuation.z * distanceToLight * distanceToLight;

        float diffuseMult = fmax(dot(normal, lightDir), 0);
        float3 lambert = attrib.diffuse * diffuseMult;

        float blinnphongMult = pow(fmax(dot(normal, normalize(-ray.direction + lightDir)), 0), attrib.shininess);
        float3 blinnphong = attrib.specular * blinnphongMult;

        float3 blinnPhongMult = (lambert + blinnphong) / attenuationMult;
        /*
       *
       *
       *
       */



        result += make_float3(
            dlights[i].color.x * blinnPhongMult.x,
            dlights[i].color.y * blinnPhongMult.y,
            dlights[i].color.z * blinnPhongMult.z
        );
    }

    payload.radiance = result;
}