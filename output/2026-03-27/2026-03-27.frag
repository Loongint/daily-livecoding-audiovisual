#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_gate_rhythm;

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

float grid(vec2 uv, float scale, float thickness) {
    vec2 g = fract(uv * scale);
    float lx = smoothstep(thickness, 0.0, g.x) + smoothstep(1.0 - thickness, 1.0, g.x);
    float ly = smoothstep(thickness, 0.0, g.y) + smoothstep(1.0 - thickness, 1.0, g.y);
    return clamp(lx + ly, 0.0, 1.0);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    float t = u_time * 0.3;

    float bass = clamp(u_bass_energy, 0.0, 1.0);
    float shimmer = clamp(u_shimmer, 0.0, 1.0);
    float pulse = clamp(u_pulse_amp, 0.0, 1.0);
    float bright = clamp(u_spectral_brightness, 0.0, 1.0);
    float gate = clamp(u_gate_rhythm, 0.0, 1.0);

    float thermalDrift = noise(uv * 3.0 + vec2(t * 0.4, t * 0.2)) * 0.5
                       + noise(uv * 7.0 - vec2(t * 0.3, t * 0.5)) * 0.3;

    vec2 distorted = uv + vec2(
        noise(uv * 5.0 + t * 0.2) - 0.5,
        noise(uv * 5.0 + t * 0.2 + 3.7) - 0.5
    ) * (0.04 + bass * 0.06);

    float gridScale1 = 6.0 + bass * 3.0;
    float gridScale2 = 12.0 + pulse * 4.0;
    float decay = noise(uv * 2.0 + vec2(t * 0.15, -t * 0.1));
    float dissolveThresh = 0.3 + thermalDrift * 0.5 + gate * 0.2;

    float g1 = grid(distorted, gridScale1, 0.04 + bass * 0.03);
    float g2 = grid(distorted, gridScale2, 0.025 + shimmer * 0.02);

    float dissolve1 = g1 * step(decay, dissolveThresh);
    float dissolve2 = g2 * step(decay + 0.1, dissolveThresh + 0.15);

    float cellNoise = noise(floor(distorted * gridScale1) + vec2(t * 0.5, 0.0));
    float cellFlicker = step(0.5 + gate * 0.3, cellNoise) * (0.4 + pulse * 0.4);

    float scanLine = sin(uv.y * 80.0 + t * 5.0) * 0.5 + 0.5;
    scanLine = pow(scanLine, 6.0) * (0.3 + shimmer * 0.4);

    float thermal = smoothstep(0.2, 0.9, thermalDrift);

    vec3 colBase = mix(
        vec3(0.05, 0.18, 0.28),
        vec3(0.55, 0.22, 0.08),
        thermal * (0.5 + bass * 0.5)
    );

    vec3 colGrid1 = mix(vec3(0.2, 0.75, 0.85), vec3(0.9, 0.5, 0.1), bass);
    vec3 colGrid2 = mix(vec3(0.7, 0.9, 0.5), vec3(1.0, 0.8, 0.2), shimmer);
    vec3 colCell = mix(vec3(0.9, 0.3, 0.6), vec3(1.0, 0.9, 0.4), pulse);

    vec3 col = colBase * (0.5 + thermal * 0.5);
    col += colGrid1 * dissolve1 * (0.6 + bass * 0.4);
    col += colGrid2 * dissolve2 * (0.4 + shimmer * 0.5);
    col += colCell * cellFlicker;
    col += vec3(0.6, 0.8, 1.0) * scanLine * (0.2 + bright * 0.3);

    float emptyGate = smoothstep(0.6, 1.0, gate);
    col = mix(col, vec3(0.85, 0.92, 1.0) * (0.3 + bright * 0.4), emptyGate * dissolve1 * 0.6);

    float vignette = 1.0 - smoothstep(0.4, 1.2, length(uv));
    col *= 0.6 + vignette * 0.4;

    col = clamp(col, 0.0, 1.0);
    col = pow(col, vec3(0.85));

    float minBright = 0.12 + bright * 0.1;
    col = max(col, vec3(minBright * 0.5, minBright * 0.6, minBright * 0.7));

    fragColor = vec4(col, 1.0);
}