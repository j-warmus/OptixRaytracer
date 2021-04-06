#include <optix.h>
#include <optix_device.h>
#include "Geometries.h"

#ifndef SQRT3f
#define SQRT3f      1.73205080756887729352
#endif

using namespace optix;

rtBuffer<Sphere> spheres; // a buffer of all spheres

rtDeclareVariable(Ray, ray, rtCurrentRay, );

// Attributes to be passed to material programs 
rtDeclareVariable(Attributes, attrib, attribute Attribute, );

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
        // rtPrintf("%f\n", t);
        // TODO: assign attribute variables here
        rtReportIntersection(0);
    }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Sphere sphere = spheres[primIndex];

    // the diagonal of the cube is 2*r*sqrt(3) so the distance from the center to a corner is r*sqrt(3)
    float boundSize = sphere.radius * SQRT3f;

    result[0] = sphere.center.x - boundSize;
    result[1] = sphere.center.y - boundSize;
    result[2] = sphere.center.z - boundSize;
    result[3] = sphere.center.x + boundSize;
    result[4] = sphere.center.y + boundSize;
    result[5] = sphere.center.z + boundSize;
}