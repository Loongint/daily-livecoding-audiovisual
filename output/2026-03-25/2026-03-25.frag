#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_pressure_build;
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
    float t = u_time * 0.3;
    float bass = 0.5 + u_bass_energy * 0.5;
    float pressure = 0.5 + u_pressure_build * 0.5;
    float shimmer = 0.4 + u_shimmer * 0.6;
    float pulse = 0.5 + u_pulse_amp * 0.5;
    float bright = 0.5 + u_spectral_brightness * 0.5;

    float slowT = t * 0.18;
    float seam = uv.y + fbm(uv * 2.5 + vec2(slowT * 0.4, slowT * 0.2)) * 0.35;
    float seamLine = abs(seam + sin(uv.x * 3.0 + slowT) * 0.08 * pressure);
    float seamGlow = exp(-seamLine * 14.0) * (0.8 + pulse * 0.5);

    float pressureField = fbm(uv * 3.0 + vec2(slowT * 0.3, -slowT * 0.5));
    pressureField = pressureField * 0.6 + 0.4;

    float accumulation = fbm(uv * 1.8 - vec2(slowT * 0.2, slowT * 0.15));
    float burstNoise = fbm(uv * 6.0 + vec2(slowT * 1.2, slowT * 0.8));
    float burst = pow(burstNoise, 3.0 + (1.0 - pressure) * 4.0) * bass * 2.5;

    float radial = length(uv);
    float halo = exp(-radial * 2.2) * 0.6 * pressure;

    float rings = sin(radial * 18.0 - t * 2.5 * pulse) * 0.5 + 0.5;
    rings = pow(rings, 4.0) * exp(-radial * 3.5) * shimmer * 0.7;

    float interval = sin(t * 0.6 + pressureField * 4.0) * 0.5 + 0.5;
    interval = pow(interval, 2.0) * 0.5 + 0.5;

    vec3 colBase = vec3(0.08, 0.18, 0.32);
    vec3 colSeam = vec3(0.85, 0.92, 1.0);
    vec3 colPressure = vec3(0.38, 0.68, 0.95);
    vec3 colBurst = vec3(1.0, 0.78, 0.42);
    vec3 colAccum = vec3(0.18, 0.42, 0.72);
    vec3 colHalo = vec3(0.55, 0.82, 1.0);

    vec3 col = colBase * (0.7 + accumulation * 0.5 + pressureField * 0.4);
    col += colPressure * pressureField * interval * 0.55;
    col += colAccum * accumulation * 0.5 * pressure;
    col += colSeam * seamGlow;
    col += colBurst * burst;
    col += colHalo * halo;
    col += colSeam * rings;

    float slowPulse = sin(t * 0.9 + pressureField * 2.0) * 0.5 + 0.5;
    col += colPressure * slowPulse * 0.18 * bright;

    float edgeVeil = 1.0 - smoothstep(0.5, 1.1, radial);
    col *= 0.5 + edgeVeil * 0.7;
    col += colHalo * (1.0 - edgeVeil) * 0.12;

    col = col * bright * 1.1;
    col = pow(clamp(col, 0.0, 1.0), vec3(0.82));
    col = mix(col, col * vec3(0.88, 0.95, 1.0), 0.3);

    fragColor = vec4(col, 1.0);
}