// === 准入阈 / Access Threshold ===
// 2026-04-03 | pink;money
// 大过卦: 超载弯折 | 满月对压 | 准入结构崩塌
//
// 结构:
//   背景 \pressure_ground    — 30-80Hz 极低频静压场，几乎静止
//   主体 \permission_beam    — 200-2kHz 弯折弦谐波系统，高压不稳定
//   中层 \threshold_relay    — 500-2400Hz 继电器 gate 脉冲，准入/拒绝二元切换
//   表面  嵌入主体内部        — 4-9kHz 热摩擦颗粒，断裂边缘质感
//   空间  非对称变形容器       — 主体左右不等延迟，中层 AllpassC 扩散
//
// 时间: 背景 0.02-0.04Hz | 主体 0.08-0.25Hz | 中层 0.5-3Hz | 表面 Dust5-12Hz
// 控制: ~brightness->主体滤波过热 ~energy->背景压力 ~motion->继电器密度 ~complexity->表面颗粒

// === Block 1: 背景层 ===
// 职责: 极低频静压场，建立重量感与空间底色，完全不携带音高信息
// 频率区: 28-90Hz (次低频)
// 时间尺度: 0.02-0.04 Hz (极慢，官僚静止)
// 音频: ~energy -> 静压振幅

SynthDef(\pressure_ground, {
	arg amp=0.22;
	var sig, env, pressure, weight;
	var baseFreq;

	env = EnvGen.kr(Env.asr(14, 1, 12), \gate.kr(1), doneAction: 2);

	pressure = (~energy ? 0.5) * 0.6 + LFNoise2.kr(0.025).range(0.15, 0.75);

	baseFreq = LFNoise1.kr(0.018).exprange(32, 68);
	weight = BPF.ar(BrownNoise.ar(0.8), baseFreq, 0.04, 6.0);
	weight = weight + BPF.ar(BrownNoise.ar(0.6), baseFreq * 1.7, 0.03, 4.0);
	weight = weight + (SinOsc.ar(baseFreq * 0.5, 0, 0.12) * LFNoise2.kr(0.03).range(0.3, 1.0));

	sig = weight * pressure * env * amp;
	sig = HPF.ar(sig, 25);
	sig = LPF.ar(sig, 95);
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.75);
	sig = Pan2.ar(sig, 0);

	SendReply.kr(Impulse.kr(30), '/audio/bass',
		Amplitude.kr(sig.sum, 0.08, 0.35));

	Out.ar(0, sig);
}).add;


// === Block 2: 主体层 ===
// 职责: 弯折弦谐波系统 — 高压不稳定的 Formant + 谐波列，表面嵌入热摩擦颗粒
// 频率区: 180-2200Hz (中频主体) + 4000-9000Hz (表面颗粒嵌入)
// 时间尺度: 0.08-0.25 Hz (弯折张力)
// 音频: ~brightness -> 滤波过热 | ~complexity -> 表面颗粒密度

SynthDef(\permission_beam, {
	arg freq=220, amp=0.28;
	var sig, env, tension, harmonics;
	var surface, grain, cutoff, grainDensity;
	var spatL, spatR;

	env = EnvGen.kr(Env.asr(8, 1, 10), \gate.kr(1), doneAction: 2);

	tension = LFNoise2.kr(0.09).range(0.2, 1.0)
	        + LFNoise1.kr(0.22).range(-0.15, 0.15);

	harmonics = Mix.fill(6, { |i|
		var n, detune, instab, f, partial;
		n = (i + 1);
		detune = LFNoise2.kr(0.08 + (i * 0.03)).range(-0.012, 0.012);
		instab = LFNoise2.kr(0.18 + (i * 0.07)).range(0.0, 0.06) * tension;
		f = (freq * n * (1 + detune + instab)).clip(120, 11000);
		partial = SinOsc.ar(f, 0, (1.0 / n.sqrt) * 0.18);
		partial * LFNoise2.kr(0.04 + (i * 0.02)).range(0.5, 1.0);
	});

	cutoff = 600 + (tension * 1200) + ((~brightness ? 0.5) * 1600);
	sig = RLPF.ar(harmonics, cutoff.clip(300, 4500), 0.15 + (tension * 0.25));
	sig = sig + (BPF.ar(harmonics, cutoff * 1.8, 0.08) * 0.2);

	grainDensity = 5 + ((~complexity ? 0.5) * 8);
	grain = Dust.ar(grainDensity);
	surface = BPF.ar(
		WhiteNoise.ar(Decay.ar(grain, 0.003)),
		LFNoise0.kr(12).exprange(4200, 8800),
		0.015, 3.0
	) * 0.06;

	sig = sig + surface;

	spatL = CombL.ar(sig, 0.2, 0.082, LFNoise1.kr(0.04).range(1.5, 4.0), 0.28);
	spatR = CombL.ar(sig, 0.2, 0.131, LFNoise1.kr(0.035).range(1.2, 3.5), 0.22);
	sig = [sig + (spatL * 0.35), sig + (spatR * 0.3)];

	sig = sig * env * amp;
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.82);

	SendReply.kr(Impulse.kr(30), '/audio/mid',
		Amplitude.kr(BPF.ar(sig.sum, 900, 1.0), 0.03, 0.15));

	Out.ar(0, sig);
}).add;


// === Block 3: 中间结构层 ===
// 职责: 继电器 gate 脉冲 — 准入/拒绝二元切换，共鸣尾迹落在主体谐波的倍频区
// 频率区: 480-2600Hz (桥接主体与背景之间的中频)
// 时间尺度: 0.5-3 Hz (密度跳变，中等速度)
// 音频: ~motion -> gate 脉冲密度

SynthDef(\threshold_relay, {
	arg freq=440, amp=0.18;
	var sig, env, relayRing;
	var density, gateOpen, gateClose;
	var spread;

	env = EnvGen.kr(Env.asr(5, 1, 7), \gate.kr(1), doneAction: 2);

	density = (~motion ? 0.5) * 3.0 + LFNoise0.kr(0.4).range(0.4, 2.8);
	gateOpen  = Dust.kr(density);
	gateClose = Dust.kr(density * 0.7 + 0.3);

	relayRing = Mix.fill(4, { |i|
		var rFreq, openRing, closeRing;
		rFreq = (freq * [1.0, 1.49, 2.03, 3.17].at(i)).clip(420, 2800);
		openRing  = Ringz.ar(Decay.ar(T2A.ar(gateOpen),  0.001, 1.0), rFreq, Rand(0.04, 0.22));
		closeRing = Ringz.ar(Decay.ar(T2A.ar(gateClose), 0.001, 0.7), rFreq * 0.93, Rand(0.02, 0.12));
		(openRing * 0.22) + (closeRing * 0.12);
	});

	sig = AllpassC.ar(relayRing, 0.4, LFNoise2.kr(0.09).range(0.05, 0.32), 2.5, 0.25);
	sig = sig + relayRing;
	sig = HPF.ar(sig, 400);
	sig = LPF.ar(sig, 2800);
	sig = sig * env * amp;
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.75);

	spread = LFNoise2.kr(0.18).range(-0.65, 0.65);
	sig = Pan2.ar(sig, spread);

	SendReply.kr(Impulse.kr(30), '/audio/onset',
		Amplitude.kr(sig.sum, 0.005, 0.04));

	Out.ar(0, sig);
}).add;


// === Block 5: 空间设计 ===
// 主体: 非对称 CombL 左右(0.082s / 0.131s) — 容器在超载下变形
// 中层: AllpassC 随机扩散(0.05-0.32s) — 继电器声分布于空间
// 背景: 无空间化 — 压力是全域的，没有方向
// 深度: 背景(干) < 中层(中扩散) < 主体(不对称延迟)

// === Block 6: 时间组织 ===
// 段落 rrand(22,42)秒，先背景->主体->继电器，段落后半张力积累

fork {
	var groundFreqs = [31, 37, 43, 52, 58];
	var beamFreqs   = [138, 174, 196, 220, 261, 311];
	var relayFreqs  = [349, 440, 523, 587, 698];

	inf.do { |i|
		var gFreq, bFreq, rFreq, dur, halfDur;
		gFreq   = groundFreqs.choose.midicps;
		bFreq   = beamFreqs.choose;
		rFreq   = relayFreqs.choose;
		dur     = rrand(22, 42);
		halfDur = dur * 0.5;

		if (~ground.notNil, { ~ground.set(\gate, 0) });
		if (~beam.notNil,   { ~beam.set(\gate, 0) });
		if (~relay.notNil,  { ~relay.set(\gate, 0) });

		rrand(2.5, 5.0).wait;

		~ground = Synth(\pressure_ground, [
			\amp, rrand(0.18, 0.26)
		]);

		rrand(3.0, 7.0).wait;

		~beam = Synth(\permission_beam, [
			\freq, bFreq,
			\amp, rrand(0.22, 0.30)
		]);

		rrand(2.0, 5.0).wait;

		~relay = Synth(\threshold_relay, [
			\freq, rFreq,
			\amp, rrand(0.14, 0.22)
		]);

		halfDur.wait;

		if (~beam.notNil,  { ~beam.set(\amp,  rrand(0.26, 0.35)) });
		if (~relay.notNil, { ~relay.set(\amp, rrand(0.18, 0.26)) });

		(halfDur * 0.85).wait;
	};
};
