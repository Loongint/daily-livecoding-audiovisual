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

vec3 ledgerLines(vec2 uv, float t) {
    float lineY = fract(uv.y * 18.0 - t * 0.12);
    float line = smoothstep(0.04, 0.0, abs(lineY - 0.5) - 0.44);
    float erasure = fbm(uv * 3.0 + t * 0.05);
    line *= smoothstep(0.3, 0.7, erasure);
    float col = line * (0.55 + 0.35 * u_spectral_brightness);
    return vec3(col * 0.6, col * 0.75, col * 0.9);
}

vec3 staticNoise(vec2 uv, float t) {
    float s1 = hash(uv * 512.0 + t * 73.1);
    float s2 = hash(uv * 256.0 - t * 41.3);
    float s = mix(s1, s2, 0.5);
    s = pow(s, 2.2);
    float intensity = 0.28 + 0.18 * u_bass_energy;
    return vec3(s * intensity * 0.7, s * intensity * 0.8, s * intensity);
}

vec3 pulsingForm(vec2 uv, float t) {
    vec2 center = vec2(0.5, 0.5);
    float dist = length(uv - center);
    float pulse = 0.5 + 0.5 * sin(t * 1.8 + u_pulse_amp * 3.14);
    float ring = exp(-pow(dist - 0.28 * pulse, 2.0) * 18.0);
    float inner = exp(-dist * dist * 6.0) * 0.7;
    float erasedPhase = fract(t * 0.07);
    float erased = smoothstep(0.0, 0.4, erasedPhase) * smoothstep(1.0, 0.6, erasedPhase);
    float form = (ring + inner) * erased;
    vec3 cold = vec3(0.3, 0.55, 0.85);
    vec3 hot = vec3(0.85, 0.4, 0.6);
    return mix(cold, hot, u_shimmer) * form * (0.9 + 0.5 * u_pulse_amp);
}

vec3 breathingField(vec2 uv, float t) {
    float f = fbm(uv * 2.5 + t * 0.08);
    float f2 = fbm(uv * 4.0 - t * 0.13 + 1.7);
    float field = f * f2;
    float breathe = 0.55 + 0.45 * sin(t * 0.6);
    vec3 tint = mix(
        vec3(0.15, 0.25, 0.45),
        vec3(0.45, 0.2, 0.55),
        f2
    );
    return tint * field * breathe * (0.7 + 0.5 * u_spectral_brightness);
}

vec3 complianceGlyph(vec2 uv, float t) {
    vec2 g = fract(uv * 6.0) - 0.5;
    float cell = hash(floor(uv * 6.0) + floor(t * 0.4));
    float appear = step(0.6, cell);
    float stamp = smoothstep(0.45, 0.0, length(g)) * appear;
    float fade = fract(t * 0.15 + cell);
    stamp *= smoothstep(1.0, 0.5, fade);
    return vec3(0.7, 0.6, 0.3) * stamp * 0.65;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    float t = u_time;

    vec3 base = breathingField(uv, t);
    vec3 ledger = ledgerLines(uv, t);
    vec3 stat = staticNoise(uv, t);
    vec3 form = pulsingForm(uv, t);
    vec3 glyph = complianceGlyph(uv, t);

    vec3 col = base + ledger + stat * 0.6 + form + glyph;

    float vignette = 1.0 - 0.45 * pow(length(uv - 0.5) * 1.6, 2.0);
    col *= vignette;

    float flicker = 0.88 + 0.12 * hash(vec2(t * 60.0, 0.5));
    col *= flicker;

    col = pow(clamp(col, 0.0, 1.0), vec3(0.88));

    fragColor = vec4(col, 1.0);
}