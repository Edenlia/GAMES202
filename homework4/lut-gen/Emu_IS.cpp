#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include <sstream>
#include <fstream>
#include <random>
#include "vec.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION

#include "stb_image_write.h"

const int resolution = 128;

Vec2f Hammersley(uint32_t i, uint32_t N) { // 0-1
    uint32_t bits = (i << 16u) | (i >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    float rdi = float(bits) * 2.3283064365386963e-10;
    return {float(i) / float(N), rdi};
}

Vec3f ImportanceSampleGGX(Vec2f Xi, Vec3f N, float roughness) {
    float a = roughness * roughness;

    //in spherical space, phi and theta obey GGX distribution
    float phi = 2 * PI * Xi.y;
    float theta = std::atan((a * sqrt(Xi.x))/ sqrt(1 - Xi.x));

    //from spherical space to cartesian space
    Vec3f M = Vec3f (sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));

    //tangent coordinates
    Vec3f up = abs(N.z) < 0.999 ? Vec3f(0.0f, 0.0f, 1.0f) : Vec3f(1.0f, 0.0f, 0.0f);
    Vec3f T = normalize(cross(up, N));
    Vec3f B = normalize(cross(N, T));

    //transform H to tangent space
    Vec3f M_tangent;
    M_tangent.x = dot(M, T);
    M_tangent.y = dot(M, B);
    M_tangent.z = dot(M, N);
    
    return M_tangent;
}

float GeometrySchlickGGX(float NdotV, float roughness) {
//    float a = roughness;
//    float k = ((a + 1) * (a + 1)) / 8.0f;
//
//    float nom = NdotV;
//    float denom = NdotV * (1.0f - k) + k;
//
//    return nom / denom;
    // TODO: Why??????
    float a = roughness;
    float k = (a * a) / 2.0f;

    float nom = NdotV;
    float denom = NdotV * (1.0f - k) + k;

    return nom / denom;
}

float GeometrySmith(float roughness, float NoV, float NoL) {
    float ggx2 = GeometrySchlickGGX(NoV, roughness);
    float ggx1 = GeometrySchlickGGX(NoL, roughness);

    return ggx1 * ggx2;
}

float DistributionGGX(float roughness, float NoH) {
    float a = roughness * roughness;
    float nom = (NoH * NoH) * (a * a - 1) + 1;

    return (a * a) / (PI * nom * nom);
}

Vec3f IntegrateBRDF(Vec3f V, float roughness) {

    const int sample_count = 1024;
    Vec3f N = Vec3f(0.0, 0.0, 1.0);
    float W = 0;
    for (int i = 0; i < sample_count; i++) {
        Vec2f Xi = Hammersley(i, sample_count);
        Vec3f H = ImportanceSampleGGX(Xi, N, roughness);
        Vec3f L = normalize(H * 2.0f * dot(V, H) - V);

        float NoL = std::max(L.z, 0.0f);
        float NoH = std::max(H.z, 0.0f);
        float VoH = std::max(dot(V, H), 0.0f);
        float NoV = std::max(dot(N, V), 0.0f);
        
        // To calculate (fr * ni) / p_o here
//        float pdfM = DistributionGGX(roughness, NoH) * (NoH);
//        float pdfI = pdfM / (4 * VoH);

        float G = GeometrySmith(roughness, NoV, NoL);
        float weight = VoH * G / NoV / NoH;
        W += weight;


        // Split Sum - Bonus 2
        
    }

    return {W / sample_count, W / sample_count, W / sample_count};
}

int main() {
    uint8_t data[resolution * resolution * 3];
    float step = 1.0 / resolution;
    for (int i = 0; i < resolution; i++) {
        for (int j = 0; j < resolution; j++) {
            float roughness = step * (static_cast<float>(i) + 0.5f);
            float NdotV = step * (static_cast<float>(j) + 0.5f);
            Vec3f V = Vec3f(std::sqrt(1.f - NdotV * NdotV), 0.f, NdotV);

            Vec3f irr = IntegrateBRDF(V, roughness);
//            irr = {1 - irr.x, 1 - irr.y, 1 - irr.z};

            data[(i * resolution + j) * 3 + 0] = uint8_t(irr.x * 255.0);
            data[(i * resolution + j) * 3 + 1] = uint8_t(irr.y * 255.0);
            data[(i * resolution + j) * 3 + 2] = uint8_t(irr.z * 255.0);
        }
    }
    stbi_flip_vertically_on_write(true);
    stbi_write_png("GGX_E_LUT.png", resolution, resolution, 3, data, resolution * 3);
    
    std::cout << "Finished precomputed!" << std::endl;
    return 0;
}