#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass;
uniform float u_mid;
uniform float u_high;
uniform float u_onset;
uniform float u_spectral_centroid;

out vec4 fragColor;

float hash(vec2 p) {
    float h = dot(p, vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i), b = hash(i + vec2(1,0));
    float c = hash(i + vec2(0,1)), d = hash(i + vec2(1,1));
    return mix(mix(a,b,f.x), mix(c,d,f.x), f.y);
}

float fbm(vec2 p, float t) {
    float v = 0.0, a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for(int i = 0; i < 5; i++) {
        v += a * noise(p + t * 0.1 * float(i + 1));
        p = rot * p * 2.1;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    float t = u_time;
    float bass = u_bass * 0.5 + 0.5;
    float mid = u_mid * 0.3 + 0.5;
    float high = u_high * 0.2 + 0.3;
    float onset = u_onset;
    float sc = u_spectral_centroid * 0.3 + 0.5;

    // jurisdictional grid — case by case
    float gridScale = 8.0 + 4.0 * sin(t * 0.13);
    vec2 gid = floor(uv * gridScale);
    vec2 gf = fract(uv * gridScale) - 0.5;
    float cellHash = hash(gid + floor(t * 0.7));
    float cellPhase = hash(gid * 1.3 + 7.0);

    // each cell judged independently — suspension probability
    float suspended = step(0.35 + 0.15 * sin(t * 0.3), cellHash);
    float reviewed = smoothstep(0.0, 0.08, abs(sin(cellPhase * 6.28 + t * (0.5 + cellHash))));

    // tension field across frame
    float f1 = fbm(uv * 3.0 + vec2(t * 0.15, 0.0), t);
    float f2 = fbm(uv * 3.0 - vec2(0.0, t * 0.12), t * 0.7);
    float tension = abs(f1 - f2);
    tension = pow(tension, 0.7) * 1.8;

    // the taut wire — pressure boundary
    float wireY = 0.02 * sin(uv.x * 12.0 + t * 1.3) + 0.01 * sin(uv.x * 27.0 - t * 2.1);
    float wireDist = abs(uv.y - wireY);
    float wire = smoothstep(0.008 + 0.003 * bass, 0.0, wireDist);
    wire *= 0.7 + 0.3 * sin(uv.x * 40.0 + t * 5.0);

    // grid edges — jurisdiction boundaries
    float edgeX = smoothstep(0.06, 0.0, abs(gf.x) - 0.44);
    float edgeY = smoothstep(0.06, 0.0, abs(gf.y) - 0.44);
    float gridEdge = max(edgeX, edgeY) * (0.3 + 0.2 * suspended);
    gridEdge *= reviewed;

    // scan pressure
    float scan = smoothstep(0.015, 0.0, abs(uv.y - mod(t * 0.25, 2.0) + 1.0));
    scan += smoothstep(0.01, 0.0, abs(uv.x - mod(t * 0.18 + 0.5, 2.0) + 1.0)) * 0.5;

    // accumulate luminance — ensure visible range
    float lum = 0.18;
    lum += tension * 0.45;
    lum += gridEdge * 0.25;
    lum += wire * 0.5;
    lum += scan * 0.2;
    lum += suspended * 0.08 * smoothstep(0.3, 0.0, length(gf));
    lum += onset * 0.25 * smoothstep(0.5, 0.0, length(uv));

    // flickering disruption per cell
    float flicker = step(0.92 - onset * 0.15, hash(gid + floor(t * 3.7)));
    lum += flicker * 0.35;

    // pressure coloring — cold steel blue to hot white
    vec3 cold = vec3(0.38, 0.42, 0.52);
    vec3 mid_tone = vec3(0.58, 0.56, 0.62);
    vec3 hot = vec3(0.88, 0.85, 0.92);
    vec3 accent = vec3(0.75, 0.45, 0.42);

    lum = clamp(lum, 0.12, 1.0);
    vec3 col = mix(cold, mid_tone, smoothstep(0.15, 0.45, lum));
    col = mix(col, hot, smoothstep(0.45, 0.85, lum));
    col = mix(col, accent, wire * 0.6 * (0.5 + 0.5 * sin(t * 0.7)));

    // vignette — pressure from edges, not darkness
    float vig = smoothstep(1.1, 0.3, length(uv * vec2(0.9, 1.0)));
    col = mix(cold * 0.55, col, 0.4 + 0.6 * vig);

    // grain — case-by-case noise
    float grain = (hash(gl_FragCoord.xy + fract(t)) - 0.5) * 0.06;
    col += grain;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}