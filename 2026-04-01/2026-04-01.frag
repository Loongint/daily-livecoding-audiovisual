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
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float grid(vec2 uv, float scale, float width) {
    vec2 g = abs(fract(uv * scale) - 0.5);
    float lines = min(g.x, g.y);
    return 1.0 - smoothstep(0.0, width, lines);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    vec2 uv01 = gl_FragCoord.xy / u_resolution;
    float t = u_time;

    // Keep audio inputs in moderate ranges, not biased toward 1.0
    float bass = u_bass * 0.5 + 0.5;
    float mid = u_mid * 0.5 + 0.5;
    float high = u_high * 0.5 + 0.5;
    float onset = u_onset;
    float pressure = u_pressure * 0.5 + 0.5;

    // Base field: centered around mid-grey (0.38) with meaningful swing
    // This gives room both above and below for contrast
    float whiteField = 0.38 + 0.14 * sin(t * 0.07) + 0.10 * (bass - 0.5);

    // Grid system — governance, measurement, total clarity
    float gridScale1 = 12.0 + 4.0 * sin(t * 0.13);
    float gridScale2 = 48.0 + 16.0 * mid;
    float g1 = grid(uv + vec2(t * 0.01, 0.0), gridScale1, 0.03 + 0.02 * high);
    float g2 = grid(uv - vec2(0.0, t * 0.007), gridScale2, 0.015);

    // Pulsing — the hum beneath the floor
    float pulse = sin(t * 2.3 + uv.y * 30.0) * 0.5 + 0.5;
    pulse = pow(pulse, 8.0 + 6.0 * bass);
    float pulseField = pulse * g2 * (0.3 + 0.7 * bass);

    // Pressure accumulation — no release valve
    float dist = length(uv);
    float pressureWave = sin(dist * 20.0 - t * 1.5) * 0.5 + 0.5;
    pressureWave = pow(pressureWave, 3.0) * smoothstep(0.8, 0.1, dist) * pressure;

    // Noise disruption — ground liquefying
    float n1 = noise(uv * 8.0 + t * 0.3);
    float n2 = noise(uv * 32.0 - t * 0.7);
    // Disruption now subtracts more aggressively to carve darkness
    float disruption = (n1 * 0.28 + n2 * 0.14 * high) * 2.0 - 0.18;

    // Scan lines — sorting, examining
    float scan = sin(uv01.y * u_resolution.y * 0.5 + t * 3.0) * 0.5 + 0.5;
    scan = pow(scan, 12.0) * 0.22;

    // Horizontal data bands — visible contrast cuts
    float band = sin(uv.y * 60.0 + t * 0.5 + n1 * 3.0) * 0.5 + 0.5;
    band = smoothstep(0.85, 0.95, band) * 0.35 * mid;

    // Dark vignette — edges fall toward black
    float vignette = 1.0 - smoothstep(0.3, 1.1, dist);

    // Onset flicker — system hiccup
    float flicker = 1.0 - onset * 0.45 * step(0.5, hash(vec2(floor(t * 30.0), 0.0)));

    // Color palette: dark slate base, cold blue-white highlights, hot pressure
    // deep = near-black blue-grey for dark areas
    // coldWhite = bright cold highlight for peaks
    vec3 deep      = vec3(0.04, 0.05, 0.10);
    vec3 midGrey   = vec3(0.28, 0.30, 0.38);
    vec3 coldWhite = vec3(0.72, 0.74, 0.82);
    vec3 white     = vec3(0.88, 0.89, 0.92);
    vec3 hotPressure = vec3(0.95, 0.45, 0.35);

    // Grid lines add bright cuts; disruption carves dark troughs
    // Net range of lum is roughly 0.0–1.0 with genuine spread
    float lum = whiteField
                + g1 * 0.35
                + pulseField * 0.30
                + pressureWave * 0.25
                - disruption
                + scan * 0.18
                + band;

    lum *= vignette;
    lum = clamp(lum, 0.0, 1.2);

    // Three-stop color ramp: dark -> midgrey -> coldWhite -> white
    vec3 col;
    if (lum < 0.35) {
        col = mix(deep, midGrey, lum / 0.35);
    } else if (lum < 0.70) {
        col = mix(midGrey, coldWhite, (lum - 0.35) / 0.35);
    } else {
        col = mix(coldWhite, white, (lum - 0.70) / 0.50);
    }

    // Hot pressure accent — only meaningful near pressure wave peaks
    col += hotPressure * pressureWave * 0.55 * bass;

    // Warm pulse tint on grid intersections
    col += vec3(0.18, 0.08, 0.02) * pulseField * bass;

    // Subtle blue desaturation on fine grid
    col -= vec3(0.0, 0.0, 0.10) * g2 * 0.4;

    // Overexposure bloom — only fires when lum genuinely high
    float bloom = max(lum - 0.92, 0.0) * 5.0;
    col += vec3(0.85, 0.90, 1.0) * bloom * 0.25;

    // Grain — slightly heavier so it reads against both dark and light areas
    float grain = (hash(uv01 * u_resolution + fract(t * 60.0)) - 0.5) * 0.045;
    col += grain;

    col *= flicker;
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}