#version 330
uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_pressure_wave;
uniform float u_shimmer;
uniform float u_spectral_brightness;
uniform float u_pulse_amp;

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

float bottleneck(vec2 uv, float t) {
    float neck = 0.12 + 0.08 * sin(t * 0.3) + u_pressure_wave * 0.06;
    float y = uv.y;
    float bulge = 0.35 + 0.15 * sin(y * 3.14159 + t * 0.2);
    float width = mix(neck, bulge, smoothstep(0.3, 0.7, y));
    width = mix(width, neck * 0.7, smoothstep(0.85, 1.0, y));
    float dist = abs(uv.x - 0.5) / width;
    return dist;
}

vec3 pressureColor(float pressure, float t) {
    vec3 cold = vec3(0.1, 0.3, 0.7);
    vec3 warm = vec3(0.9, 0.4, 0.1);
    vec3 hot = vec3(1.0, 0.9, 0.3);
    float p = clamp(pressure, 0.0, 1.0);
    vec3 c = mix(cold, warm, p);
    c = mix(c, hot, smoothstep(0.7, 1.0, p));
    float pulse = 0.5 + 0.5 * sin(t * 2.0 + pressure * 6.28);
    c += vec3(0.15, 0.1, 0.05) * pulse * u_pulse_amp;
    return c;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 centered = uv - vec2(0.5, 0.5);
    float t = u_time * 0.5;
    float bass = 0.3 + u_bass_energy * 0.7;
    float shimmer = 0.2 + u_shimmer * 0.8;
    float brightness = 0.4 + u_spectral_brightness * 0.6;

    float dist = bottleneck(uv, t);

    float flow = noise(vec2(uv.x * 3.0, uv.y * 8.0 - t * 1.5)) * 0.5 + 0.5;
    float pressure = clamp(1.0 - dist * 0.8 + flow * 0.3 * bass, 0.0, 1.0);

    float compressWave = sin(uv.y * 20.0 - t * 4.0) * 0.5 + 0.5;
    compressWave *= smoothstep(0.15, 0.0, abs(dist - 0.5));
    pressure += compressWave * 0.3 * u_pulse_amp;

    float edge = smoothstep(1.0, 0.6, dist);
    float innerGlow = smoothstep(0.7, 0.0, dist) * bass;

    float ripple = sin(dist * 25.0 - t * 3.0) * 0.04 * shimmer;
    pressure += ripple;

    vec3 col = pressureColor(pressure, t * 2.0);

    float bgNoise = noise(uv * 4.0 + vec2(t * 0.1, 0.0));
    vec3 bg = vec3(0.05, 0.08, 0.18) + bgNoise * vec3(0.08, 0.06, 0.12);

    float archLine = exp(-abs(dist - 1.0) * 15.0) * 0.7 * brightness;
    vec3 archColor = vec3(0.5, 0.8, 1.0) * archLine;

    float stillness = smoothstep(0.0, 0.5, 1.0 - abs(sin(t * 0.15)));
    float glowCore = exp(-dist * 3.0) * innerGlow * brightness;
    vec3 coreGlow = vec3(1.0, 0.85, 0.5) * glowCore * 1.5;

    col = mix(bg, col, edge);
    col += archColor;
    col += coreGlow;
    col += vec3(0.2, 0.3, 0.5) * stillness * 0.4 * smoothstep(0.5, 0.0, dist);

    float scanLine = 0.85 + 0.15 * sin(uv.y * u_resolution.y * 0.5);
    col *= scanLine;

    float sparkle = pow(noise(uv * 15.0 + t * 0.3), 6.0) * shimmer * 0.8;
    col += vec3(0.8, 0.9, 1.0) * sparkle * edge;

    col = pow(clamp(col, 0.0, 1.0), vec3(0.85));
    col = mix(col, vec3(dot(col, vec3(0.299, 0.587, 0.114))), 0.1 * stillness);

    float vign = 1.0 - dot(centered * 1.2, centered * 1.2);
    col *= 0.6 + 0.4 * clamp(vign, 0.0, 1.0);
    col = clamp(col * 1.3, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}