#include "optix.h"
#include "optix_device.h"
#include "Geometries.h"

using namespace optix;

rtBuffer<Triangle> triangles; // a buffer of all spheres

rtDeclareVariable(Ray, ray, rtCurrentRay, );

// Attributes to be passed to material programs 
rtDeclareVariable(Attributes, attrib, attribute Attribute, );
rtDeclareVariable(float3, normal, attribute Normal, );

RT_PROGRAM void intersect(int primIndex)
{
    // Find the intersection of the current ray and triangle
    Triangle tri = triangles[primIndex];
    float t;

    // Moller-Trumbore: "http://www.graphics.cornell.edu/pubs/1997/MT97.pdf"

    const float EPSILON = 1e-6;
    float3 v0 = tri.vertices[0];
    float3 v1 = tri.vertices[1];
    float3 v2 = tri.vertices[2];
    float3 e1, e2, h, s, q;
    float a, f, u, v;
    e1 = v1 - v0;
    e2 = v2 - v0;
    h = cross(ray.direction, e2);
    a = dot(e1, h);
    if (a > -EPSILON && a < EPSILON) { return; }
    f = 1.f / a;
    s = ray.origin - v0;
    u = f * dot(s, h);
    if (u < 0.f || u > 1.f) { return; }
    q = cross(s, e1);
    v = f * dot(ray.direction, q);
    if (v < 0.f || u + v > 1.f) { return; }
    t = f * dot(e2, q);
    

    // Report intersection (material programs will handle the rest)
    if (rtPotentialIntersection(t))
    {
        // Pass attributes
        attrib = tri.attrs;
        // get and pass normal
        float3 n1 = normalize(cross((v2 - v1), (v1 - v0)));
        normal = (dot(ray.direction, n1) < 0) ? n1 : -1.f*n1;

        rtReportIntersection(0);
    }
    else { return; }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Triangle tri = triangles[primIndex];

    // TODO: implement triangle bouding box
    result[0] = -1000.f;
    result[1] = -1000.f;
    result[2] = -1000.f;
    result[3] = 1000.f;
    result[4] = 1000.f;
    result[5] = 1000.f;
}