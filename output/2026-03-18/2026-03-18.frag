#version 330

uniform float u_time;
uniform vec2 u_resolution;

// Audio-reactive uniforms — mapped to drone/ambient analysis
uniform float u_drone_swell;        // low drone energy — expands cloud mass
uniform float u_veil_density;       // mid presence — cloud opacity/layering
uniform float u_moon_shimmer;       // high freq shimmer — lunar edge glow
uniform float u_breath_amp;         // slow breath envelope — overall luminance pulse
uniform float u_humidity_warmth;    // spectral warmth — shifts grey toward amber

out vec4 fragColor;

// Smooth noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1,0)), u.x),
        mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x),
        u.y
    );
}

float fbm(vec2 p, int oct) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < oct; i++) {
        v += a * noise(p);
        p = p * 2.1 + vec2(1.3, 0.7);
        a *= 0.5;
    }
    return v;
}

// Crescent mask for new moon (phase ~0.009 — barely a sliver)
float crescentMask(vec2 uv, float phase) {
    float r1 = length(uv);
    float r2 = length(uv - vec2(0.03, 0.0)); // tiny offset = thin crescent
    float moon = smoothstep(0.12, 0.10, r1);
    float shadow = smoothstep(0.11, 0.09, r2);
    return clamp(moon - shadow, 0.0, 1.0);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t = u_time * 0.04;

    // Slow drifting cloud layers
    float drone = 0.5 + 0.5 * u_drone_swell;
    vec2 drift1 = uv + vec2(t * 0.3, t * 0.12);
    vec2 drift2 = uv + vec2(-t * 0.18, t * 0.22) + vec2(0.4, 0.1);

    float cloud1 = fbm(drift1 * (1.8 + drone * 0.6), 5);
    float cloud2 = fbm(drift2 * (2.2 - drone * 0.3), 4);
    float veil = mix(cloud1, cloud2, 0.5 + 0.5 * u_veil_density);
    veil = smoothstep(0.2, 0.85, veil);

    // Moon position — upper center, slightly offset
    vec2 moonUV = uv - vec2(0.05, 0.18);
    float crescent = crescentMask(moonUV, 0.009481882831006828);

    // Lunar halo — soft glow behind veil, shimmer clamped to [0,1]
    float haloDist = length(moonUV);
    float shimmer = clamp(u_moon_shimmer, 0.0, 1.0);
    float halo = exp(-haloDist * haloDist * 18.0) * (0.4 + 0.6 * shimmer);

    // Cloud occlusion of moon
    float moonVeil = fbm((moonUV + drift1) * 3.5, 3);
    float occlude = smoothstep(0.35, 0.65, moonVeil);
    float moonVisible = crescent * (1.0 - occlude * u_veil_density);

    // Breath pulse — clamp amp to [0,1] so envelope followers can't blow out
    float breathAmp = clamp(u_breath_amp, 0.0, 1.0);
    float breath = 0.85 + 0.15 * breathAmp * sin(u_time * 0.3);

    // Base palette: deep grey-blue void
    vec3 voidCol   = vec3(0.04, 0.05, 0.07);
    vec3 cloudCol  = vec3(0.18, 0.19, 0.22);
    vec3 warmMist  = vec3(0.28, 0.24, 0.18); // warm humidity tint
    vec3 moonCol   = vec3(0.88, 0.90, 0.95);
    vec3 haloCol   = vec3(0.55, 0.58, 0.65);

    // Compose scene
    vec3 col = mix(voidCol, cloudCol, veil);
    col = mix(col, warmMist, u_humidity_warmth * veil * 0.5);

    // Budget the additive terms so moon center stays below 1.0:
    // halo peak contribution capped, then moon added on top with headroom check
    vec3 haloContrib = haloCol * halo * (1.0 - occlude * 0.6);
    vec3 moonContrib = moonCol * moonVisible;
    // Tone-map the combined additive layer to prevent hard clipping
    vec3 additive = haloContrib + moonContrib;
    col += additive / (1.0 + additive);

    // Subtle vignette
    float vig = 1.0 - smoothstep(0.5, 1.2, length(uv));
    col *= vig * breath;

    // Faster fade-in (3 s) so the scene is visible immediately on start/loop
    float presence = smoothstep(0.0, 3.0, u_time);
    col *= presence;

    fragColor = vec4(col, 1.0);
}