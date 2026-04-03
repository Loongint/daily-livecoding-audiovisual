// === 滞准期 / Conditional Hold State ===
// 2026-04-04 | pink;money
// 坎卦: 重险叠险 | 残月下沉 | 深折叠压力渗透
//
// 结构:
//   背景 \abyss_pressure   — 16-55Hz 极低频纯音叠加水压场，全域无方���
//   主体 \deep_fold        — 220-1800Hz 自嵌套FM调制，慢漂临界张力，高频液面扫描嵌入
//   中层 \seep_resonance   — 1200-3800Hz Ringz气泡共振，极低密度随机涌现
//   表面  嵌入主体内部       — 5-12kHz 液体高频折射扫描，轻薄
//   空间  深水腔容器          — 主体FreeVerb(大房间)，中层AllpassC随机扩散，背景无空间化
//
// 时间: 背景 0.008-0.015Hz | 主体FM 0.04-0.12Hz | 气泡 0.3-1.5Hz | 扫描 3-8Hz
// 控制: ~energy->背景压力 ~brightness->FM折叠深度 ~complexity->气泡密度 ~motion->扫描速率

// === Block 1: 背景层 ===
// 职责: 极低频纯音水压场，4条独立慢漂正弦建立"水下气压容器"
// 频率区: 16-55Hz (次次低频，纯音，无噪声)
// 时间尺度: 0.008-0.015 Hz (深渊静止)
// 音频: ~energy -> 压力振幅

SynthDef(\abyss_pressure, {
	arg amp=0.20;
	var sig, env, pressure;
	var baseFreqs, sines;

	env = EnvGen.kr(Env.asr(18, 1, 14), \gate.kr(1), doneAction: 2);

	pressure = (~energy ? 0.5) * 0.5 + 0.35 + LFNoise2.kr(0.012).range(-0.12, 0.12);

	baseFreqs = [
		LFNoise1.kr(0.009).exprange(16, 22),
		LFNoise1.kr(0.011).exprange(24, 32),
		LFNoise1.kr(0.013).exprange(33, 44),
		LFNoise1.kr(0.015).exprange(43, 55)
	];

	sines = baseFreqs.collect({ |f, i|
		var weight = [0.32, 0.28, 0.22, 0.18].at(i);
		SinOsc.ar(f, LFNoise1.kr(0.007 + (i * 0.002)).range(0, 6.28)) * weight;
	});

	sig = Mix.ar(sines) * pressure * env * amp;
	sig = HPF.ar(sig, 14);
	sig = LPF.ar(sig, 58);
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.78);
	sig = Pan2.ar(sig, 0);

	SendReply.kr(Impulse.kr(30), '/audio/bass',
		Amplitude.kr(sig.sum, 0.1, 0.4));

	Out.ar(0, sig);
}).add;


// === Block 2: 主体层 ===
// 职责: 自嵌套FM调制系统 — 载波被调制，调制指数被极慢LFO控制，临界悬停
//       表面嵌入: 5-12kHz 液体高频折射扫描（BPF白噪声）
// 频率区: 220-1800Hz (中频核心) + 5000-12000Hz (高频表面)
// 时间尺度: FM 0.04-0.12 Hz (慢漂张力) | 表面 3-8 Hz
// 音频: ~brightness -> FM折叠深度(调制指数) | ~motion -> 高频扫描速率

SynthDef(\deep_fold, {
	arg freq=280, amp=0.26;
	var sig, env, modIndex, modFreq;
	var fold1, fold2, fmSig;
	var surface, scanRate, scanFreq;
	var wet;

	env = EnvGen.kr(Env.asr(10, 1, 12), \gate.kr(1), doneAction: 2);

	// 调制指数：极慢漂移，~brightness 扩展上限（折叠加深）
	modIndex = LFNoise2.kr(0.042).range(0.3, 1.0)
	         + LFNoise1.kr(0.09).range(-0.15, 0.15)
	         + ((~brightness ? 0.5) * 1.8);
	modIndex = modIndex.clip(0.2, 3.5);

	// 调制频率自身也在慢漂（嵌套）
	modFreq = freq * (LFNoise1.kr(0.06).range(0.7, 2.1));

	// 第一层FM
	fold1 = SinOsc.ar(
		freq + (SinOsc.ar(modFreq) * modIndex * freq * 0.8),
		0, 0.5
	);
	// 第二层：用fold1的振幅调制载波相位，产生深折叠感
	fold2 = SinOsc.ar(
		freq * LFNoise1.kr(0.08).range(0.88, 1.12),
		fold1 * modIndex * 1.4,
		0.35
	);

	fmSig = (fold1 * 0.55 + fold2 * 0.45);
	fmSig = BPF.ar(fmSig, freq * LFNoise2.kr(0.07).range(1.2, 4.5), 0.35) * 0.6 + (fmSig * 0.4);

	// 表面嵌入：液体高频折射扫描
	scanRate = LFNoise0.kr((~motion ? 0.5) * 4 + 3);
	scanFreq = LFNoise0.kr(scanRate.abs + 1).exprange(5000, 12000);
	surface = BPF.ar(
		WhiteNoise.ar(0.6),
		scanFreq,
		0.018, 2.0
	) * 0.042 * LFNoise2.kr(5).range(0.0, 1.0);

	sig = fmSig + surface;

	// FreeVerb 深水腔
	wet = FreeVerb.ar(sig, 0.38, 0.91, 0.18);
	sig = (sig * 0.62) + wet;

	sig = sig * env * amp;
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.80);

	// 空间化：主体居中，轻微宽化
	sig = [
		sig * LFNoise1.kr(0.05).range(0.88, 1.0),
		sig * LFNoise1.kr(0.04).range(0.88, 1.0)
	];

	SendReply.kr(Impulse.kr(30), '/audio/mid',
		Amplitude.kr(BPF.ar(sig.sum, 600, 1.0), 0.04, 0.18));

	Out.ar(0, sig);
}).add;


// === Block 3: 中间结构层 ===
// 职责: Ringz气泡共振 — 极低密度随机涌现，深水气泡浮现感
// 频率区: 1200-3800Hz (主体谐波倍频区，桥接)
// 时间尺度: 0.3-1.5 Hz (稀疏事件)
// 音频: ~complexity -> 气泡密度

SynthDef(\seep_resonance, {
	arg amp=0.16;
	var sig, env, density, trig;
	var bubbles, spread;

	env = EnvGen.kr(Env.asr(6, 1, 8), \gate.kr(1), doneAction: 2);

	density = (~complexity ? 0.5) * 1.2 + LFNoise0.kr(0.35).range(0.3, 1.5);
	trig = Dust.kr(density);

	bubbles = Mix.fill(5, { |i|
		var rFreq, decTime, bubble;
		rFreq = LFNoise0.kr(0.3 + (i * 0.07)).exprange(1200, 3800);
		decTime = LFNoise1.kr(0.15 + (i * 0.04)).range(0.1, 0.75);

		bubble = Ringz.ar(
			Decay.ar(T2A.ar(trig), 0.0005, 0.7),
			rFreq,
			decTime
		) * [0.22, 0.20, 0.18, 0.15, 0.12].at(i);

		// 独立随机延迟让每个气泡在空间中散布
		AllpassC.ar(bubble, 0.35,
			LFNoise2.kr(0.08 + (i * 0.03)).range(0.03, 0.28), 2.0) * 0.3
		+ (bubble * 0.7);
	});

	sig = HPF.ar(bubbles, 1000);
	sig = LPF.ar(sig, 4200);
	sig = sig * env * amp;
	sig = LeakDC.ar(sig);
	sig = Limiter.ar(sig, 0.72);

	spread = LFNoise2.kr(0.22).range(-0.55, 0.55);
	sig = Pan2.ar(sig, spread);

	SendReply.kr(Impulse.kr(30), '/audio/onset',
		Amplitude.kr(sig.sum, 0.003, 0.06));

	Out.ar(0, sig);
}).add;


// === Block 5: 空间设计 ===
// 主体: FreeVerb(roomSize 0.91, 大深水腔) — 主体在深渊内漂浮
// 中层: AllpassC随机扩散(0.03-0.28s, per bubble) — 气泡在空间中无方向漂散
// 背景: 无空间化 — 全域水压，没有方向
// 深度: 背景(全域干) < 中层(散射) < 主体(大腔体)

// === Block 6: 时间组织 ===
// 段落 rrand(25,45)秒，先背景->主体->气泡，后半段FM折叠不可逆推进

fork {
	var pressureFreqs = [18, 22, 27, 31, 38];
	var foldFreqs     = [196, 220, 247, 261, 294, 330];
	var seepRoots     = [1200, 1500, 1800, 2200, 2800];

	inf.do { |i|
		var pFreq, fFreq, sFreq, dur, halfDur;
		pFreq = pressureFreqs.choose;
		fFreq = foldFreqs.choose;
		sFreq = seepRoots.choose;
		dur     = rrand(25, 45);
		halfDur = dur * 0.5;

		if (~pressure.notNil, { ~pressure.set(\gate, 0) });
		if (~fold.notNil,     { ~fold.set(\gate, 0) });
		if (~seep.notNil,     { ~seep.set(\gate, 0) });

		rrand(3.0, 6.0).wait;

		~pressure = Synth(\abyss_pressure, [
			\amp, rrand(0.17, 0.24)
		]);

		rrand(4.0, 8.0).wait;

		~fold = Synth(\deep_fold, [
			\freq, fFreq,
			\amp, rrand(0.22, 0.28)
		]);

		rrand(3.0, 6.0).wait;

		~seep = Synth(\seep_resonance, [
			\amp, rrand(0.12, 0.18)
		]);

		halfDur.wait;

		// 后半段：FM折叠张力积累（不可逆），气泡密度推进
		if (~fold.notNil,  { ~fold.set(\amp,  rrand(0.26, 0.34)) });
		if (~seep.notNil,  { ~seep.set(\amp,  rrand(0.18, 0.24)) });

		(halfDur * 0.88).wait;
	};
};
