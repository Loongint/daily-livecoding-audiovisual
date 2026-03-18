#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_drone_depth;

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
    float slowT = u_time * 0.03;

    vec2 cloudUV1 = uv * vec2(2.2, 1.4) + vec2(t * 0.4, slowT * 0.2);
    vec2 cloudUV2 = uv * vec2(1.5, 2.0) + vec2(-t * 0.25, slowT * 0.35);
    float cloud1 = fbm(cloudUV1);
    float cloud2 = fbm(cloudUV2);
    float cloudMix = cloud1 * 0.6 + cloud2 * 0.4;
    float cloudDensity = smoothstep(0.30, 0.75, cloudMix);

    vec2 moonPos = vec2(0.0, 0.12);
    float moonDist = length(uvA - moonPos);
    float moonRadius = 0.055;
    float moonDisc = smoothstep(moonRadius, moonRadius - 0.008, moonDist);

    float glowRadius = 0.28 + u_pulse_amp * 0.06;
    float glow = exp(-moonDist * moonDist / (glowRadius * glowRadius)) * 0.85;
    float halo = exp(-moonDist * moonDist / (0.08 * 0.08)) * 0.5;

    float cloudAtMoon = fbm(vec2(moonPos.x / aspect.x + 0.5, moonPos.y + 0.5) * vec2(2.2, 1.4) + vec2(t * 0.4, slowT * 0.2));
    float veilFactor = smoothstep(0.35, 0.65, cloudAtMoon);
    float moonVisible = 1.0 - veilFactor * 0.75;

    float breathe = 0.92 + 0.08 * sin(u_time * 0.4 + u_drone_depth * 1.5);
    float shimmerPulse = 0.85 + 0.15 * sin(u_time * 1.2) * u_shimmer;

    vec3 skyLow  = vec3(0.38, 0.44, 0.42);
    vec3 skyHigh = vec3(0.52, 0.60, 0.58);
    vec3 sky = mix(skyLow, skyHigh, uv.y * 0.8 + 0.1);

    vec3 cloudColor = vec3(0.62, 0.68, 0.65);
    vec3 cloudLit   = vec3(0.78, 0.84, 0.80);
    float cloudLitFactor = smoothstep(0.0, 0.5, glow * moonVisible);
    vec3 cloudFinal = mix(cloudColor, cloudLit, cloudLitFactor);

    vec3 moonColor = vec3(0.92, 0.95, 0.90);
    vec3 glowColor = vec3(0.70, 0.80, 0.76);

    vec3 col = sky;
    col = mix(col, cloudFinal, cloudDensity * 0.72);
    col += glowColor * glow * moonVisible * breathe;
    col += glowColor * halo * moonVisible * 0.4;
    col = mix(col, moonColor, moonDisc * moonVisible * shimmerPulse);

    float starNoise = hash(floor(uv * 180.0));
    float starMask = pow(starNoise, 14.0);
    float starTwinkle = 0.5 + 0.5 * sin(u_time * 2.5 + starNoise * 40.0);
    float starVis = starMask * starTwinkle * (1.0 - cloudDensity * 0.9) * 0.9;
    col += vec3(0.85, 0.92, 0.88) * starVis;

    float spectralLift = u_spectral_brightness * 0.18;
    col += vec3(0.55, 0.65, 0.60) * spectralLift * (1.0 - cloudDensity * 0.5);

    float bassWarm = u_bass_energy * 0.12;
    col += vec3(bassWarm * 0.4, bassWarm * 0.2, bassWarm * 0.1) * cloudDensity;

    float vignette = 1.0 - 0.28 * dot(uvA * vec2(0.9, 1.1), uvA * vec2(0.9, 1.1));
    col *= max(vignette, 0.72);

    col = clamp(col, 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}