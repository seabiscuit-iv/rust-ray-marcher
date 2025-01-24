#version 300 es

precision mediump float;


layout(location = 0) in vec4 vs_pos;
layout(location = 1) in vec4 vs_col;
layout(location = 2) in vec2 vs_uv;

out vec4 fs_col;
out vec2 fs_uv; 

uniform mat4 u_InvViewProj;
uniform mat4 u_ViewProj;
uniform float aspectRatio;


void main() {
    // fs_col = vs_col;
    fs_uv = vec2(vs_pos);

    vec4 pos = vs_pos;

    // pos =  u_ViewProj * pos;
    // pos.x /= aspectRatio;
    // pos.z = 0;
    // pos /= pos.w;
    fs_col = pos;
    fs_uv = vec2(pos);

    // gl_Position = pos;
    gl_Position = vs_pos;
}