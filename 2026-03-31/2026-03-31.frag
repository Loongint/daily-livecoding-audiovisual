#version 330
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass;
uniform float u_mid;
uniform float u_high;
uniform float u_pressure;
uniform float u_onset;

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
    float v = 0.0, a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    float t = u_time * 0.08;

    float pressure = 0.5 + 0.3 * u_pressure + 0.2 * u_bass;
    float accumulation = 0.5 + 0.5 * sin(t * 0.7) * sin(t * 1.1);
    accumulation = pow(accumulation, 0.3);

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Wider, more visible glass ring
    float glassRadius = 0.55 + 0.02 * sin(angle * 6.0 + t * 3.0);
    float glassDist = abs(r - glassRadius);
    float glass = smoothstep(0.025, 0.0, glassDist);
    glass += smoothstep(0.045, 0.0, glassDist) * 0.4;

    // Internal pressure field
    vec2 distorted = uv + 0.15 * vec2(
        fbm(uv * 3.0 + t * 0.5 + u_mid * 0.3),
        fbm(uv * 3.0 + 10.0 - t * 0.4)
    );

    float heat = fbm(distorted * 2.5 + t * 0.2);
    float heat2 = fbm(distorted * 4.0 - t * 0.15 + 5.0);

    // Intensity: lift floor, widen falloff so mid-range is reachable
    float intensity = heat * 0.6 + heat2 * 0.4;
    // Softer spatial falloff — reaches near glass wall before fading
    intensity *= smoothstep(0.62, 0.05, r);
    // Lift intensity floor so cold zone is still visible, not black
    intensity = intensity * 0.75 + 0.25;
    // Gentle gamma — keep exponent close to 1 so mid values survive
    intensity = pow(intensity, 1.1 - 0.2 * accumulation);

    // Palette
    vec3 cold = vec3(0.08, 0.12, 0.22);
    vec3 warmth = vec3(0.95, 0.55, 0.15);
    vec3 white_hot = vec3(1.0, 0.92, 0.85);
    vec3 frost = vec3(0.45, 0.58, 0.72);

    // inner mask extends to cover whole interior
    float inner = smoothstep(0.60, 0.05, r);

    // Wider smoothstep bands so each palette zone is well represented
    vec3 col = mix(cold, frost, smoothstep(0.22, 0.45, intensity));
    col = mix(col, warmth, smoothstep(0.42, 0.68, intensity) * inner);
    col = mix(col, white_hot, smoothstep(0.65, 0.88, intensity) * inner * (0.5 + 0.5 * accumulation));

    // Frozen rain lines — slightly brighter, wider spatial reach
    float lines = sin(gl_FragCoord.x * 1.5 + noise(vec2(gl_FragCoord.x * 0.01, t)) * 20.0);
    lines = smoothstep(0.95, 1.0, lines) * 0.22 * smoothstep(0.65, 0.1, r);
    col += vec3(0.4, 0.5, 0.65) * lines;

    // Glass membrane — brighter, more visible edge
    col += vec3(0.75, 0.85, 1.0) * glass * (1.2 + 0.6 * u_high);

    // Onset flicker
    float crack = u_onset * smoothstep(0.5, 0.52, r) * smoothstep(0.58, 0.54, r);
    col += vec3(1.0, 0.8, 0.5) * crack * 2.0;

    // Breathing pulsation
    float breath = 0.88 + 0.12 * sin(u_time * 0.5);
    col *= breath;

    // Vignette: fade toward a visible dark blue, not near-black,
    // and only begin fading well outside the glass wall
    vec3 vignetteColor = cold * 0.75;
    col = mix(col, vignetteColor, smoothstep(0.58, 1.1, r));

    // Film grain
    float grain = hash(gl_FragCoord.xy + fract(u_time) * 100.0) * 0.05 - 0.025;
    col += grain;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}