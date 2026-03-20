#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_threshold_pressure;

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

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec2 uvRaw = gl_FragCoord.xy / u_resolution.xy;
    
    float bass = clamp(u_bass_energy, 0.0, 1.0);
    float shimmer = clamp(u_shimmer, 0.0, 1.0);
    float pulse = clamp(u_pulse_amp, 0.0, 1.0);
    float bright = clamp(u_spectral_brightness, 0.0, 1.0);
    float pressure = clamp(u_threshold_pressure, 0.0, 1.0);
    
    float t = u_time * 0.3;
    
    float gridScale = 8.0 + bass * 6.0;
    vec2 gridUV = uv * gridScale;
    vec2 gridCell = floor(gridUV);
    vec2 gridFrac = fract(gridUV);
    
    float compression = 0.5 + 0.4 * sin(t * 0.7 + gridCell.y * 0.3);
    float lineWidth = 0.04 + pressure * 0.06;
    float gridH = smoothstep(lineWidth, 0.0, abs(gridFrac.y - 0.5) - (0.5 - lineWidth));
    float gridV = smoothstep(lineWidth, 0.0, abs(gridFrac.x - 0.5) - (0.5 - lineWidth));
    float grid = max(gridH, gridV);
    
    float cellNoise = hash(gridCell + floor(t * 0.5));
    float cellPulse = sin(t * 2.0 + cellNoise * 6.28) * 0.5 + 0.5;
    float cellActive = step(0.3 + pressure * 0.4, cellNoise);
    float cellFill = cellActive * cellPulse * smoothstep(0.1, 0.0, length(gridFrac - 0.5) - 0.3);
    
    float dist = length(uv);
    float swell = sin(dist * 8.0 - t * 2.0 + bass * 3.14) * 0.5 + 0.5;
    float swellRing = smoothstep(0.05, 0.0, abs(fract(dist * 4.0 - t * 0.8) - 0.5) - 0.1 * (1.0 - pulse));
    
    float edgeRupture = smoothstep(0.6, 1.2, dist + bass * 0.3);
    float ruptureNoise = noise(uv * 5.0 + t * 0.5);
    float ruptureLine = smoothstep(0.03, 0.0, abs(dist - (0.7 + ruptureNoise * 0.2 + pulse * 0.15)));
    
    float angle = atan(uv.y, uv.x);
    float radialCompress = sin(angle * 12.0 + t * 1.5) * 0.5 + 0.5;
    float radialGrid = smoothstep(0.02, 0.0, abs(fract(angle / 0.5236 + t * 0.1) - 0.5) - 0.05);
    
    float silence = smoothstep(0.0, 0.5, dist) * (1.0 - bass * 0.5);
    float silencePool = 1.0 - smoothstep(0.1, 0.5, dist) * (0.5 + shimmer * 0.5);
    
    vec3 colorBase = vec3(0.05, 0.12, 0.22);
    vec3 colorGrid = vec3(0.3, 0.6, 0.9) * (0.5 + shimmer * 0.5);
    vec3 colorSwell = vec3(0.7, 0.4, 0.2) * (0.6 + bass * 0.4);
    vec3 colorRupture = vec3(0.9, 0.8, 0.4) * (0.7 + bright * 0.3);
    vec3 colorCenter = vec3(0.8, 0.9, 1.0);
    
    vec3 col = colorBase;
    col += colorGrid * grid * (0.6 + cellPulse * 0.4);
    col += colorGrid * 0.5 * cellFill;
    col += colorSwell * swellRing * (0.5 + pulse * 0.5);
    col += colorRupture * ruptureLine * (1.0 + bright);
    col += colorCenter * silencePool * 0.4;
    col += vec3(0.2, 0.5, 0.8) * radialGrid * 0.3 * (1.0 - dist * 0.5);
    
    float bgLift = 0.15 + 0.1 * noise(uv * 2.0 + t * 0.2) + bass * 0.1;
    col += colorBase * bgLift * 2.0;
    
    float moonPhase = 0.5;
    float moonGlow = exp(-dist * 3.0) * 0.6 * moonPhase;
    col += vec3(0.5, 0.6, 0.8) * moonGlow;
    
    col = clamp(col, 0.0, 1.0);
    col = pow(col, vec3(0.85));
    col = mix(col, col * col * (3.0 - 2.0 * col), 0.3);
    
    fragColor = vec4(col, 1.0);
}