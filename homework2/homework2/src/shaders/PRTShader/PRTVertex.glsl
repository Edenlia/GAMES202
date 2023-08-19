attribute vec3 aVertexPosition;
attribute vec3 aNormalPosition;
attribute mat3 aPrecomputeLT;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform vec3 uPrecomputeLSH0;
uniform vec3 uPrecomputeLSH1;
uniform vec3 uPrecomputeLSH2;
uniform vec3 uPrecomputeLSH3;
uniform vec3 uPrecomputeLSH4;
uniform vec3 uPrecomputeLSH5;
uniform vec3 uPrecomputeLSH6;
uniform vec3 uPrecomputeLSH7;
uniform vec3 uPrecomputeLSH8;

varying vec3 vColor;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

void main(void) {

    vFragPos = (uModelMatrix * vec4(aVertexPosition, 1.0)).xyz;
    vNormal = (uModelMatrix * vec4(aNormalPosition, 0.0)).xyz;

    vec3 L0 = uPrecomputeLSH0 * aPrecomputeLT[0][0];
    vec3 L1 = uPrecomputeLSH1 * aPrecomputeLT[0][1];
    vec3 L2 = uPrecomputeLSH2 * aPrecomputeLT[0][2];
    vec3 L3 = uPrecomputeLSH3 * aPrecomputeLT[1][0];
    vec3 L4 = uPrecomputeLSH4 * aPrecomputeLT[1][1];
    vec3 L5 = uPrecomputeLSH5 * aPrecomputeLT[1][2];
    vec3 L6 = uPrecomputeLSH6 * aPrecomputeLT[2][0];
    vec3 L7 = uPrecomputeLSH7 * aPrecomputeLT[2][1];
    vec3 L8 = uPrecomputeLSH8 * aPrecomputeLT[2][2];

    vColor = L0 + L1 + L2 + L3 + L4 + L5 + L6 + L7 + L8;

    gl_Position = uProjectionMatrix * uViewMatrix * uModelMatrix *
    vec4(aVertexPosition, 1.0);

}