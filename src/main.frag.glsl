#version 330 core

in vec4 fs_col;
in vec2 fs_uv;

uniform mat4 u_ViewProj;
uniform mat4 u_InvViewProj;
uniform vec3 u_CamPos;
uniform float u_Exp;

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

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float smin( float a, float b, float k )
{
    k *= 1.0;
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}


float smincolor( float a, float b, vec3 a_col, vec3 b_col, float k )
{
    k *= 1.0;
    float r = exp2(-a/k) + exp2(-b/k);
    return -k*log2(r);
}

vec3 cart2polar(vec3 cart) {
    float r = length(cart); // Radius
    float theta = atan(cart.y, cart.x); // Azimuthal angle
    float phi = acos(cart.z / r); // Polar angle

    return vec3(r, theta, phi);
}


float mandelbulb(vec3 pos, out float orbit_trap_dist) {
    float power = u_Exp;
    float sphere_rad = 0.5;
    // float sphere_rad = u_Exp;
    // float power = 8.0;
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;

    orbit_trap_dist = 1000000.0;

    for (int i = 0; i < 12; i++) {
        r = length(z);
        if (r > 2.0) break;

        // Convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        dr = pow(r, power - 1.0) * power * dr + 1.0;

        // Scale and rotate
        float zr = pow(r, power);
        theta *= power;
        phi *= power;

        // Convert back to cartesian coordinates
        z = zr * vec3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
        z += pos;

        float dist = sdSphere(z, sphere_rad);
        orbit_trap_dist = min(orbit_trap_dist, dist);
    }

    return 0.5 * log(r) * r / dr;
}


vec3 gradient(float t) {
    t = clamp(t, 0.0, 1.0);

    vec3 darkBlue = vec3(0.0, 0.0, 0.1);  // Extremely dark blue
    vec3 softPink = vec3(0.8, 0.5, 0.6);  // Not super light pink

    return mix(darkBlue, softPink, t);
}




vec3 getNormal(vec3 p) {
    //d is distance of the active ray
    float tmp;
    float d = mandelbulb(p, tmp);
    vec2 e = vec2(0.001, 0);
    vec3 n = d - vec3(
        mandelbulb(p - e.xyy, tmp),
        mandelbulb(p - e.yxy, tmp),
        mandelbulb(p - e.yyx, tmp)
    );

    return normalize(n);
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
    float dist = 0;
    float orbit_trap;
 

    const vec3 sphereCol = vec3(1, 0.2, 0.7);
    const vec3 boxCol = vec3(0.1, 1.0, 0.2);
    vec3 color = vec3(0, 0, 0);

    float value;

    vec3 hitPos;

    while(t < 500.0) {
        // float sphereHit = sdSphere(getRayPos(ray, t) - u_SpherePos, 20);
        // float boxHit = sdBox(getRayPos(ray, t), vec3(25));
        // float hitDist = smin(sphereHit, boxHit, 2.0);
        float hitDist = mandelbulb(getRayPos(ray, t), orbit_trap);
        
        if (hitDist < 0.0001) {
            hit = true;
            dist = t;
            hitPos = getRayPos(ray, t);
            value = length(hitPos);
            break;
        }
        t += hitDist;
    }

    if(!hit) {  
        frag_color = vec4(0.1, 0.15, 0.25, 1.0);
    } else {
        //max(0.3, 1-(t/10.0))*
        // float lightVal = dot(getNormal(hitPos), normalize(vec3(0, -1, -1)));
        // frag_color = (max(0.5+lightVal/2, 0.6))*(fiveColorGradient(value / 1.0));
        // frag_color = vec4(getNormal(hitPos), 0.0);
        vec3 normal = getNormal(hitPos);
        normal = (normal + 0.8) / 2;
        // normal = abs(normal);

        // vec3 first = vec3(0.66, 0.87, 0.886) * 2;
        // vec3 second = vec3(0.815, 0.639, 0.804) * 2;
        // vec3 third = vec3(0.96, 0.85, 0.882) * 2;

        float lighting = dot(normalize(normal), vec3(0, 1, 0));
        lighting = (lighting + 1) / 2;

        // lighting = lighting * 0.6  + 0.4;
        lighting = orbit_trap;
        lighting = clamp(lighting, 0, 1);
        // lighting = 1.0;

        // frag_color = vec4(normal, 1.0);
        // frag_color = vec4(lighting * ((vec3(1.0, .4, 0.6) * normal.x) + (vec3(.3, .1, 0.8) * normal.y) + (vec3(.9, .6, .6) * normal.z)), 1.0);
        frag_color = vec4(lighting * ((vec3(1.0, .4, 0.6) * normal.x) + (vec3(.3, .1, 0.8) * normal.y) + (vec3(.9, .6, .6) * normal.z)), 1.0);
        // frag_color = vec4(lighting * vec3(1.0, .71, 0.8), 1.0);
        // frag_color = vec4(vec3(lighting), 1.0);
        // frag_color = vec4(vec3(lighting), 1.0);
    }
}