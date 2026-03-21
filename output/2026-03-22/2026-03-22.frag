#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_heat_flux;

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

vec3 gridLine(vec2 uv, float scale, float t) {
    vec2 g = fract(uv * scale) - 0.5;
    float lx = smoothstep(0.48, 0.46, abs(g.x));
    float ly = smoothstep(0.48, 0.46, abs(g.y));
    float line = max(lx, ly);
    float dist = min(abs(g.x), abs(g.y));
    float pulse = sin(uv.x * scale * 6.28 - t * 3.0) * 0.5 + 0.5;
    return vec3(line * (0.4 + pulse * 0.6));
}

void main() {
    vec2 uv = (gl_FragCoord.xy - u_resolution * 0.5) / u_resolution.y;
    float bass = clamp(u_bass_energy, 0.0, 1.0);
    float shimmer = clamp(u_shimmer, 0.0, 1.0);
    float pulse = clamp(u_pulse_amp, 0.0, 1.0);
    float bright = clamp(u_spectral_brightness, 0.0, 1.0);
    float heat = clamp(u_heat_flux, 0.0, 1.0);

    float t = u_time;
    float slowT = t * 0.3;
    float midT = t * 0.7;

    vec2 distUV = uv + vec2(
        fbm(uv * 2.0 + vec2(slowT * 0.4, 0.0)) - 0.5,
        fbm(uv * 2.0 + vec2(0.0, slowT * 0.4)) - 0.5
    ) * (0.3 + bass * 0.4);

    vec3 grid1 = gridLine(distUV, 6.0 + bass * 4.0, t * 1.2);
    vec3 grid2 = gridLine(distUV * 1.3 + vec2(midT * 0.05, 0.0), 12.0, t * 0.8);
    vec3 gridColor = grid1 * vec3(1.0, 0.3, 0.1) + grid2 * vec3(0.2, 0.6, 1.0);

    float meltNoise = fbm(distUV * 3.0 + vec2(0.0, t * 0.5));
    float melt = smoothstep(0.3, 0.8, meltNoise);
    vec3 meltColor = mix(
        vec3(1.0, 0.4, 0.05),
        vec3(0.9, 0.1, 0.4),
        melt
    ) * (0.6 + heat * 0.8);

    float radial = length(uv);
    float pulseRing = exp(-radial * (4.0 - pulse * 2.0)) * (0.5 + pulse * 0.8);
    float ring2 = exp(-abs(radial - 0.4 - sin(t * 1.5) * 0.1) * 12.0) * 0.7;
    vec3 pulseColor = vec3(1.0, 0.7, 0.2) * pulseRing + vec3(0.5, 0.2, 1.0) * ring2;

    float collapse = smoothstep(0.8, 0.2, radial + meltNoise * 0.3 - bass * 0.2);
    vec3 core = mix(vec3(1.0, 0.5, 0.1), vec3(0.8, 0.1, 0.6), sin(t * 0.5) * 0.5 + 0.5);
    vec3 coreGlow = core * collapse * (1.0 + shimmer * 1.5);

    float shimNoise = fbm(uv * 8.0 + vec2(t * 1.5, -t * 0.9));
    vec3 shimmerLayer = vec3(0.4, 0.8, 1.0) * pow(shimNoise, 2.0) * shimmer * 1.2;

    vec3 bgGrad = mix(
        vec3(0.35, 0.05, 0.15),
        vec3(0.05, 0.15, 0.35),
        uv.y * 0.5 + 0.5 + sin(slowT) * 0.2
    );
    bgGrad += vec3(0.1, 0.05, 0.2) * fbm(uv + vec2(slowT * 0.2));

    vec3 color = bgGrad;
    color += gridColor * (0.5 + bright * 0.8);
    color += meltColor * melt * 0.7;
    color += pulseColor;
    color += coreGlow;
    color += shimmerLayer;

    float hotspot = exp(-radial * 2.0) * (0.3 + bass * 0.5);
    color += vec3(1.0, 0.4, 0.1) * hotspot;

    float vignette = 1.0 - smoothstep(0.5, 1.2, radial * 0.8);
    color *= 0.5 + vignette * 0.7;
    color = color / (color + 0.6) * 1.6;

    float flicker = 0.92 + 0.08 * sin(t * 47.3 + uv.x * 100.0);
    color *= flicker;

    color = clamp(color, 0.0, 1.0);
    fragColor = vec4(color, 1.0);
}