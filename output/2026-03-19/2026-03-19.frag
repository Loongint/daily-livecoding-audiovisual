#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_feedback_tension;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        v += amp * noise(p);
        p = p * 2.1 + vec2(1.3, 0.7);
        amp *= 0.5;
    }
    return v;
}

vec3 staticGrain(vec2 uv, float t) {
    float g = hash(uv * 300.0 + vec2(t * 17.3, t * 9.1));
    return vec3(g);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 centered = uv * 2.0 - 1.0;
    centered.x *= u_resolution.x / u_resolution.y;

    float t = u_time * 0.4;
    float bass = clamp(u_bass_energy, 0.0, 1.0);
    float shimmer = clamp(u_shimmer, 0.0, 1.0);
    float pulse = clamp(u_pulse_amp, 0.0, 1.0);
    float bright = clamp(u_spectral_brightness, 0.0, 1.0);
    float tension = clamp(u_feedback_tension, 0.0, 1.0);

    vec2 grip = centered;
    float latency = sin(t * 3.7 + fbm(grip * 2.0 + t * 0.3) * 6.28) * 0.5 + 0.5;
    grip += vec2(
        sin(t * 1.3 + centered.y * 4.0) * 0.08 * (1.0 + bass),
        cos(t * 1.7 + centered.x * 3.5) * 0.08 * (1.0 + pulse)
    );

    float dist = length(grip);
    float angle = atan(grip.y, grip.x);

    float rings = sin(dist * 18.0 - t * 5.0 + bass * 6.28) * 0.5 + 0.5;
    rings *= sin(dist * 7.0 + t * 2.3) * 0.5 + 0.5;

    float spiral = sin(angle * 5.0 + dist * 12.0 - t * 4.0 + tension * 3.14) * 0.5 + 0.5;

    float field = fbm(grip * 3.5 + vec2(t * 0.5, t * 0.3));
    float field2 = fbm(grip * 5.0 - vec2(t * 0.4, t * 0.6) + field);

    float collapse = smoothstep(0.8, 0.0, dist) * (1.0 + bass * 0.5);
    float staticNoise = hash(uv * (200.0 + tension * 300.0) + vec2(floor(t * 24.0) * 0.1));
    float staticLayer = pow(staticNoise, 3.0) * (0.3 + tension * 0.7);

    float vibration = sin(t * 60.0 * (1.0 + tension) + dist * 30.0) * 0.5 + 0.5;
    vibration *= smoothstep(0.6, 0.2, dist) * tension * 0.5;

    float core = rings * 0.4 + spiral * 0.3 + field2 * 0.3;
    core = core * collapse + staticLayer * 0.4 + vibration;

    vec3 colA = vec3(0.85, 0.35, 0.15);
    vec3 colB = vec3(0.15, 0.55, 0.85);
    vec3 colC = vec3(0.95, 0.85, 0.45);
    vec3 colStatic = vec3(0.75, 0.72, 0.70);

    float blend = field * 0.5 + latency * 0.5;
    vec3 color = mix(colA, colB, blend);
    color = mix(color, colC, spiral * bright * 0.6);
    color = mix(color, colStatic, staticLayer * 0.5);

    color *= (0.5 + core * 1.2);
    color += shimmer * 0.3 * vec3(0.9, 0.85, 1.0) * (sin(t * 8.0 + dist * 10.0) * 0.5 + 0.5);
    color += pulse * 0.25 * colA * rings;

    float grain = (hash(uv * 512.0 + vec2(t * 31.0)) - 0.5) * 0.06;
    color += grain;

    float vignette = 1.0 - smoothstep(0.5, 1.4, dist);
    color *= 0.4 + vignette * 0.8;

    color = clamp(color, 0.0, 1.0);
    color = pow(color, vec3(0.85));

    fragColor = vec4(color, 1.0);
}