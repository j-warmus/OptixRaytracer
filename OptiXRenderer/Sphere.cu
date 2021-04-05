#include <optix.h>
#include <optix_device.h>
#include "Geometries.h"

using namespace optix;

rtBuffer<Sphere> spheres; // a buffer of all spheres

rtDeclareVariable(Ray, ray, rtCurrentRay, );

// Attributes to be passed to material programs 
rtDeclareVariable(Attributes, attrib, attribute Attribute, );
rtDeclareVariable(float3, normal, attribute Normal, );

RT_PROGRAM void intersect(int primIndex)
{
    // Find the intersection of the current ray and sphere
    Sphere sphere = spheres[primIndex];
    float t;

    optix::Matrix4x4 transinv = sphere.transforms.inverse();

    // pre-transform the ray
    float3 src = optix::make_float3(transinv * optix::make_float4(ray.origin, 1));
    float3 dir = optix::normalize(optix::make_matrix3x3(transinv) * ray.direction);
    float3 eyetocenter = src - sphere.center;

    float a = optix::dot(dir, dir);
    float b = 2 * optix::dot(dir, eyetocenter);
    float c = optix::dot(eyetocenter, eyetocenter) - (sphere.radius * sphere.radius);

    float disc = b * b - 4 * a * c;

    if (disc < 0) {             // NO HIT
        return;
    }
    else if (disc == 0) {       // 1 HIT
        t = (-b / 2 * a);
    }
    else {                      // 2 HITS
        disc = sqrt(disc);
        float sol1 = ((-b + disc) / 2 * a);
        float sol2 = ((-b - disc) / 2 * a);

        if (sol1 == sol2) {
            t = sol1;
        }
        else if (sol1 > 0 && sol2 > 0) {
            t = sol1 < sol2 ? sol1 : sol2;
        }
        else if ((sol1 < 0 && sol2 > 0) || (sol1 > 0 && sol2 < 0)) {
            t = sol1 < 0 ? sol2 : sol1;
        }
        else {
            return;
        }
    }

    // get the location of the (transformed) intersetion
    optix::float3 hitPos = src + t * dir;
    // post-transform the hit position and intersection distance
    hitPos = optix::make_float3(sphere.transforms * optix::make_float4(hitPos, 1));
    t = optix::dot(hitPos - ray.origin, ray.direction);

    // Report intersection (material programs will handle the rest)
    if (rtPotentialIntersection(t))
    {
        // Pass attributes
        attrib = sphere.attrs;
        // calc and pass normal
        normal = hitPos - make_float3(sphere.transforms * make_float4(sphere.center,1));
        rtReportIntersection(0);
    }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Sphere sphere = spheres[primIndex];

    // TODO: implement sphere bouding box
    result[0] = -1000.f;
    result[1] = -1000.f;
    result[2] = -1000.f;
    result[3] = 1000.f;
    result[4] = 1000.f;
    result[5] = 1000.f;
}