#version 330
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_thermal_flux;
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

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    float t = u_time;
    float bass = 0.5 + u_bass_energy * 0.5;
    float shimmer = 0.5 + u_shimmer * 0.5;
    float pulse = 0.5 + u_pulse_amp * 0.5;
    float bright = 0.5 + u_spectral_brightness * 0.5;
    float flux = 0.5 + u_thermal_flux * 0.5;

    float stutter = floor(t * 8.0 * bass) / (8.0 * bass);
    float microJitter = hash(vec2(floor(t * 24.0), 7.3)) * 0.04 * pulse;
    vec2 jUV = uv + vec2(microJitter, microJitter * 0.7);

    float warpAmt = 0.4 + bass * 0.4;
    vec2 warpedUV = jUV + warpAmt * vec2(
        fbm(jUV * 2.5 + vec2(stutter * 0.3, t * 0.15)),
        fbm(jUV * 2.5 + vec2(t * 0.12, stutter * 0.25))
    );

    float thermal = fbm(warpedUV * 3.0 + vec2(t * 0.2 * flux, -t * 0.13));
    float regulation = fbm(warpedUV * 5.0 - vec2(t * 0.17, t * 0.21 * shimmer));

    float collapse = step(0.65, hash(vec2(floor(t * 6.0 * pulse), floor(t * 4.3))));
    float blend = mix(thermal, regulation, 0.5 + 0.5 * sin(t * 1.1 + thermal * 3.14));
    blend = mix(blend, 1.0 - blend, collapse * 0.7);

    float hotStreak = smoothstep(0.55, 0.85, fbm(uv * 8.0 + vec2(stutter, t * 0.4)));
    float coolDip = smoothstep(0.6, 0.9, fbm(uv * 6.0 - vec2(t * 0.3, stutter * 0.5)));

    float dist = length(uv);
    float radialPulse = 0.5 + 0.5 * sin(dist * 10.0 - t * 3.0 * bass);
    blend += radialPulse * 0.15 * pulse;

    float scanLine = step(0.5, fract(gl_FragCoord.y / 3.0 + t * 12.0 * flux)) * 0.08 * collapse;
    blend -= scanLine;

    vec3 colCold = vec3(0.05, 0.35, 0.75);
    vec3 colHot = vec3(0.95, 0.45, 0.05);
    vec3 colMid = vec3(0.8, 0.8, 0.3);
    vec3 colFail = vec3(0.9, 0.15, 0.4);

    vec3 col = mix(colCold, colHot, blend);
    col = mix(col, colMid, hotStreak * 0.5 * shimmer);
    col = mix(col, colFail, collapse * coolDip * 0.6);

    float halfLit = 0.5 + 0.5 * sin(t * 0.4 + uv.x * 2.0);
    col *= mix(0.55, 1.0, halfLit * bright);

    col += vec3(0.08, 0.04, 0.02) * hotStreak * 2.0 * bass;
    col += vec3(0.02, 0.06, 0.18) * (1.0 - thermal) * shimmer;

    float flickerSpeed = mix(4.0, 20.0, pulse);
    float flicker = 0.85 + 0.15 * step(0.4, hash(vec2(floor(t * flickerSpeed), 3.7)));
    col *= flicker;

    col = clamp(col, 0.0, 1.0);
    col = pow(col, vec3(0.85));
    col = mix(col, vec3(dot(col, vec3(0.299, 0.587, 0.114))), 0.1 * (1.0 - bright));

    fragColor = vec4(col, 1.0);
}