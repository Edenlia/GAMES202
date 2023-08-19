#ifdef GL_ES
precision mediump float;
#endif

varying highp vec3 vColor;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;


void main() {
    gl_FragColor = vec4(vColor, 1.0);
}
