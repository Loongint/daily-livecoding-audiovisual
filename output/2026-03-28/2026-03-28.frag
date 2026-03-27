#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_rotation_speed;

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

mat2 rot2(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float fbm(vec2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        v += noise(p) * amp;
        p = rot2(0.7) * p * 2.1;
        amp *= 0.48;
    }
    return v;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    
    float bass = clamp(u_bass_energy, 0.0, 1.0);
    float shimmer = clamp(u_shimmer, 0.0, 1.0);
    float pulse = clamp(u_pulse_amp, 0.0, 1.0);
    float bright = clamp(u_spectral_brightness, 0.0, 1.0);
    float rotSpd = clamp(u_rotation_speed, 0.0, 1.0);

    float t = u_time * 0.18 + rotSpd * u_time * 0.12;
    vec2 ruv = rot2(t) * uv;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    float falseCenter = 0.3 + 0.12 * sin(u_time * 0.23);
    vec2 falseAxis = vec2(falseCenter * cos(u_time * 0.11), falseCenter * sin(u_time * 0.07));
    vec2 uvOff = uv - falseAxis;
    float rOff = length(uvOff);

    float orbit = sin(atan(uvOff.y, uvOff.x) * 3.0 - u_time * 0.9 + bass * 2.0);
    float orbitRing = smoothstep(0.04, 0.0, abs(rOff - 0.42 - 0.08 * orbit - pulse * 0.06));

    vec2 heatUV = ruv * 2.8 + vec2(u_time * 0.07, u_time * 0.05);
    float heat = fbm(heatUV + vec2(fbm(heatUV * 1.3)));
    
    vec2 surfUV = uv * 3.5 + vec2(sin(u_time * 0.13) * 0.4, cos(u_time * 0.09) * 0.3);
    float surface = fbm(surfUV);

    float tautHum = sin(r * 18.0 - u_time * 2.4 + shimmer * 4.0) * 0.5 + 0.5;
    tautHum *= exp(-r * 2.2);

    float giltMask = smoothstep(0.7, 0.0, rOff);
    float giltSkin = heat * giltMask;

    vec3 colDeep = vec3(0.55, 0.18, 0.05);
    vec3 colGilt = vec3(0.95, 0.72, 0.18);
    vec3 colHot  = vec3(1.0, 0.45, 0.08);
    vec3 colRim  = vec3(0.85, 0.95, 0.65);
    vec3 colDark = vec3(0.12, 0.08, 0.18);

    vec3 col = mix(colDark, colDeep, smoothstep(0.9, 0.3, r));
    col = mix(col, mix(colDeep, colHot, heat), giltSkin * 1.1);
    col = mix(col, colGilt, giltSkin * surface * 1.3);
    col += colRim * tautHum * (0.4 + shimmer * 0.5);
    col += colHot * orbitRing * (0.7 + bass * 0.8);

    float shimmerStar = pow(noise(uv * 22.0 + u_time * 0.3), 6.0);
    col += colGilt * shimmerStar * (0.5 + shimmer * 0.9);

    float pulse2 = sin(u_time * 1.7 + rOff * 8.0) * 0.5 + 0.5;
    col += colHot * pulse2 * pulse * 0.35 * giltMask;

    float halfMoon = sin(angle + u_time * 0.15) * 0.5 + 0.5;
    col *= 0.55 + halfMoon * 0.45 + bass * 0.15;

    col = pow(clamp(col, 0.0, 1.0), vec3(0.82));
    col = mix(col, vec3(dot(col, vec3(0.299, 0.587, 0.114))), -0.15);
    col = clamp(col * 1.25 + 0.04, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}