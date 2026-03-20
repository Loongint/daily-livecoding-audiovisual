#version 330
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_threshold_heat;

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

vec3 hotColor(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 c0 = vec3(0.6, 0.05, 0.3);
    vec3 c1 = vec3(1.0, 0.3, 0.0);
    vec3 c2 = vec3(1.0, 0.9, 0.2);
    vec3 c3 = vec3(1.0, 1.0, 1.0);
    if (t < 0.33) return mix(c0, c1, t / 0.33);
    if (t < 0.66) return mix(c1, c2, (t - 0.33) / 0.33);
    return mix(c2, c3, (t - 0.66) / 0.34);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    float t = u_time;

    float bass = clamp(u_bass_energy, 0.0, 1.0);
    float shimmer = clamp(u_shimmer, 0.0, 1.0);
    float pulse = clamp(u_pulse_amp, 0.0, 1.0);
    float bright = clamp(u_spectral_brightness, 0.0, 1.0);
    float heat = clamp(u_threshold_heat, 0.0, 1.0);

    vec2 center = uv;
    float dist = length(center);

    float angle = atan(center.y, center.x);
    float spiral = sin(angle * 6.0 + dist * 12.0 - t * 3.0 + bass * 4.0) * 0.5 + 0.5;

    vec2 warp = vec2(
        fbm(uv * 2.5 + vec2(t * 0.3, 0.0)),
        fbm(uv * 2.5 + vec2(0.0, t * 0.25 + 1.7))
    );
    vec2 warped = uv + warp * (0.3 + pulse * 0.3);

    float field = fbm(warped * 3.0 + t * 0.4);
    float field2 = fbm(warped * 5.5 - t * 0.6 + vec2(3.3, 1.1));

    float threshold = 0.5 + sin(t * 1.7) * 0.05 + heat * 0.15;
    float edge = abs(field - threshold);
    float glow = smoothstep(0.18, 0.0, edge) * (1.0 + shimmer * 2.0);

    float pressure = pow(max(0.0, 1.0 - dist * 1.4), 1.5);
    pressure *= 0.6 + fbm(uv * 4.0 + t * 0.5) * 0.6;

    float ignition = smoothstep(0.6, 1.0, field * (0.8 + bass * 0.5));
    ignition += smoothstep(0.7, 1.0, field2 * (0.7 + pulse * 0.6)) * 0.7;
    ignition = clamp(ignition, 0.0, 1.0);

    float tremor = sin(uv.x * 40.0 + t * 8.0) * sin(uv.y * 35.0 - t * 7.0);
    tremor = tremor * 0.5 + 0.5;
    tremor *= pulse * 0.3;

    float base = field * 0.5 + field2 * 0.3 + pressure * 0.4;
    base += glow * 0.6;
    base += ignition * 0.5;
    base += spiral * 0.15 * (0.5 + bass);
    base += tremor * 0.2;
    base = clamp(base, 0.0, 1.0);

    float colorShift = field * 0.6 + ignition * 0.4 + shimmer * 0.2 + bright * 0.3;
    colorShift = clamp(colorShift, 0.0, 1.0);

    vec3 col = hotColor(colorShift);

    col *= (0.7 + base * 0.8);
    col += vec3(0.8, 0.4, 0.1) * glow * 0.9;
    col += vec3(1.0, 0.9, 0.5) * ignition * 0.6 * (0.5 + bright * 0.5);
    col += vec3(0.9, 0.1, 0.5) * tremor * 0.4;

    float rim = pow(clamp(1.0 - dist * 0.9, 0.0, 1.0), 0.5);
    col *= (0.5 + rim * 0.7);

    col = clamp(col, 0.0, 1.0);

    col = pow(col, vec3(0.85));

    col = max(col, vec3(0.05, 0.02, 0.04));

    fragColor = vec4(col, 1.0);
}