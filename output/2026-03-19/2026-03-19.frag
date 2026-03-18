#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_humid_drone;
uniform float u_mist_density;
uniform float u_breath_amp;
uniform float u_veil_shimmer;
uniform float u_low_pulse;

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
    float freq = 1.0;
    for (int i = 0; i < 5; i++) {
        v += amp * noise(p * freq);
        amp *= 0.5;
        freq *= 2.1;
    }
    return v;
}

float moonSDF(vec2 uv, float phase) {
    float r = 0.13;
    float d = length(uv);
    float crescent = length(uv - vec2(phase * 0.18, 0.0));
    return smoothstep(r, r - 0.004, d) - smoothstep(r - 0.01, r - 0.018, crescent);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

    float t = u_time * 0.04;
    float slowT = u_time * 0.012;

    vec2 mistUV = uv * 2.2 + vec2(t * 0.3, t * 0.15);
    float mist1 = fbm(mistUV + vec2(slowT * 0.4, 0.0));
    float mist2 = fbm(mistUV * 1.6 - vec2(0.0, slowT * 0.3));
    float mistLayer = mix(mist1, mist2, 0.5 + 0.5 * sin(slowT * 0.7));
    mistLayer = pow(mistLayer, 1.2 - u_mist_density * 0.4);

    vec3 deepGrey = vec3(0.10, 0.12, 0.11);
    vec3 mistGreen = vec3(0.22, 0.28, 0.22);
    vec3 warmVeil = vec3(0.30, 0.32, 0.24);
    vec3 moonGlow = vec3(0.72, 0.76, 0.65);

    float breathe = 0.5 + 0.5 * sin(u_time * 0.18 + u_breath_amp * 1.5);
    float droneWave = 0.5 + 0.5 * sin(u_time * 0.07 * (1.0 + u_humid_drone * 0.5));

    vec3 bg = mix(deepGrey, mistGreen, mistLayer * 0.85);
    bg = mix(bg, warmVeil, droneWave * 0.25 * (1.0 + u_humid_drone * 0.4));

    vec2 moonPos = uv - vec2(0.0, 0.18);
    float veilNoise = fbm(uv * 3.5 + vec2(slowT, slowT * 0.5)) * 0.6;
    float moonMask = moonSDF(moonPos, 0.043345750084647194);
    float veilOver = smoothstep(0.0, 1.0, veilNoise + u_veil_shimmer * 0.3);
    float moonVisible = clamp(moonMask * (1.0 - veilOver * 0.75), 0.0, 1.0);

    float halo = exp(-length(moonPos) * 7.0) * 0.35 * (1.0 + u_low_pulse * 0.4);
    halo *= (0.8 + 0.2 * breathe);

    vec3 col = bg;
    col += moonGlow * halo;
    col = mix(col, moonGlow * 0.95, moonVisible * (0.85 + u_veil_shimmer * 0.15));

    float vignette = 1.0 - smoothstep(0.3, 1.1, length(uv * vec2(0.9, 1.1)));
    col *= vignette;

    float dissolve = fbm(uv * 1.8 + vec2(0.0, slowT * 0.6));
    col = mix(col, col * vec3(0.95, 1.02, 0.96), dissolve * 0.18);

    float gamma = 0.88 + u_breath_amp * 0.06;
    col = pow(clamp(col, 0.0, 1.0), vec3(gamma));

    fragColor = vec4(col, 1.0);
}