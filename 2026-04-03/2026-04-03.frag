#version 330 core
// === 准入阈 / Access Threshold ===
// 2026-04-03 | pink;money
// 前景: 5条垂直权限闸条(振荡于门与膜之间) | 背景: 双区域垂直梯度场(准入/拒绝)
// 中层: 透过闸条的垂直光束条纹 | 表面: 水平干涉纹(膜张力质感)
// 镜头: 水平渐晕+溢光+色差 | 大过卦/满月/准入结构崩塌

uniform float u_time;
uniform vec2  u_resolution;
uniform float u_bass;
uniform float u_mid;
uniform float u_high;
uniform float u_loudness;
uniform float u_onset;

out vec4 fragColor;

// ─── 共享工具 ────────────────��───────────────────────────────────────────────

float hash1(float n) {
    return fract(sin(n) * 43758.5453);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float sNoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash2(i), hash2(i + vec2(1,0)), f.x),
        mix(hash2(i + vec2(0,1)), hash2(i + vec2(1,1)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 m = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 4; i++) {
        v += a * sNoise(p);
        p = m * p * 2.1;
        a *= 0.5;
    }
    return v;
}

// SDF: 垂直闸条（在 x 轴方向的有符号距离，负值=闸条内部）
float sdVSlat(vec2 p, float cx, float hw) {
    return abs(p.x - cx) - hw;
}

// === Block 1: 背景层 ===
// 职责: 双区域垂直梯度场 — 准入区(上)/拒绝区(下)，以 fbm 漂移边界线为轴
// 时间: t_slow = u_time * 0.025 (官僚静止感)
// 音频: u_bass -> 拒绝区向上扩张, u_loudness -> 准入区亮度

vec4 renderBackground(vec2 uv, float t_slow) {
    float boundaryY = -0.05 + 0.18 * fbm(vec2(uv.x * 1.2 + t_slow, t_slow * 0.4));
    boundaryY += u_bass * 0.25;

    float distToBoundary = uv.y - boundaryY;

    float accessBrightness = 0.10 + u_loudness * 0.08;
    vec3 accessColor = vec3(accessBrightness * 1.02, accessBrightness, accessBrightness * 0.96);
    vec3 refuseColor = vec3(0.018, 0.022, 0.032);

    float boundaryGlow = exp(-abs(distToBoundary) * 18.0) * (0.12 + u_loudness * 0.06);
    vec3 glowColor = vec3(0.55, 0.42, 0.28);

    float t = smoothstep(-0.04, 0.04, distToBoundary);
    vec3 col = mix(refuseColor, accessColor, t);
    col += glowColor * boundaryGlow;

    return vec4(col, 1.0);
}

// === Block 2: 中间结构层 ===
// 职责: 8条透过闸条间隙的垂直光束 — 被允许通过的光，在漂移中
// 时间: t_mid = u_time * 0.12
// 音频: u_mid -> 漂移速度与间距变化

vec4 renderMidStructure(vec2 uv, float t_mid) {
    float beamAcc = 0.0;

    for (int i = 0; i < 8; i++) {
        float fi = float(i);
        float baseX = -0.91 + fi * 0.26;
        float drift = 0.045 * sin(t_mid * (0.6 + fi * 0.13) + fi * 2.17)
                    * (1.0 + u_mid * 0.9);
        float bx = baseX + drift;

        float dist = abs(uv.x - bx);
        float core = smoothstep(0.005, 0.0, dist);
        float halo = smoothstep(0.055, 0.01, dist) * 0.08;
        float beam = core + halo;

        float vFade = smoothstep(-0.55, 0.1, uv.y) * smoothstep(0.9, 0.3, uv.y);
        float brightness = 0.55 + fi * 0.04;

        beamAcc += beam * vFade * brightness;
    }

    beamAcc = clamp(beamAcc, 0.0, 1.0);
    vec3 beamColor = vec3(0.88, 0.86, 0.80);
    return vec4(beamColor * beamAcc, beamAcc * 0.55);
}

// === Block 3: 前景主体层 ===
// 职责: 5条垂直权限闸条，在 gate(窄/不透明) 与 membrane(宽/半透明) 之间振荡
// 时间: t_base = u_time * 0.06
// 音频: u_onset -> 全体崩解脉冲(膜化), u_loudness -> 超载溢光亮度

vec4 renderForeground(vec2 uv, float t_base) {
    float onsetExpand = u_onset * 0.036 * exp(-u_onset * 2.5);

    float slatAcc  = 0.0;
    float innerAcc = 0.0;

    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float phase = hash1(fi * 3.17 + 0.61) * 6.283;
        float cx = -0.8 + fi * 0.4;

        float osc = 0.5 + 0.5 * sin(t_base * (0.45 + fi * 0.19) + phase);
        float hw = mix(0.006, 0.038, osc) + onsetExpand;

        float d = sdVSlat(uv, cx, hw);

        float lineW = 0.0025;
        float outline = 1.0 - smoothstep(0.0, lineW * 2.0, abs(d));
        float inner = step(d, 0.0) * mix(0.08, 0.02, osc);
        float edgeGlow = (0.72 + 0.28 * sin(t_base * 1.1 + fi * 0.8))
                       * (0.8 + u_loudness * 0.3);

        slatAcc  += outline * edgeGlow;
        innerAcc += inner;
    }

    slatAcc  = clamp(slatAcc,  0.0, 1.0);
    innerAcc = clamp(innerAcc, 0.0, 1.0);

    vec3 slatColor  = vec3(0.94, 0.91, 0.85);
    vec3 innerColor = vec3(0.05, 0.05, 0.08);

    vec3 col = slatColor * slatAcc + innerColor * innerAcc;
    float alpha = clamp(slatAcc + innerAcc * 0.4, 0.0, 1.0);

    return vec4(col, alpha);
}

// === Block 4: 表面层 ===
// 职责: 水平干涉纹 — 膜在张力下的物理质感 + 高频颗粒
// 时间: t_fast = u_time * 4.2
// 音频: u_high -> 干涉纹密度与颗粒量

vec4 applySurface(vec2 uv, float t_fast, vec4 base) {
    float density = 55.0 + u_high * 40.0;
    float fringePhase = uv.y * density + t_fast * 0.8
                      + sNoise(uv * 3.0 + vec2(0.0, t_fast * 0.2)) * 1.8;
    float fringe = sin(fringePhase) * 0.5 + 0.5;
    float fringeAmt = 0.022 + u_high * 0.018;
    float fringeVal = (fringe - 0.5) * fringeAmt;

    vec2 grainUV = uv * 420.0 + vec2(t_fast * 6.1, t_fast * 2.7);
    float grain = hash2(floor(grainUV));
    float grainAmt = 0.025 + u_high * 0.025;
    float grainVal = (grain - 0.5) * grainAmt;

    vec3 col = base.rgb + fringeVal + grainVal;
    return vec4(col, base.a);
}

// === Block 5: 镜头后处理 ===
// 职责: 水平渐晕(强调竖向结构) + 闸条溢光(超载暖色) + 横向色差(准入阈处光分裂)
// 音频: u_onset -> 色差峰值, u_loudness -> 溢光强度

vec3 applyLens(vec3 col, vec2 uv) {
    float hVig = 1.0 - smoothstep(0.45, 1.3, abs(uv.x) * 1.1);
    float vVig = 0.82 + 0.18 * smoothstep(-0.9, 0.4, uv.y);
    col *= hVig * vVig;

    float slatGlow = 0.0;
    for (int i = 0; i < 5; i++) {
        float cx = -0.8 + float(i) * 0.4;
        slatGlow += exp(-abs(uv.x - cx) * 28.0);
    }
    slatGlow = clamp(slatGlow, 0.0, 1.0);
    vec3 heatColor = vec3(0.48, 0.28, 0.12);
    col += heatColor * slatGlow * (0.04 + u_loudness * 0.06);

    float caAmt = 0.003 + u_onset * 0.014;
    float rShift = caAmt * 2.2 * sign(uv.x) * abs(uv.x);
    float bShift = -caAmt * 1.6 * sign(uv.x) * abs(uv.x);
    col.r += col.r * rShift;
    col.b += col.b * bShift;

    col = clamp(col, 0.0, 1.0);
    return col;
}

// === Block 6: main ===

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t_slow = u_time * 0.025;
    float t_mid  = u_time * 0.12;
    float t_base = u_time * 0.06;
    float t_fast = u_time * 4.2;

    vec4 bg  = renderBackground(uv, t_slow);
    vec4 mid = renderMidStructure(uv, t_mid);
    vec4 fg  = renderForeground(uv, t_base);

    vec4 composed = bg;
    composed.rgb = mix(composed.rgb, mid.rgb, mid.a * 0.75);
    composed.rgb = mix(composed.rgb, fg.rgb, fg.a);

    composed = applySurface(uv, t_fast, composed);

    vec3 final = applyLens(composed.rgb, uv);

    fragColor = vec4(final, 1.0);
}
