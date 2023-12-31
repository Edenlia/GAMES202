#ifdef GL_ES
precision highp float;
#endif

uniform vec3 uLightDir;
uniform vec3 uCameraPos;
uniform vec3 uLightRadiance;
uniform sampler2D uGDiffuse;
uniform sampler2D uGDepth;
uniform sampler2D uGNormalWorld;
uniform sampler2D uGShadow;
uniform sampler2D uGPosWorld;

varying mat4 vWorldToScreen;
varying highp vec4 vPosWorld;

#define M_PI 3.1415926535897932384626433832795
#define TWO_PI 6.283185307
#define INV_PI 0.31830988618
#define INV_TWO_PI 0.15915494309

#define RAY_MARCH_STEPS 1000

float Rand1(inout float p) {
  p = fract(p * .1031);
  p *= p + 33.33;
  p *= p + p;
  return fract(p);
}

vec2 Rand2(inout float p) {
  return vec2(Rand1(p), Rand1(p));
}

float InitRand(vec2 uv) {
	vec3 p3  = fract(vec3(uv.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 SampleHemisphereUniform(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = uv.x;
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(1.0 - z*z);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = INV_TWO_PI;
  return dir;
}

vec3 SampleHemisphereCos(inout float s, out float pdf) {
  vec2 uv = Rand2(s);
  float z = sqrt(1.0 - uv.x);
  float phi = uv.y * TWO_PI;
  float sinTheta = sqrt(uv.x);
  vec3 dir = vec3(sinTheta * cos(phi), sinTheta * sin(phi), z);
  pdf = z * INV_PI;
  return dir;
}

void LocalBasis(vec3 n, out vec3 b1, out vec3 b2) {
  float sign_ = sign(n.z);
  if (n.z == 0.0) {
    sign_ = 1.0;
  }
  float a = -1.0 / (sign_ + n.z);
  float b = n.x * n.y * a;
  b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
  b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

vec4 Project(vec4 a) {
  return a / a.w;
}

float GetDepth(vec3 posWorld) {
  float depth = (vWorldToScreen * vec4(posWorld, 1.0)).w;
  return depth;
}

/*
 * Transform point from world space to screen space([0, 1] x [0, 1])
 *
 */
vec2 GetScreenCoordinate(vec3 posWorld) {
  vec2 uv = Project(vWorldToScreen * vec4(posWorld, 1.0)).xy * 0.5 + 0.5;
  return uv;
}

float GetGBufferDepth(vec2 uv) {
  float depth = texture2D(uGDepth, uv).x;
  if (depth < 1e-2) {
    depth = 1000.0;
  }
  return depth;
}

vec3 GetGBufferNormalWorld(vec2 uv) {
  vec3 normal = texture2D(uGNormalWorld, uv).xyz;
  return normal;
}

vec3 GetGBufferPosWorld(vec2 uv) {
  vec3 posWorld = texture2D(uGPosWorld, uv).xyz;
  return posWorld;
}

float GetGBufferuShadow(vec2 uv) {
  float visibility = texture2D(uGShadow, uv).x;
  return visibility;
}

vec3 GetGBufferDiffuse(vec2 uv) {
  vec3 diffuse = texture2D(uGDiffuse, uv).xyz;
  diffuse = pow(diffuse, vec3(2.2));
  return diffuse;
}

/*
 * Evaluate diffuse bsdf value.
 *
 * wi, wo are all in world space.
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDiffuse(vec3 wi, vec3 wo, vec2 uv) {
  vec3 normal = GetGBufferNormalWorld(uv);
  wi = normalize(wi);

  return GetGBufferDiffuse(uv) * INV_PI * max(0.0, dot(wi, normal));
}

/*
 * Evaluate directional light with shadow map
 * uv is in screen space, [0, 1] x [0, 1].
 *
 */
vec3 EvalDirectionalLight(vec2 uv) {
  vec3 Le = vec3(0.0);

  float visible = GetGBufferuShadow(uv);
  Le = uLightRadiance * visible;

  return Le;
}

bool RayMarch(vec3 ori, vec3 dir, out vec3 hitPos) {

//  float step =0.05;
//  vec3 endPoint =ori;
//
//  for(int i=0;i<40;i++){
//    vec3 testPoint = endPoint+step * dir;
//    float testDepth = GetDepth(testPoint);
//    float  bufferDepth = GetGBufferDepth(GetScreenCoordinate(testPoint));
//    if(step > 40.0){
//      return false;
//    }else if(testDepth -bufferDepth > 1e-6){
//      hitPos = testPoint;
//      return true;
//    }else if( testDepth < bufferDepth ){
//      endPoint =testPoint;
//    }else if( testDepth > bufferDepth){
//    }
//
//  }
//  return false;

  float step = 0.04;
  float bias = 0.1;
  for (int i = 1; i <= RAY_MARCH_STEPS; i++) {
    vec3 posWorld = ori + dir * step * float(i);
    float rayDepth = GetDepth(posWorld);
    float depth = GetGBufferDepth(GetScreenCoordinate(posWorld));

    if (rayDepth - depth > bias) {
      hitPos = GetGBufferPosWorld(GetScreenCoordinate(posWorld));
      return true;
    }
  }

  return false;

//  float UVStep = 0.001;
//  float bias = 3.0;
//  vec2 UVdir = GetScreenCoordinate(ori + dir) - GetScreenCoordinate(ori);
//  UVdir = normalize(UVdir);
//
//  for (int i = 1; i <= RAY_MARCH_STEPS; i++) {
//    vec2 posUV = GetScreenCoordinate(ori) + UVdir * UVStep * float(i);
//    if (posUV.x < 0.0 || posUV.x > 1.0 || posUV.y < 0.0 || posUV.y > 1.0) {
//      break;
//    }
//    float depth = GetGBufferDepth(posUV);
//    float rayDepth;
//    vec3 posWorld = GetGBufferPosWorld(posUV);
//    float w = dot(vec3(posWorld - ori), dir);
//    rayDepth = GetGBufferDepth(GetScreenCoordinate(ori)) + dir.z * w;
//
//    if (rayDepth - depth > bias) {
//      hitPos = GetGBufferPosWorld(GetScreenCoordinate(posWorld));
//      return true;
//    }
//  }
//
//    return false;
}

vec3 SpecularL() {
  float s = InitRand(gl_FragCoord.xy);
  vec3 wo = uCameraPos - vPosWorld.xyz;
  wo = normalize(wo);
  vec3 n = GetGBufferNormalWorld(GetScreenCoordinate(vPosWorld.xyz));
  vec3 wi = -wo + 2.0 * dot(wo, n) * n;

  vec3 hitPos = vec3(0.0);
  RayMarch(vPosWorld.xyz, wi, hitPos);
  if (hitPos == vec3(0.0)) {
    return vec3(0.0);
  }
  else if (hitPos == vPosWorld.xyz) {
    return vec3(1.0);
  }
  else {
    return GetGBufferDiffuse(GetScreenCoordinate(hitPos));
  }


}

#define SAMPLE_NUM 2

void main() {
  float s = InitRand(gl_FragCoord.xy);

  vec3 L = vec3(0.0);
  vec3 wo = uCameraPos - vPosWorld.xyz;
  wo = normalize(wo);
  vec3 wl = uLightDir;
  wl = normalize(wl);
  vec3 directL = EvalDiffuse(wl, wo, GetScreenCoordinate(vPosWorld.xyz))
  * EvalDirectionalLight(GetScreenCoordinate(vPosWorld.xyz));
  vec3 indirectL = vec3(0.0);
  for (int i = 0; i < SAMPLE_NUM; i++) {
    float pdf = 0.0;
    vec3 b1, b2;
    vec3 N = GetGBufferNormalWorld(GetScreenCoordinate(vPosWorld.xyz));
    LocalBasis(N, b1, b2);
    vec3 wd2i = SampleHemisphereUniform(s, pdf); // direct pos to indirect pos
    wd2i = normalize(mat3(b1, b2, N) * wd2i);

    vec3 hitPos = vec3(0.0);
    if (RayMarch(vPosWorld.xyz, wd2i, hitPos)) {
      indirectL +=
      EvalDiffuse(wd2i, wo, GetScreenCoordinate(vPosWorld.xyz))
      * EvalDiffuse(wl, -wd2i, GetScreenCoordinate(hitPos))
      * EvalDirectionalLight(GetScreenCoordinate(hitPos))
      / pdf;
    }
  }
  indirectL /= float(SAMPLE_NUM);
  L = directL + indirectL;

//  L = SpecularL();

  vec3 color;
  color = pow(clamp(L, vec3(0.0), vec3(1.0)), vec3(1.0 / 2.2));

  gl_FragColor = vec4(vec3(color.rgb), 1.0);
}
