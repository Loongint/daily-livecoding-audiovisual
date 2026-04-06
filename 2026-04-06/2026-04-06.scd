// === 阈值审批 / Clearance Pending State ===
// 2026-04-06 | pink;money
// 咸卦: 感应/吸引 | 皮肤在手到之前已经共鸣 | 雷声不破只是增厚
//
// 结构:
//   背景 \static_membrane   — 22-120Hz 宽频低噪声底色，全域静压
//   主体 \pull_interference  — 200-1600Hz 6对拍频干涉网络，慢律动张力
//   中层 \field_hum          — 180-2000Hz 奇次谐波standing wave，各自独立调制
//   表面  嵌入主体内部        — 4-9kHz 皮肤感BPF扫描，轻薄共鸣
//   空间  两极分处两侧         — 主体非对称CombL，中层AllpassC扩散，背景全域中置
//
// 时间: 背景 0.012Hz | 拍频偏移 0.06-0.15Hz | 谐波 0.1-0.4Hz | 皮肤扫描 4-7Hz
// 控制: ~density->拍频偏移量 ~energy->背景振幅 ~brightness->谐波亮度 ~motion->扫描速率

// === Block 1: 背景层 ===
// 职责: 宽频低噪声底色，"dense static field compressing inward"的声音基础
// 频率区: 22-120Hz (次低频宽频噪声，无音高感)
// 时间尺度: 0.012 Hz (几乎静止)
// 音频: ~energy -> 基础振幅

SynthDef(\static_membrane, {
	arg amp=0.22;
	var sig, env, pressure;

	env = EnvGen.kr(Env.asr(16, 1, 14), \gate.kr(1), doneAction: 2);

	pressure = (~energy ? 0.5) * 0.45 + 0.38
	         + LFNoise2.kr(0.012).range(-0.10, 0.10);

	sig = PinkNoise.ar(0.9);
	sig = LPF.ar(sig, 122);
	sig = HPF.ar(sig, 20);

	sig = sig + (BPF.ar(PinkNoise.ar(0.5), 85, 0.12) * 0.35);

	sig = sig * pressure * env * amp;
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.75);
	sig = Pan2.ar(sig, 0);

	SendReply.kr(Impulse.kr(30), '/audio/bass',
		Amplitude.kr(sig.sum, 0.08, 0.3));

	Out.ar(0, sig);
}).add;


// === Block 2: 主体层 ===
// 职责: 6对拍频干涉网络 — 每对SinOsc频率接近，产生慢速拍频律动
//       表面嵌入: 4-9kHz 皮肤感BPF扫描
// 频率区: 200-1600Hz (中频核心) + 4000-9000Hz (高频皮肤)
// 时间尺度: 拍频偏移 0.06-0.15Hz | 皮肤扫描 4-7Hz
// 音频: ~density -> 拍频偏移量(感应密度) | ~motion -> 皮肤扫描速率

SynthDef(\pull_interference, {
	arg amp=0.25;
	var sig, env, beatNet;
	var surface, scanRate, scanFreq;
	var spatL, spatR;
	var baseFreqs, beatDepth;

	env = EnvGen.kr(Env.asr(9, 1, 11), \gate.kr(1), doneAction: 2);

	beatDepth = (~density ? 0.5) * 2.2 + LFNoise1.kr(0.08).range(0.1, 0.5);

	baseFreqs = [282, 358, 446, 582, 718, 924];

	beatNet = Mix.fill(6, { |i|
		var f, offset, osc1, osc2, beatRate, beatPair;
		f = baseFreqs.at(i);
		beatRate = LFNoise1.kr(0.06 + (i * 0.015)).range(0.18, beatDepth);
		offset = beatRate;
		osc1 = SinOsc.ar(f, 0, 0.15);
		osc2 = SinOsc.ar(f + offset, 0, 0.15);
		beatPair = (osc1 + osc2) * LFNoise2.kr(0.09 + (i * 0.02)).range(0.5, 1.0);
		beatPair;
	});

	sig = BPF.ar(beatNet, 580, 1.2) * 0.7 + (beatNet * 0.3);
	sig = HPF.ar(sig, 180);
	sig = LPF.ar(sig, 1650);

	// 表面嵌入：皮肤感扫描
	scanRate = LFNoise0.kr((~motion ? 0.5) * 3.5 + 4);
	scanFreq = LFNoise0.kr(scanRate.abs + 0.5).exprange(4000, 9000);
	surface = BPF.ar(
		WhiteNoise.ar(0.5),
		scanFreq,
		0.016, 1.8
	) * 0.032 * LFNoise2.kr(4).range(0.0, 1.0);

	sig = sig + surface;

	// 非对称CombL：两极分处两侧
	spatL = CombL.ar(sig, 0.15, 0.068, LFNoise1.kr(0.035).range(1.2, 3.0), 0.22);
	spatR = CombL.ar(sig, 0.15, 0.112, LFNoise1.kr(0.028).range(1.0, 2.5), 0.18);
	sig = [sig + (spatL * 0.32), sig + (spatR * 0.28)];

	sig = sig * env * amp;
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.82);

	SendReply.kr(Impulse.kr(30), '/audio/mid',
		Amplitude.kr(BPF.ar(sig.sum, 500, 0.8), 0.03, 0.12));

	Out.ar(0, sig);
}).add;


// === Block 3: 中间结构层 ===
// 职责: 奇次谐波standing wave — 基频+1x/3x/5x/7x，各独立慢调制，场线感
// 频率区: 180-2000Hz (桥接背景与主体上沿，但性质完全不同)
// 时间尺度: 0.1-0.4 Hz (可感知的谐波呼吸)
// 音频: ~brightness -> 高次谐波(5x,7x)增益

SynthDef(\field_hum, {
	arg freq=220, amp=0.18;
	var sig, env, harmonics;
	var hBright, spread;

	env = EnvGen.kr(Env.asr(7, 1, 9), \gate.kr(1), doneAction: 2);

	hBright = (~brightness ? 0.5) * 0.7 + 0.2;

	harmonics = [1.0, 3.0, 5.0, 7.0].collect({ |n, i|
		var f, weight, osc;
		f = (freq * n).clip(150, 2200);
		weight = LFNoise1.kr(0.12 + (i * 0.07)).range(0.2, 1.0);
		osc = SinOsc.ar(f, 0, [0.38, 0.22, 0.14 * hBright, 0.08 * hBright].at(i));
		osc * weight;
	});

	sig = Mix.ar(harmonics);

	sig = AllpassC.ar(sig, 0.3,
		LFNoise2.kr(0.10).range(0.04, 0.22), 2.0) * 0.28
	+ (sig * 0.72);

	sig = HPF.ar(sig, 160);
	sig = LPF.ar(sig, 2200);
	sig = sig * env * amp;
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.74);

	spread = LFNoise2.kr(0.15).range(-0.48, 0.48);
	sig = Pan2.ar(sig, spread);

	SendReply.kr(Impulse.kr(30), '/audio/onset',
		Amplitude.kr(sig.sum, 0.005, 0.08));

	Out.ar(0, sig);
}).add;


// === Block 5: 空间设计 ===
// 主体: 非对称CombL左(0.068s)/右(0.112s) — 两极分处两侧的物理距离感
// 中层: AllpassC轻扩散(0.04-0.22s) — 场线在空间中漫射
// 背景: 中置无空间化 — 全域静压，无方向

// === Block 6: 时间组织 ===
// 段落 rrand(28,44)秒，先背景->主体->谐波，后半段拍频偏移不可逆推大

fork {
	var humFreqs = [180, 198, 216, 234, 252, 270];

	inf.do { |i|
		var hFreq, dur, halfDur;
		hFreq   = humFreqs.choose;
		dur     = rrand(28, 44);
		halfDur = dur * 0.5;

		if (~membrane.notNil,     { ~membrane.set(\gate, 0) });
		if (~interference.notNil, { ~interference.set(\gate, 0) });
		if (~hum.notNil,          { ~hum.set(\gate, 0) });

		rrand(3.5, 7.0).wait;

		~membrane = Synth(\static_membrane, [
			\amp, rrand(0.18, 0.25)
		]);

		rrand(4.5, 9.0).wait;

		~interference = Synth(\pull_interference, [
			\amp, rrand(0.20, 0.28)
		]);

		rrand(3.0, 6.0).wait;

		~hum = Synth(\field_hum, [
			\freq, hFreq,
			\amp, rrand(0.14, 0.20)
		]);

		halfDur.wait;

		// 后半段：拍频张力积累（感应增强），谐波亮度上推
		if (~interference.notNil, { ~interference.set(\amp, rrand(0.24, 0.32)) });
		if (~hum.notNil,          { ~hum.set(\amp, rrand(0.18, 0.24)) });

		(halfDur * 0.86).wait;
	};
};
