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

float ledgerLine(vec2 uv, float y, float thickness, float t) {
    float erasure = noise(vec2(uv.x * 8.0, t * 0.3 + y * 10.0));
    float line = smoothstep(thickness, 0.0, abs(uv.y - y));
    return line * smoothstep(0.35, 0.65, erasure);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
    float t = u_time * 0.4;

    float bass = 0.5 + u_bass_energy * 0.5;
    float shimmer = 0.5 + u_shimmer * 0.5;
    float pulse = 0.5 + u_pulse_amp * 0.5;
    float bright = 0.5 + u_spectral_brightness * 0.5;

    vec3 col = vec3(0.0);

    vec3 bgDark = vec3(0.08, 0.12, 0.18);
    vec3 bgMid  = vec3(0.22, 0.30, 0.42);
    float bgGrad = smoothstep(-0.6, 0.6, uv.y);
    col = mix(bgDark, bgMid, bgGrad);

    float staticField = fbm(uv * 6.0 + vec2(t * 0.2, t * 0.15));
    float staticField2 = fbm(uv * 12.0 - vec2(t * 0.1, t * 0.25));
    float density = staticField * 0.6 + staticField2 * 0.4;

    vec3 staticColor = mix(
        vec3(0.35, 0.50, 0.65),
        vec3(0.70, 0.85, 0.95),
        density
    );
    col = mix(col, staticColor, density * 0.55 * bass);

    float numLines = 18.0;
    float lineAccum = 0.0;
    for (int i = 0; i < 18; i++) {
        float fi = float(i);
        float y = -0.5 + (fi / numLines) * 1.1 + 0.02 * sin(t * 0.5 + fi * 0.7);
        float th = 0.003 + 0.004 * pulse;
        lineAccum += ledgerLine(uv, y, th, t + fi * 0.13);
    }
    vec3 lineColor = mix(vec3(0.75, 0.88, 1.0), vec3(1.0, 0.95, 0.80), shimmer);
    col += lineColor * lineAccum * 0.65;

    float entryNoise = fbm(uv * 20.0 + vec2(0.0, t * 0.08));
    float entryMask = smoothstep(0.55, 0.75, entryNoise);
    float entryFlicker = 0.5 + 0.5 * sin(t * 3.0 + entryNoise * 20.0);
    col += vec3(0.60, 0.75, 0.90) * entryMask * entryFlicker * 0.30 * bright;

    float pulseCycle = 0.5 + 0.5 * sin(t * 1.8);
    float threshold = 0.72;
    float prePulse = smoothstep(threshold - 0.15, threshold, pulseCycle * pulse);
    float radial = 1.0 - smoothstep(0.0, 0.55, length(uv));
    col += vec3(0.50, 0.70, 1.0) * prePulse * radial * 0.45;

    float moonPhase = 0.5;
    vec2 moonUV = uv - vec2(0.3, 0.28);
    float moonDist = length(moonUV);
    float moonGlow = exp(-moonDist * 6.0) * 0.5 * moonPhase;
    float moonDisc = smoothstep(0.06, 0.055, moonDist);
    col += vec3(0.85, 0.90, 1.0) * moonGlow;
    col += vec3(0.92, 0.95, 1.0) * moonDisc * 0.7;

    float eraseSurface = fbm(uv * 5.0 - vec2(t * 0.05, 0.0));
    float eraseAlpha = smoothstep(0.60, 0.80, eraseSurface) * 0.35;
    col = mix(col, vec3(0.15, 0.20, 0.28), eraseAlpha);

    col = pow(clamp(col, 0.0, 1.0), vec3(0.88));
    col = mix(col, col * col * (3.0 - 2.0 * col), 0.25);

    fragColor = vec4(col, 1.0);
}