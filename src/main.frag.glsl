#version 330 core

in vec4 fs_col;
in vec2 fs_uv;

uniform mat4 u_ViewProj;
uniform mat4 u_InvViewProj;
uniform vec3 u_CamPos;

out vec4 frag_color;

struct Ray {
    vec3 origin;
    vec3 direction;
};

vec3 getRayPos(Ray ray, float t) {
    return ray.origin + t * ray.direction;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

void main() {
    //Ray Marching Time
    Ray ray;
    vec4 ndc = vec4(fs_uv, -1.0, 1.0);

    vec4 near = u_InvViewProj * ndc;
    near /= near.w;

    ndc.z = 1.0;
    vec4 far = u_InvViewProj * ndc;
    far /= far.w;

    vec3 dir = normalize(vec3(far) - vec3(near));

    ray.direction = dir;
    ray.origin = u_CamPos;

    float t = 0;

    bool hit = false;


    while(t < 150.0) {
        float hitDist = sdSphere(getRayPos(ray, t), 4.0);
        if (hitDist < 0.1) {
            hit = true;
            break;
        }

        t += 1;
    }

    if(!hit) {
        frag_color = vec4(0, 0, 0, 0);
    } else {
        frag_color = fs_col;
    }
}