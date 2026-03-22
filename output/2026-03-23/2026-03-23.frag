#version 330

uniform float u_time;
uniform vec2 u_resolution;
uniform float u_bass_energy;
uniform float u_shimmer;
uniform float u_pulse_amp;
uniform float u_spectral_brightness;
uniform float u_density;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1,0)), u.x),
               mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x), u.y);
}

vec3 queueBody(vec2 uv, float index, float time) {
    float bass = u_bass_energy * 0.5 + 0.5;
    float phase = index * 0.7 + time * 0.3;
    float xPos = fract(index * 0.618) * 1.8 - 0.9;
    float yBase = -0.6 + index * 0.05;
    float sway = sin(phase * 1.3) * 0.02 * bass;
    vec2 bodyPos = vec2(xPos + sway, yBase);
    float dist = length(uv - bodyPos);
    float bodyH = 0.25 + u_pulse_amp * 0.05;
    float bodyW = 0.04 + bass * 0.015;
    vec2 diff = uv - bodyPos;
    float ellipse = diff.x * diff.x / (bodyW * bodyW) + diff.y * diff.y / (bodyH * bodyH);
    float body = smoothstep(1.1, 0.7, ellipse);
    float vibFreq = 12.0 + u_spectral_brightness * 8.0;
    float vib = sin(uv.y * vibFreq + time * 6.0 + index * 2.1) * 0.5 + 0.5;
    float hue = fract(index * 0.15 + time * 0.04);
    vec3 col = 0.5 + 0.5 * cos(6.28318 * (vec3(hue, hue + 0.33, hue + 0.66)));
    col = mix(col * 0.6, col * 1.4, vib);
    return body * col;
}

vec3 thresholdGate(vec2 uv, float time) {
    float gate = u_bass_energy * 0.3 + 0.5;
    float narrowing = 0.15 + gate * 0.25;
    float gateX = abs(uv.x);
    float inGate = smoothstep(narrowing + 0.01, narrowing - 0.01, gateX);
    float scanLine = sin(uv.y * 40.0 - time * 3.0) * 0.5 + 0.5;
    float pulse = sin(time * 8.0) * 0.5 + 0.5;
    pulse = mix(pulse, 1.0, u_pulse_amp);
    vec3 gateColor = vec3(0.9, 0.7, 0.3) * scanLine * pulse * 2.0;
    float edgeGlow = exp(-abs(abs(uv.x) - narrowing) * 30.0);
    vec3 edgeColor = vec3(1.0, 0.4, 0.1) * edgeGlow * (1.0 + u_shimmer);
    return (gateColor * inGate + edgeColor) * 0.8;
}

vec3 densityField(vec2 uv, float time) {
    float d = u_density * 0.5 + 0.5;
    float n1 = noise(uv * 3.0 + time * 0.2);
    float n2 = noise(uv * 7.0 - time * 0.15 + 1.5);
    float n3 = noise(uv * 15.0 + time * 0.4 + 3.0);
    float field = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
    float saturation = smoothstep(0.3, 0.9, field) * d;
    vec3 col1 = vec3(0.2, 0.5, 0.9);
    vec3 col2 = vec3(0.9, 0.3, 0.6);
    vec3 col3 = vec3(1.0, 0.8, 0.2);
    vec3 color = mix(col1, col2, n1);
    color = mix(color, col3, n3 * 0.4);
    return color * saturation * 0.7;
}

vec3 frequencyBars(vec2 uv, float time) {
    float freq = 20.0 + u_spectral_brightness * 30.0;
    float bars = sin(uv.x * freq + time * 2.0) * 0.5 + 0.5;
    float locked = smoothstep(0.45, 0.55, bars);
    float height = 0.3 + u_pulse_amp * 0.3;
    float inBar = smoothstep(height, height - 0.05, abs(uv.y + 0.2));
    vec3 barColor = vec3(0.3, 0.9, 0.8) * locked * inBar;
    float shimmerWave = sin(uv.x * 80.0 + time * 15.0) * u_shimmer * 0.3;
    return barColor * (1.0 + shimmerWave);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);
    float time = u_time;
    
    vec3 bg = vec3(0.08, 0.05, 0.15);
    bg += densityField(uv, time);
    
    vec3 bodies = vec3(0.0);
    for (int i = 0; i < 12; i++) {
        bodies += queueBody(uv, float(i), time);
    }
    
    vec3 gate = thresholdGate(uv, time);
    vec3 freqBars = frequencyBars(uv, time);
    
    float lockPulse = sin(time * 6.2832 * (1.0 + u_bass_energy * 0.5)) * 0.5 + 0.5;
    float centerGlow = exp(-length(uv) * 1.5) * lockPulse * 0.6;
    vec3 glowColor = vec3(0.8, 0.6, 1.0) * centerGlow;
    
    vec3 color = bg + bodies * 1.2 + gate + freqBars + glowColor;
    
    float vignette = 1.0 - smoothstep(0.6, 1.4, length(uv));
    color *= (0.7 + vignette * 0.3);
    
    float brightness = 0.3 + u_spectral_brightness * 0.2 + lockPulse * 0.1;
    color = max(color, vec3(brightness * 0.15));
    color = pow(clamp(color, 0.0, 1.0), vec3(0.85));
    
    fragColor = vec4(color, 1.0);
}