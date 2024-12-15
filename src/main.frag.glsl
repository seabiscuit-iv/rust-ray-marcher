#version 330 core

in vec4 fs_col;
in vec2 fs_uv;

uniform mat4 u_ViewProj;
uniform mat4 u_InvViewProj;
uniform vec3 u_CamPos;

uniform vec3 u_SpherePos;

uniform float u_Time;

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


float mandelbulb(vec3 c) {
    int iterations = 20;
    // float power = 8.0;
    float power = u_Time;
    float dr = 1.0;
    float r = 0.0;

    vec3 w = c;
   
    for(int i = 0; i < iterations; i++) {
        r = length(w);
        if (r > 2.0) break;

        float wr = sqrt(dot(w,w));
        float wo = acos(w.y/wr);
        float wi = atan(w.x,w.z);

        dr = pow(r, power - 1.0) * power * dr + 1.0;

        wr = pow( wr, 8.0 );
        wo = wo * 8.0;
        wi = wi * 8.0;

        w.x = wr * sin(wo)*sin(wi);
        w.y = wr * cos(wo);
        w.z = wr * sin(wo)*cos(wi);

        w += c;
    }

    return 0.5 * log(r) * r / dr; // Distance estimation formula
}


vec4 fiveColorGradient(float t) {
    // Clamp t to the range [0.0, 1.0]
    t = clamp(t, 0.0, 1.0);

    vec4 color1 = vec4(0.4, 0.0, 0.1, 1.0);
    vec4 color2 = vec4(0.5, 0.0, 0.1, 1.0);
    vec4 color3 = vec4(0.6, 0.0, 0.3, 1.0);
    vec4 color4 = vec4(0.8, 0.0, 0.4, 1.0);
    vec4 color5 = vec4(0.8, 0.0, 0.6, 1.0);

    // Determine which segment of the gradient t falls into
    if (t < 0.25) {
        float localT = t / 0.25; // Map t from [0.0, 0.25] to [0.0, 1.0]
        return mix(color1, color2, localT);
    } else if (t < 0.5) {
        float localT = (t - 0.25) / 0.25; // Map t from [0.25, 0.5] to [0.0, 1.0]
        return mix(color2, color3, localT);
    } else if (t < 0.75) {
        float localT = (t - 0.5) / 0.25; // Map t from [0.5, 0.75] to [0.0, 1.0]
        return mix(color3, color4, localT);
    } else {
        float localT = (t - 0.75) / 0.25; // Map t from [0.75, 1.0] to [0.0, 1.0]
        return mix(color4, color5, localT);
    }
}


vec3 getNormal(vec3 p) {
    //d is distance of the active ray
    float d = mandelbulb(p);
    vec2 e = vec2(0.001, 0);
    vec3 n = d - vec3(
        mandelbulb(p - e.xyy),
        mandelbulb(p - e.yxy),
        mandelbulb(p - e.yyx)
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

    const vec3 sphereCol = vec3(1, 0.2, 0.7);
    const vec3 boxCol = vec3(0.1, 1.0, 0.2);
    vec3 color = vec3(0, 0, 0);

    float value;

    vec3 hitPos;

    while(t < 500.0) {
        // float sphereHit = sdSphere(getRayPos(ray, t) - u_SpherePos, 20);
        // float boxHit = sdBox(getRayPos(ray, t), vec3(25));
        // float hitDist = smin(sphereHit, boxHit, 2.0);
        float hitDist = mandelbulb(getRayPos(ray, t));

        if (hitDist < 0.0004) {
            hit = true;
            dist = t;
            hitPos = getRayPos(ray, t);
            value = length(hitPos);
            break;
        }
        t += hitDist;
    }

    if(!hit) {  
        frag_color = vec4(0, 0, 0, 0);
    } else {
        //max(0.3, 1-(t/10.0))*
        // float lightVal = dot(getNormal(hitPos), normalize(vec3(0, -1, -1)));
        // frag_color = (max(0.5+lightVal/2, 0.6))*(fiveColorGradient(value / 1.0));
        frag_color = vec4(getNormal(hitPos), 0.0);
        // vec3 normal = (getNormal(hitPos) + 1) * 0.5;

        // vec3 first = vec3(0.66, 0.87, 0.886) * 2;
        // vec3 second = vec3(0.815, 0.639, 0.804) * 2;
        // vec3 third = vec3(0.96, 0.85, 0.882) * 2;

        // frag_color = vec4(((vec3(1.0, .4, 0.6) * normal.x) + (vec3(.3, .1, 0.8) * normal.y)), 1.0);
    }
}