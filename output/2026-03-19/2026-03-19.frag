#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_drone_swell;

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

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 aspect = vec2(u_resolution.x / u_resolution.y, 1.0);
    vec2 uvA = (uv - 0.5) * aspect;

    float t = u_time * 0.08;
    float swell = 0.5 + 0.5 * sin(u_time * 0.3) + u_drone_swell * 0.3;
    float pulse = 1.0 + u_pulse_amp * 0.15 * sin(u_time * 1.1);

    vec2 moonPos = vec2(0.0, 0.12);
    float moonPhase = 0.043345750084647194;
    float moonR = 0.07 * pulse;
    float moonDist = length(uvA - moonPos);

    float crescent = 0.0;
    if (moonDist < moonR * 1.8) {
        float d1 = length(uvA - moonPos);
        float d2 = length(uvA - moonPos - vec2(moonR * 1.3 * (1.0 - moonPhase * 2.0), 0.0));
        float lit = smoothstep(moonR, moonR * 0.85, d1);
        float shadow = smoothstep(moonR * 0.95, moonR * 0.75, d2);
        crescent = lit * (1.0 - shadow * 0.92);
    }

    float glow = exp(-moonDist * moonDist * 18.0) * 0.7 * swell;
    float halo = exp(-moonDist * moonDist * 4.5) * 0.35 * swell;

    vec2 cloudUV1 = uv * vec2(2.2, 1.4) + vec2(t * 0.6, t * 0.2);
    vec2 cloudUV2 = uv * vec2(1.5, 2.0) + vec2(-t * 0.4, t * 0.35);
    float cloud1 = fbm(cloudUV1);
    float cloud2 = fbm(cloudUV2);
    float clouds = cloud1 * 0.6 + cloud2 * 0.4;
    clouds = smoothstep(0.35, 0.75, clouds);

    float veilUV_x = uv.x * 3.5 + t * 0.3;
    float veilUV_y = uv.y * 2.0 + t * 0.15;
    float veil = fbm(vec2(veilUV_x, veilUV_y));
    veil = smoothstep(0.3, 0.7, veil) * 0.5;

    float moonProximity = 1.0 - smoothstep(0.0, 0.45, moonDist);
    float cloudLit = clouds * (0.4 + moonProximity * 0.6) + veil * 0.3;

    vec3 skyLow  = vec3(0.28, 0.34, 0.32);
    vec3 skyHigh = vec3(0.42, 0.50, 0.46);
    vec3 sky = mix(skyLow, skyHigh, uv.y * 0.8 + 0.1);

    vec3 cloudColor = vec3(0.55, 0.62, 0.58) + vec3(0.12, 0.14, 0.10) * moonProximity * swell;
    vec3 moonColor  = vec3(0.88, 0.92, 0.82);
    vec3 glowColor  = vec3(0.65, 0.78, 0.65);

    vec3 col = sky;
    col = mix(col, cloudColor, cloudLit * 0.75);
    col += glowColor * halo;
    col += glowColor * glow * 0.5;
    col = mix(col, moonColor, crescent * 0.95);

    float shimmerNoise = noise(uv * 120.0 + vec2(u_time * 0.5, 0.0));
    float stars = pow(shimmerNoise, 9.0) * (1.0 - clouds * 1.5) * (1.0 - moonProximity) * 0.5 * u_shimmer;
    col += vec3(0.8, 0.9, 0.85) * stars;

    float breathe = 0.92 + 0.08 * sin(u_time * 0.25 + fbm(uv * 1.5) * 2.0);
    col *= breathe;

    float bass_lift = u_bass_energy * 0.08;
    col += vec3(0.04, 0.06, 0.05) * bass_lift;

    col = pow(clamp(col, 0.0, 1.0), vec3(0.88));

    fragColor = vec4(col, 1.0);
}