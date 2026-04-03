#version 330 core
// === 滞准期 / Conditional Hold State ===
// 2026-04-04 | pink;money
// 坎卦: 重险深渊 | 残月压重 | 悬浮辉度拒绝消散
//
// 结构:
//   前景 renderForeground  — 有机辉度质团，fbm扭曲半径，暖白核，下沉
//   背景 renderBackground  — 垂直深渊梯度，上暖灰/下冷黑，水层线
//   中层 renderMidStructure — 圆形压力干涉环，以质团为心，5环叠加
//   表面 applySurface       — 悬浮颗粒+折射微扰，液体混浊感
//   镜头 applyLens          — 垂直渐晕+深度色差+质团辉晕
//
// 时间: 背景×0.012 | 干涉环×0.09 | 质团×0.055 | 颗粒×4.8
// 音频: u_bass→深渊上升 u_mid→环密度 u_high→颗粒 u_onset→骤缩+色差 u_loudness→膨胀

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

// === Block 1: 背景层 ===
// 职责: 垂直深渊梯度场 — 上方辉度余辉 / 下方冷蓝黑虚空，水层线扰动
// 时间: t_slow = u_time * 0.012 (几乎静止的深渊)
// 音频: u_bass -> 深渊上升压缩上方空间, u_loudness -> 上方辉度

vec4 renderBackground(vec2 uv, float t_slow) {
    float waterY = 0.0 + 0.12 * fbm(vec2(uv.x * 0.8 + t_slow * 0.3, t_slow));
    float abyssRise = u_bass * 0.35;

    float depth = 1.0 - smoothstep(-0.9 + abyssRise, 0.6, uv.y);

    float wl = abs(uv.y - waterY - abyssRise * 0.5);
    float waterLine = exp(-wl * 22.0) * (0.08 + u_bass * 0.04);

    float surfaceBrightness = 0.12 + u_loudness * 0.07;
    vec3 surfaceColor = vec3(surfaceBrightness * 1.04, surfaceBrightness * 1.01, surfaceBrightness * 0.94);

    vec3 abyssColor = vec3(0.008, 0.012, 0.024);

    vec3 col = mix(surfaceColor, abyssColor, depth);
    col += vec3(0.28, 0.34, 0.42) * waterLine;

    return vec4(col, 1.0);
}

// === Block 2: 中间结构层 ===
// 职责: 以质团为心的圆形压力干涉环 — "river folding on itself"，5环叠加不等速
// 时间: t_mid = u_time * 0.09
// 音频: u_mid -> 环扩散速度与密度

vec4 renderMidStructure(vec2 uv, float t_mid) {
    vec2 center = vec2(
        0.05 * sin(t_mid * 0.41 + 1.3),
        0.08 + 0.06 * sin(t_mid * 0.27)
    );

    float dist = length(uv - center);
    float ringAcc = 0.0;

    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float baseR    = 0.18 + fi * 0.14;
        float speed    = (0.55 + fi * 0.09 + u_mid * 0.4) * t_mid;
        float phase    = hash1(fi * 2.71 + 0.33) * 6.283;
        float r        = baseR + 0.04 * sin(speed + phase)
                       + 0.015 * sNoise(vec2(dist * 3.0 + fi, t_mid * 0.5));

        float ringDist = abs(dist - r);
        float ringW    = 0.008 + fi * 0.002 + u_mid * 0.004;
        float ring     = smoothstep(ringW, 0.0, ringDist);

        float fadeOut  = smoothstep(0.85, 0.4, dist);
        float fadeIn   = smoothstep(0.04, 0.1, dist);
        float brightness = (0.35 - fi * 0.05) * (1.0 + u_mid * 0.2);

        ringAcc += ring * fadeOut * fadeIn * brightness;
    }

    ringAcc = clamp(ringAcc, 0.0, 1.0);

    vec3 ringColor = vec3(0.72, 0.80, 0.92);
    return vec4(ringColor * ringAcc, ringAcc * 0.5);
}

// === Block 3: 前景主体层 ===
// 职责: 有机辉度质团 — fbm双层扭曲半径，暖白核，拒绝消散，缓慢下沉
// 时间: t_base = u_time * 0.055
// 音频: u_onset -> 骤缩崩解脉冲, u_loudness -> 辉度膨胀

vec4 renderForeground(vec2 uv, float t_base) {
    float sinkY = 0.15 - t_base * 0.012;
    sinkY = sinkY - floor(sinkY / 1.2 + 0.5) * 1.2;
    vec2 center = vec2(
        0.04 * sin(t_base * 0.38 + 0.7),
        sinkY + 0.08 * sin(t_base * 0.21)
    );

    vec2 p = uv - center;

    vec2 q = vec2(
        fbm(p * 1.8 + vec2(t_base * 0.12, t_base * 0.08)),
        fbm(p * 1.8 + vec2(0.4 + t_base * 0.09, 0.7 + t_base * 0.06))
    );
    vec2 r = vec2(
        fbm(p * 2.2 + 2.0 * q + vec2(1.7 + t_base * 0.05, 9.2)),
        fbm(p * 2.2 + 2.0 * q + vec2(8.3 + t_base * 0.04, 2.8))
    );

    float distorted = length(p) + 0.22 * length(q) + 0.08 * length(r);

    float onsetShrink = u_onset * 0.08 * exp(-u_onset * 3.0);
    float baseRadius = 0.18 + u_loudness * 0.06 - onsetShrink;

    float d = distorted - baseRadius;

    float core  = smoothstep(0.04, 0.0, d + 0.06);
    float halo  = smoothstep(0.22, 0.0, d) * 0.4;
    float glow  = exp(-max(d, 0.0) * 5.5) * 0.25;

    float total = clamp(core + halo + glow, 0.0, 1.0);

    vec3 coreColor = vec3(0.96, 0.93, 0.88);
    vec3 haloColor = vec3(0.68, 0.55, 0.32);
    vec3 col = mix(haloColor, coreColor, core);

    float alpha = clamp(total, 0.0, 1.0);
    return vec4(col * total, alpha * 0.92);
}

// === Block 4: 表面层 ===
// 职责: 悬浮颗粒（液体混浊感）+ 折射微扰（水的光学特性）
// 时间: t_fast = u_time * 4.8
// 音频: u_high -> 颗粒密度与折射强度

vec4 applySurface(vec2 uv, float t_fast, vec4 base) {
    vec2 particleUV1 = uv * 280.0 + vec2(t_fast * 0.7, t_fast * 0.4);
    vec2 particleUV2 = uv * 380.0 + vec2(-t_fast * 0.5, t_fast * 0.8);
    float p1 = hash2(floor(particleUV1));
    float p2 = hash2(floor(particleUV2));
    float particleAmt = 0.018 + u_high * 0.022;
    float particleVal = ((p1 + p2) * 0.5 - 0.5) * particleAmt;

    float refract = sNoise(uv * 5.5 + vec2(t_fast * 0.06, t_fast * 0.04));
    float refractAmt = 0.012 + u_high * 0.010;
    float refractVal = (refract - 0.5) * refractAmt;

    vec3 col = base.rgb + particleVal + refractVal;
    return vec4(col, base.a);
}

// === Block 5: 镜头后处理 ===
// 职责: 垂直渐晕（底部强压暗）+ 深度色差（越往底部RGB分裂越大）+ 质团辉晕染
// 音频: u_onset -> 色差峰值, u_bass -> 底部色差强度

vec3 applyLens(vec3 col, vec2 uv) {
    float vVig = smoothstep(-1.1, 0.5, uv.y);
    float hVig = 1.0 - smoothstep(0.6, 1.4, abs(uv.x) * 0.9);
    col *= vVig * hVig;

    float depthFactor = 1.0 - smoothstep(-0.8, 0.6, uv.y);
    float caAmt = (0.004 + u_bass * 0.012 + u_onset * 0.018) * depthFactor;
    float rShift = caAmt * 2.0 * sign(uv.x) * abs(uv.x);
    float bShift = -caAmt * 1.4 * abs(uv.y + 0.2);
    col.r += col.r * rShift;
    col.b += col.b * bShift;

    float cx = length(uv - vec2(0.0, 0.12));
    float massGlow = exp(-cx * 2.8) * (0.06 + u_loudness * 0.05);
    vec3 warmGlowColor = vec3(0.58, 0.44, 0.22);
    col += warmGlowColor * massGlow;

    col = clamp(col, 0.0, 1.0);
    return col;
}

// === Block 6: main ===

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    float t_slow = u_time * 0.012;
    float t_mid  = u_time * 0.09;
    float t_base = u_time * 0.055;
    float t_fast = u_time * 4.8;

    vec4 bg  = renderBackground(uv, t_slow);
    vec4 mid = renderMidStructure(uv, t_mid);
    vec4 fg  = renderForeground(uv, t_base);

    vec4 composed = bg;
    composed.rgb = mix(composed.rgb, mid.rgb, mid.a * 0.65);
    composed.rgb = mix(composed.rgb, fg.rgb, fg.a);

    composed = applySurface(uv, t_fast, composed);

    vec3 final = applyLens(composed.rgb, uv);

    fragColor = vec4(final, 1.0);
}
