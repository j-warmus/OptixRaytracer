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

// helper function for determining the bounding box coordinates
float min3(float a, float b, float c) {
    return a < b ? (a < c ? a : c) : (b < c ? b : c);
}
float max3(float a, float b, float c) {
    return a > b ? (a > c ? a : c) : (b > c ? b : c);
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Triangle tri = triangles[primIndex];

    // just get the minimum/maximum x, y, z from the triangle and set those values to be the bounds.
    result[0] = min3(tri.vertices[0].x, tri.vertices[1].x, tri.vertices[2].x);
    result[1] = min3(tri.vertices[0].y, tri.vertices[1].y, tri.vertices[2].y);
    result[2] = min3(tri.vertices[0].z, tri.vertices[1].z, tri.vertices[2].z);
    result[3] = max3(tri.vertices[0].x, tri.vertices[1].x, tri.vertices[2].x);
    result[4] = max3(tri.vertices[0].y, tri.vertices[1].y, tri.vertices[2].y);
    result[5] = max3(tri.vertices[0].z, tri.vertices[1].z, tri.vertices[2].z);
}