#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;

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
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.1 + vec2(1.3, 0.7);
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 st = uv * 2.0 - 1.0;
    st.x *= u_resolution.x / u_resolution.y;

    float t = u_time * 0.3;
    float bass = 0.5 + u_bass_energy * 0.5;
    float shimmer = 0.5 + u_shimmer * 0.5;
    float pulse = 0.5 + u_pulse_amp * 0.5;
    float bright = 0.5 + u_spectral_brightness * 0.5;

    vec2 ledgerUV = uv + vec2(t * 0.05, sin(t * 0.7) * 0.02);
    float ledger = fbm(ledgerUV * 3.0 + vec2(0.0, t * 0.1));
    float ledger2 = fbm(ledgerUV * 6.0 - vec2(t * 0.08, 0.0));

    float threshold = 0.48 + pulse * 0.12 + sin(t * 1.3) * 0.06;
    float governed = smoothstep(threshold - 0.08, threshold + 0.08, ledger);
    float governed2 = smoothstep(threshold - 0.05, threshold + 0.12, ledger2);

    float staticNoise = hash(uv * 300.0 + vec2(floor(u_time * 24.0)));
    float staticField = hash(uv * 80.0 + vec2(floor(u_time * 8.0), 1.7));
    float dissolve = smoothstep(0.6, 1.0, staticNoise) * bass * 0.7;
    float permission = mix(governed, staticField, dissolve * 0.5);

    float breathe = 0.5 + 0.5 * sin(t * 0.8 + ledger * 3.14);
    float breathe2 = 0.5 + 0.5 * cos(t * 0.5 + ledger2 * 2.0);

    float scanLine = smoothstep(0.0, 0.003, fract(uv.y * 80.0 + t * 0.4)) * 0.25 + 0.75;
    float scanLine2 = smoothstep(0.0, 0.002, fract(uv.x * 40.0 - t * 0.2)) * 0.15 + 0.85;

    vec3 colA = vec3(0.72, 0.28, 0.55);
    vec3 colB = vec3(0.18, 0.62, 0.78);
    vec3 colC = vec3(0.95, 0.82, 0.30);
    vec3 colD = vec3(0.10, 0.38, 0.55);

    vec3 base = mix(colD, colB, ledger * 1.2);
    base = mix(base, colA, governed * breathe * 0.8);
    base = mix(base, colC, governed2 * breathe2 * shimmer * 0.6);

    float staticColor = hash(uv * 150.0 + vec2(u_time * 13.0, 3.3));
    vec3 staticTint = mix(vec3(0.55, 0.55, 0.65), vec3(0.85, 0.70, 0.90), staticColor);
    base = mix(base, staticTint, dissolve * 0.55);

    float glow = exp(-length(st) * 1.2) * bright * 0.6;
    base += vec3(0.30, 0.18, 0.45) * glow;

    float ledgerLine = smoothstep(0.01, 0.0, abs(fract(uv.y * 12.0 + breathe * 0.3) - 0.5) - 0.46);
    base += vec3(0.60, 0.85, 0.95) * ledgerLine * permission * 0.5;

    base *= scanLine * scanLine2;

    float lum = dot(base, vec3(0.299, 0.587, 0.114));
    base = mix(base, base * (0.4 + bright * 0.6), 0.3);
    base = mix(vec3(lum), base, 1.2);

    base = clamp(base * 1.1 + 0.05, 0.0, 1.0);
    base = pow(base, vec3(0.88));

    fragColor = vec4(base, 1.0);
}