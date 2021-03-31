#include "SceneLoader.h"

void SceneLoader::rightMultiply(const optix::Matrix4x4& M)
{
    optix::Matrix4x4& T = transStack.top();
    T = T * M;
}

optix::float3 SceneLoader::transformPoint(optix::float3 v)
{
    optix::float4 vh = transStack.top() * optix::make_float4(v, 1);
    return optix::make_float3(vh) / vh.w; 
}

optix::float3 SceneLoader::transformNormal(optix::float3 n)
{
    return optix::make_float3(transStack.top() * make_float4(n, 0));
}

template <class T>
bool SceneLoader::readValues(std::stringstream& s, const int numvals, T* values)
{
    for (int i = 0; i < numvals; i++)
    {
        s >> values[i];
        if (s.fail())
        {
            std::cout << "Failed reading value " << i << " will skip" << std::endl;
            return false;
        }
    }
    return true;
}


std::shared_ptr<Scene> SceneLoader::load(std::string sceneFilename)
{
    // Attempt to open the scene file 
    std::ifstream in(sceneFilename);
    if (!in.is_open())
    {
        // Unable to open the file. Check if the filename is correct.
        throw std::runtime_error("Unable to open scene file " + sceneFilename);
    }

    auto scene = std::make_shared<Scene>();

    transStack.push(optix::Matrix4x4::identity());

    std::string str, cmd;

    // Read a line in the scene file in each iteration
    while (std::getline(in, str))
    {
        // Ruled out comment and blank lines
        if ((str.find_first_not_of(" \t\r\n") == std::string::npos) 
            || (str[0] == '#'))
        {
            continue;
        }

        // Read a command
        std::stringstream s(str);
        s >> cmd;

        // Some arrays for storing values
        float fvalues[12];
        int ivalues[3];
        std::string svalues[1];


        /*
        *   Image settings
        */
        if (cmd == "size" && readValues(s, 2, fvalues))
        {
            scene->width = (unsigned int)fvalues[0];
            scene->height = (unsigned int)fvalues[1];
        }
        else if (cmd == "output" && readValues(s, 1, svalues))
        {
            scene->outputFilename = svalues[0];
        }
        else if (cmd == "camera" && readValues(s, 10, fvalues)) {
            optix::float3 lookfrom = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            optix::float3 lookat = optix::make_float3(fvalues[3], fvalues[4], fvalues[5]);
            optix::float3 up  = optix::make_float3(fvalues[6], fvalues[7], fvalues[8]);
            optix::float1 fov = optix::make_float1(fvalues[9]);

            // TODO pass values to PinholeCamera.cu
            // need to achieve functionality equivalent to LookAt and setFov
        }
        

        /*
        *   Lights
        */
        else if (cmd == "point" && readValues(s, 6, fvalues))
        {
            optix::float3 transfpos = optix::make_float3(transStack.top() * optix::make_float4(fvalues[0], fvalues[1], fvalues[2], 1));
            
            // use fvalues[3-5] for light color in the constructor
            scene->plights.push_back(PointLight());
            // TODO determine what to pass into the light objects.  may be the same as original raytracer
        }
        else if (cmd == "directional" && readValues(s, 6, fvalues))
        {
            optix::float3 transfpos = optix::make_float3(transStack.top() * optix::make_float4(fvalues[0], fvalues[1], fvalues[2], 1));
            
            // use fvalues[3-5] for light color in the constructor
            scene->dlights.push_back(DirectionalLight());
            // TODO determine what to pass into the light objects.  may be the same as original raytracer
        }
        else if (cmd == "attenuation" && readValues(s, 3, fvalues))
        {
            // TODO I couldn't find where attenuation variables are stored
            //      Maybe we just add them to Scene.h?
        }


        /*
         *  Recursion 
         */
        else if (cmd == "maxdepth" && readValues(s, 1, ivalues))
        {
            // TODO max recursion depth is set in the renderer.
            //  save value in Renderer.h before calling SetMaxTraceDepth?
        }
        

        /*
        *   Materials 
        */ 
        else if (cmd == "ambient" && readValues(s, 3, fvalues)) 
        {
            // TODO  I still have no idea where material values should go for now.
            // maybe make a struct at the top of this file and pass its values into the geometries?
        }
        else if (cmd == "diffuse" && readValues(s, 3, fvalues)) 
        {
            // TODO
        }
        else if (cmd == "specular" && readValues(s, 3, fvalues)) 
        {
            // TODO
        }
        else if (cmd == "emission" && readValues(s, 3, fvalues)) 
        {
            // TODO
        }
        else if (cmd == "shininess" && readValues(s, 3, fvalues)) 
        {
            // TODO
        }


        /*
        *   Geometry
        */
        else if (cmd == "maxverts" && readValues(s, 1, ivalues)) 
        {
            scene->vertices.reserve(ivalues[0]);
        }
        else if (cmd == "maxvertnorms" && readValues(s, 1, ivalues))        // vertices with normals are optional.  do we want them?
        {
            // TODO
        }
        else if (cmd == "vertex" && readValues(s, 3, fvalues))
        {
            scene->vertices.push_back(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]));
        }
        else if (cmd == "vertexnormal" && readValues(s, 6, fvalues))
        {
            // TODO
        }
        /* TODO: combine tri and trinormal, because we only have one
        *        kind of triangle.  Just compute normals *NOW* for triangles without
        *        specified normals instead of computing them later.  Normal calculations
        *        can be generalized between the two types of triangles (although we
        *        don't need to do those calculations, right?)
        */
        else if (cmd == "tri" && readValues(s, 3, ivalues))
        {
            scene->triangles.push_back(Triangle());
        }
        else if (cmd == "trinormal" && readValues(s, 3, ivalues))
        {
            // TODO
        }
        else if (cmd == "sphere" && readValues(s, 4, fvalues))
        {
            scene->spheres.push_back(Sphere());
        }


        /*
        *   Transformations
        */
        else if (cmd == "translate" && readValues(s, 3, fvalues)) {    
            rightMultiply(
                optix::Matrix4x4::translate(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]))
            );
        }
        else if (cmd == "scale" && readValues(s, 3, fvalues)) {
            rightMultiply(
                optix::Matrix4x4::scale(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]))
            );
        }
        else if (cmd == "rotate" && readValues(s, 4, fvalues)) {
            // TODO find a way to change fvalues[3] from degrees to radians.
            // ideally we'd want to find an optix:: function but we might just need to import Math for pi.
            // we're going to be using pi a lot, so wouldn't optix provide it as a constant?
            rightMultiply(
                optix::Matrix4x4::rotate(fvalues[3], optix::make_float3(fvalues[0], fvalues[1], fvalues[2]))
            );
        }

        else if (cmd == "pushTransform") {
            transStack.push(transStack.top());
        }
        else if (cmd == "popTransform") {
            if (transStack.size() <= 1) {
                std::cerr << "Stack has no elements.  Cannot Pop\n";
            }
            else {
                transStack.pop();
            }
        }
  
        
        else {
            std::cerr << "Unknown Command: " << cmd << " Skipping \n";
        }
    }

    in.close();

    return scene;
}