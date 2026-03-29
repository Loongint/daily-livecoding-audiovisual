#version 330
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_pulse_amp;
uniform float u_shimmer;
uniform float u_spectral_brightness;
uniform float u_tension;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float grid(vec2 uv, float scale, float thickness) {
    vec2 g = fract(uv * scale);
    float lx = smoothstep(thickness, 0.0, min(g.x, 1.0 - g.x));
    float ly = smoothstep(thickness, 0.0, min(g.y, 1.0 - g.y));
    return max(lx, ly);
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

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    float aspect = u_resolution.x / u_resolution.y;
    vec2 uvn = gl_FragCoord.xy / u_resolution;

    float bass = clamp(u_bass_energy, 0.0, 1.0);
    float pulse = clamp(u_pulse_amp, 0.0, 1.0);
    float shimmer = clamp(u_shimmer, 0.0, 1.0);
    float brightness = clamp(u_spectral_brightness, 0.0, 1.0);
    float tension = clamp(u_tension, 0.0, 1.0);

    float t = u_time * 0.3;
    float slowPulse = sin(u_time * 0.7) * 0.5 + 0.5;
    float microPulse = sin(u_time * 3.1 + bass * 6.0) * 0.5 + 0.5;

    float compress = 1.0 + bass * 0.4 + slowPulse * 0.15;
    vec2 compressed = uv * compress;

    float g1 = grid(compressed + vec2(t * 0.05, 0.0), 8.0, 0.04 + pulse * 0.03);
    float g2 = grid(compressed * 0.5 + vec2(0.0, t * 0.03), 4.0, 0.03 + tension * 0.04);
    float g3 = grid(compressed * 2.0 - vec2(t * 0.08, t * 0.04), 16.0, 0.025 + shimmer * 0.02);

    float gridMask = g1 * 0.6 + g2 * 0.4 + g3 * 0.3;
    gridMask = clamp(gridMask, 0.0, 1.0);

    float dist = length(uv);
    float rupture = smoothstep(0.8, 0.2, dist) * (0.3 + bass * 0.5 + tension * 0.3);
    float radialPulse = sin(dist * 12.0 - u_time * 1.5) * 0.5 + 0.5;
    radialPulse *= smoothstep(1.2, 0.0, dist);

    float n = noise(uv * 3.0 + vec2(t * 0.2, t * 0.15));
    float n2 = noise(uv * 7.0 - vec2(t * 0.1, t * 0.3));

    vec3 bgColor = vec3(0.08, 0.12, 0.18);
    bgColor += vec3(0.05, 0.04, 0.02) * n;
    bgColor += vec3(0.02, 0.06, 0.05) * n2;

    vec3 gridColor1 = vec3(0.55, 0.62, 0.75);
    vec3 gridColor2 = vec3(0.75, 0.55, 0.35);
    vec3 gridColor = mix(gridColor1, gridColor2, bass * 0.6 + tension * 0.4);

    vec3 ruptureColor = vec3(0.85, 0.70, 0.40);
    ruptureColor = mix(ruptureColor, vec3(1.0, 0.85, 0.55), shimmer * 0.5 + brightness * 0.4);

    vec3 col = bgColor;
    col += gridColor * gridMask * (0.5 + microPulse * 0.3 + pulse * 0.25);
    col += ruptureColor * rupture * (0.4 + bass * 0.4);
    col += vec3(0.50, 0.65, 0.80) * radialPulse * 0.18 * (0.5 + shimmer * 0.5);

    float centerGlow = exp(-dist * dist * 2.5) * (0.3 + tension * 0.5 + bass * 0.3);
    col += vec3(0.70, 0.60, 0.80) * centerGlow;

    float scanLine = sin(uvn.y * u_resolution.y * 1.5 + u_time * 2.0) * 0.04;
    col += scanLine * gridColor * 0.3;

    float bureaucraticFlat = smoothstep(0.3, 0.7, n) * 0.15;
    col += vec3(0.40, 0.45, 0.50) * bureaucraticFlat * (1.0 - bass * 0.7);

    col = clamp(col, 0.0, 1.0);
    col = pow(col, vec3(0.85));
    col = mix(col, col * col * (3.0 - 2.0 * col), 0.3);

    float vign = smoothstep(1.4, 0.4, dist) * 0.35 + 0.65;
    col *= vign;

    col = clamp(col, 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}