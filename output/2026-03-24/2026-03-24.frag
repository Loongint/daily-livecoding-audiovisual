#version 330
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_mid_pressure;
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
        v += noise(p) * amp;
        p = p * 2.1 + vec2(1.3, 0.7);
        amp *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - u_resolution * 0.5) / u_resolution.y;
    float t = u_time * 0.4;

    float bass = clamp(u_bass_energy, 0.0, 1.0);
    float shimmer = clamp(u_shimmer, 0.0, 1.0);
    float pulse = clamp(u_pulse_amp, 0.0, 1.0);
    float brightness = clamp(u_spectral_brightness, 0.0, 1.0);
    float pressure = clamp(u_mid_pressure, 0.0, 1.0);

    float collapse = sin(t * 0.3) * 0.5 + 0.5;
    float dist = length(uv);

    vec2 warp = uv;
    warp += vec2(fbm(uv * 3.0 + t * 0.5) - 0.5, fbm(uv * 3.0 + t * 0.5 + 5.2) - 0.5) * (0.3 + bass * 0.4);

    float layers = 0.0;
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float scale = 2.0 + fi * 1.5;
        float speed = t * (0.3 + fi * 0.12);
        vec2 lp = warp * scale + vec2(speed, speed * 0.7);
        float n = fbm(lp);
        float compress = 1.0 + collapse * 2.0 + bass * 1.5;
        n = pow(n, compress);
        layers += n / (fi + 1.5);
    }
    layers = clamp(layers, 0.0, 1.0);

    float rupture = smoothstep(0.6, 1.0, layers);
    float ruptureAnim = sin(t * 8.0 + dist * 15.0) * 0.5 + 0.5;
    rupture *= ruptureAnim * (0.5 + pulse * 0.5);

    float edge = smoothstep(0.6, 0.0, dist);
    float centripetal = exp(-dist * (3.0 + collapse * 4.0 + bass * 3.0));

    float flickerNoise = fbm(uv * 12.0 + t * 3.0 + vec2(sin(t * 7.3), cos(t * 5.1)));
    float flicker = pow(flickerNoise, 6.0 - shimmer * 3.0);
    float peripheral = smoothstep(0.2, 0.7, dist) * flicker * (0.5 + shimmer * 0.8);

    vec3 deepColor = vec3(0.08, 0.02, 0.18);
    vec3 pressureColor = vec3(0.4, 0.1, 0.6);
    vec3 ruptureColor = vec3(1.0, 0.5, 0.1);
    vec3 flickerColor = vec3(0.8, 0.9, 1.0);
    vec3 coreColor = vec3(0.9, 0.7, 1.0);

    vec3 col = deepColor;
    col = mix(col, pressureColor, layers * (0.6 + collapse * 0.4));
    col = mix(col, coreColor, centripetal * (0.4 + brightness * 0.4));
    col += ruptureColor * rupture * (0.8 + pulse * 0.6);
    col += flickerColor * peripheral * (0.4 + shimmer * 0.5);

    float signalLine = abs(sin(uv.y * 40.0 + t * 6.0 + fbm(vec2(uv.y * 3.0, t)) * 4.0));
    signalLine = pow(1.0 - signalLine, 12.0 + pressure * 8.0);
    col += vec3(0.5, 0.8, 0.4) * signalLine * (0.3 + pressure * 0.5) * edge;

    float radialPulse = sin(dist * 20.0 - t * 5.0 + collapse * 6.28) * 0.5 + 0.5;
    radialPulse = pow(radialPulse, 4.0) * centripetal * 0.4;
    col += vec3(1.0, 0.3, 0.5) * radialPulse * (0.3 + bass * 0.5);

    col = clamp(col, 0.0, 1.0);

    float lift = 0.15 + brightness * 0.1 + collapse * 0.08;
    col = col * 0.85 + lift;
    col = clamp(col, 0.0, 1.0);

    col = pow(col, vec3(0.85));

    fragColor = vec4(col, 1.0);
}