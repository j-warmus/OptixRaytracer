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

    Attributes currentAttributes;

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
            optix::float3 eye = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            optix::float3 center = optix::make_float3(fvalues[3], fvalues[4], fvalues[5]);
            optix::float3 up  = optix::make_float3(fvalues[6], fvalues[7], fvalues[8]);
            
            float aspect = (float)scene->width / (float)scene->height;
            float fovy = fvalues[9] * M_PIf / 180.;
            float fovx = 2. * atan(tan(fovy / 2.) * aspect);

            // don't change the order of these lines
            optix::float3 w = optix::normalize(eye - center);
            optix::float3 u = optix::normalize(optix::cross(up, w));
            optix::float3 v = optix::cross(w, u);

            // pos, u, v, w are passed in a float3 buffer
            // fovy, fovx, width, height passed in a float 
            // TODO pass values to pinholecamera.cu
            std::vector<optix::float3> cameraPos;
            std::vector<float> cameraView;

            //Buffer is undefined - should an #include be enough or do I have the wrong idea?

        }
        

        /*
        *   Lights
        */
        else if (cmd == "point" && readValues(s, 6, fvalues))
        {
            optix::float3 transfpos = optix::make_float3(transStack.top() * optix::make_float4(fvalues[0], fvalues[1], fvalues[2], 1));
            optix::float3 color = optix::make_float3(fvalues[3], fvalues[4], fvalues[5]);
            
            scene->plights.push_back(PointLight(transfpos, color));
        }
        else if (cmd == "directional" && readValues(s, 6, fvalues))
        {
            optix::float3 transfpos = optix::make_float3(transStack.top() * optix::make_float4(fvalues[0], fvalues[1], fvalues[2], 1));
            optix::float3 color = optix::make_float3(fvalues[3], fvalues[4], fvalues[5]);
            
            scene->dlights.push_back(DirectionalLight(transfpos, color));
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
            scene->maxDepth = ivalues[0];
        }
        

        /*
        *   Materials 
        */ 
        else if (cmd == "ambient" && readValues(s, 3, fvalues)) 
        {
            currentAttributes.ambient = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "diffuse" && readValues(s, 3, fvalues)) 
        {
            currentAttributes.diffuse = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "specular" && readValues(s, 3, fvalues)) 
        {
            currentAttributes.specular = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "emission" && readValues(s, 3, fvalues)) 
        {
            currentAttributes.emission = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "shininess" && readValues(s, 3, fvalues)) 
        {
            currentAttributes.shininess = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }


        /*
        *   Geometry
        */
        else if (cmd == "maxverts" && readValues(s, 1, ivalues)) 
        {
            scene->vertices.reserve(ivalues[0]);
        }
        else if (cmd == "vertex" && readValues(s, 3, fvalues))
        {
            scene->vertices.push_back(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]));
        }
        else if (cmd == "tri" && readValues(s, 3, ivalues))
        {
            scene->triangles.push_back(Triangle(scene->vertices[ivalues[0]], scene->vertices[ivalues[1]], scene->vertices[ivalues[2]], currentAttributes));
        }
        else if (cmd == "sphere" && readValues(s, 4, fvalues))
        {
            scene->spheres.push_back(Sphere(optix::make_float3(fvalues[0], fvalues[1], fvalues[2]), optix::make_float1(fvalues[3]), transStack.top(), currentAttributes);
        }


        /* 
        *   Geometry w/ normals     (OPTIONAL)
        */
        else if (cmd == "maxvertnorms" && readValues(s, 1, ivalues))
        {
            std::cerr << "Command \"maxvertexnorms\" not implemented.\n";
        }
        else if (cmd == "vertexnormal" && readValues(s, 6, fvalues))
        {
            std::cerr << "Command \"vertexnormal\" not implemented.\n";
        }
        else if (cmd == "trinormal" && readValues(s, 3, ivalues))
        {
            std::cerr << "Command \"trinormal\" not implemented.\n";
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
            float rads = fvalues[3] * M_PIf / 180.;     // conversion to radians required
            rightMultiply(
                optix::Matrix4x4::rotate(rads, optix::make_float3(fvalues[0], fvalues[1], fvalues[2]))
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