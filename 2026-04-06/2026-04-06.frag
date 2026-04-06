#version 330 core
// === 阈值审批 / Clearance Pending State ===
// 2026-04-06 | pink;money
// 咸卦: 感应/吸引 | 两极之间的无接触场域 | 审批等待的轨迹可见化
//
// 结构:
//   前景 renderForeground  — 磁偶极子流线场，atan势函数等势线，12条案例轨迹
//   背景 renderBackground  — 极细密水平静电条纹，低照度压缩场
//   中层 renderMidStructure — 两极高斯影响区，极间提亮，磁极缓慢漂移
//   表面 applySurface       — 全局双尺度静电颗粒，dense static field物质感
//   镜头 applyLens          — 弱vignette+横向色差(磁场色散)+低对比度
//
// 时间: 背景×0.018 | 磁极×0.07 | 场线×0.045 | 静电×5.5
// 音频: u_bass→条纹密度 u_mid→极间场强 u_high→静电颗粒 u_onset→场线爆发+色差 u_loudness→亮度

uniform float u_time;
uniform vec2  u_resolution;
uniform float u_bass;
uniform float u_mid;
uniform float u_high;
uniform float u_loudness;
uniform float u_onset;

out vec4 fragColor;

// ─── 共享工具 ─────────────────────────────────────────────────────────────────

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

// === Block 1: 背景层 ===
// 职责: 极细密水平静电条纹，低照度冷蓝灰压缩场 — "dense static field compressing inward"
// 时间: t_slow = u_time * 0.018
// 音频: u_bass -> 条纹密度（压力增大则更密）, u_loudness -> 整体亮度

vec4 renderBackground(vec2 uv, float t_slow) {
    float density = 80.0 + u_bass * 60.0;

    float noiseOffset = sNoise(vec2(uv.x * 0.8 + t_slow * 0.3, t_slow * 0.2)) * 2.2;

    float stripe = sin(uv.y * density + noiseOffset + t_slow * 0.8) * 0.5 + 0.5;
    stripe = smoothstep(0.35, 0.65, stripe);

    float baseBrightness = 0.045 + u_loudness * 0.028;
    vec3 baseColor = vec3(baseBrightness * 0.85, baseBrightness * 0.91, baseBrightness * 1.12);

    vec3 stripeColor = vec3(0.062, 0.068, 0.088);
    vec3 col = mix(baseColor, stripeColor, stripe * 0.55);

    return vec4(col, 1.0);
}

// === Block 2: 中间结构层 ===
// 职责: 两极高斯影响区 — 极间区域轻微提亮，吸引力场的空间标记
// 时间: t_mid = u_time * 0.07 (磁极缓慢漂移)
// 音频: u_mid -> 极间场强辉光强度

vec4 renderMidStructure(vec2 uv, float t_mid) {
    vec2 P1 = vec2(
        -0.32 + 0.08 * sin(t_mid * 0.61 + 1.2),
         0.22 + 0.06 * sin(t_mid * 0.43)
    );
    vec2 P2 = vec2(
         0.30 + 0.07 * sin(t_mid * 0.55 + 2.1),
        -0.20 + 0.05 * sin(t_mid * 0.38 + 0.7)
    );

    float r1 = length(uv - P1);
    float r2 = length(uv - P2);
    float g1 = exp(-r1 * 3.2) * (0.12 + u_mid * 0.10);
    float g2 = exp(-r2 * 3.2) * (0.12 + u_mid * 0.10);

    float bridge = exp(-length(uv - (P1 + P2) * 0.5) * 2.4) * (0.06 + u_mid * 0.06);

    float total = clamp(g1 + g2 + bridge, 0.0, 1.0);

    vec3 poleColor   = vec3(0.78, 0.74, 0.68);
    vec3 bridgeColor = vec3(0.55, 0.65, 0.82);
    vec3 col = mix(bridgeColor, poleColor, clamp((g1 + g2) / (total + 0.001), 0.0, 1.0));

    return vec4(col * total, total * 0.7);
}

// === Block 3: 前景主体层 ===
// 职责: 磁偶极子流线场 — atan势函数等势线，审批等待轨迹的可见化
// 时间: t_base = u_time * 0.045
// 音频: u_onset -> 场线密度骤增脉冲（案件堆积崩塌）, u_loudness -> 线亮度

vec4 renderForeground(vec2 uv, float t_base) {
    float tm = t_base * (0.07 / 0.045);
    vec2 P1 = vec2(
        -0.32 + 0.08 * sin(tm * 0.61 + 1.2),
         0.22 + 0.06 * sin(tm * 0.43)
    );
    vec2 P2 = vec2(
         0.30 + 0.07 * sin(tm * 0.55 + 2.1),
        -0.20 + 0.05 * sin(tm * 0.38 + 0.7)
    );

    vec2 d1 = uv - P1;
    vec2 d2 = uv - P2;
    float phi = atan(d1.y, d1.x) - atan(d2.y, d2.x);

    float lineDensity = 12.0
        + u_onset * 18.0 * exp(-u_onset * 2.0)
        + 2.5 * sin(t_base * 0.8);

    float lineVal = sin(phi * lineDensity + t_base * 1.1) * 0.5 + 0.5;
    float lineSharp = smoothstep(0.32, 0.52, lineVal);

    float fieldStr = 1.0 / (length(d1) * length(d2) + 0.08);
    fieldStr = clamp(fieldStr * 0.12, 0.0, 1.0);

    float flicker = 0.55 + 0.45 * sin(t_base * 0.62 + phi * 0.3);

    float line = lineSharp * fieldStr * flicker;
    line = clamp(line, 0.0, 1.0);

    float warmness = clamp(exp(-length(uv - P1) * 4.0) + exp(-length(uv - P2) * 4.0), 0.0, 1.0);
    vec3 lineColor = mix(
        vec3(0.72, 0.76, 0.85),
        vec3(0.88, 0.84, 0.75),
        warmness
    );

    float brightness = 0.8 + u_loudness * 0.25;
    float alpha = clamp(line * brightness, 0.0, 1.0);
    return vec4(lineColor * alpha, alpha * 0.88);
}

// === Block 4: 表面层 ===
// 职责: 全局双尺度静电颗粒 — "dense static field"的物质感
// 时间: t_fast = u_time * 5.5
// 音频: u_high -> 静电颗粒强度

vec4 applySurface(vec2 uv, float t_fast, vec4 base) {
    vec2 g1UV = uv * 180.0 + vec2(t_fast * 0.9, t_fast * 0.4);
    float g1 = hash2(floor(g1UV));

    vec2 g2UV = uv * 520.0 + vec2(-t_fast * 0.6, t_fast * 1.1);
    float g2 = hash2(floor(g2UV));

    float grainAmt = 0.022 + u_high * 0.028;
    float grainVal = ((g1 * 0.6 + g2 * 0.4) - 0.5) * grainAmt;

    vec3 col = base.rgb + grainVal;
    return vec4(col, base.a);
}

// === Block 5: 镜头后处理 ===
// 职责: 弱vignette（强调中央场域）+ 横向色差（磁场对光的色散）+ 低对比度
// 音频: u_onset -> 色差峰值, u_loudness -> 最终亮度微调

vec3 applyLens(vec3 col, vec2 uv) {
    float vig = 1.0 - smoothstep(0.55, 1.35, length(uv) * 0.95);
    col *= vig;

    float caAmt = 0.0025 + u_onset * 0.012;
    float rShift = caAmt * 2.1 * uv.x;
    float bShift = -caAmt * 1.5 * uv.x;
    col.r += col.r * rShift;
    col.b += col.b * bShift;

    col *= (0.88 + u_loudness * 0.16);

    col = clamp(col, 0.0, 1.0);
    return col;
}

// === Block 6: main ===

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t_slow = u_time * 0.018;
    float t_mid  = u_time * 0.07;
    float t_base = u_time * 0.045;
    float t_fast = u_time * 5.5;

    vec4 bg  = renderBackground(uv, t_slow);
    vec4 mid = renderMidStructure(uv, t_mid);
    vec4 fg  = renderForeground(uv, t_base);

    vec4 composed = bg;
    composed.rgb = mix(composed.rgb, mid.rgb, mid.a * 0.72);
    composed.rgb = mix(composed.rgb, fg.rgb, fg.a);

    composed = applySurface(uv, t_fast, composed);

    vec3 final = applyLens(composed.rgb, uv);

    fragColor = vec4(final, 1.0);
}
