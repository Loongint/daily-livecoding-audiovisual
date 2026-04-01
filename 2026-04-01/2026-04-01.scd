SynthDef(\thermal_wall, {
	arg freq=55, amp=0.3, pan=0;
	var sig, mod, env, pressure, brightness;
	brightness = \brightness.kr(0.5);
	env = EnvGen.kr(Env.asr(6, 1, 8), \gate.kr(1), doneAction: 2);
	mod = LFNoise1.kr(0.07).range(0.2, 1.8);
	pressure = LFNoise2.kr(0.03).range(0.4, 1.0);
	sig = BrownNoise.ar(0.5) + PinkNoise.ar(0.3);
	sig = RLPF.ar(sig, freq * mod * (1 + (brightness * 2)), 0.08 + (pressure * 0.12));
	sig = sig + RLPF.ar(
		LFPulse.ar(freq * 0.5, 0, LFNoise2.kr(0.1).range(0.01, 0.5)) * 0.15,
		freq * 1.5 * pressure,
		0.2
	);
	sig = sig + (SinOsc.ar(freq * [1, 1.001, 2.003, 3.01]) * LFNoise2.kr(0.05 ! 4).range(0, 0.06)).sum;
	sig = (sig * (1 + (2 * pressure))).tanh;
	sig = LPF.ar(sig, 3000 + (brightness * 4000));
	sig = HPF.ar(sig, 30);
	sig = Pan2.ar(sig * env * amp, pan + LFNoise2.kr(0.08).range(-0.3, 0.3));
	sig = LeakDC.ar(sig);
	SendReply.kr(Impulse.kr(30), '/audio/bass', Amplitude.kr(Mix.ar(sig)));
	Out.ar(0, sig);
}).add;

SynthDef(\grid_pulse, {
	arg freq=110, amp=0.12, density=4;
	var sig, trig, env, filt, motion, hue;
	motion = \motion.kr(0.5);
	hue = \hue.kr(0.5);
	env = EnvGen.kr(Env.asr(3, 1, 5), \gate.kr(1), doneAction: 2);
	trig = Dust.kr(density + (motion * 8));
	sig = WhiteNoise.ar(1);
	sig = Ringz.ar(sig * Decay.kr(trig, 0.02), freq * [1, 1.5, 2.01, 3.98], LFNoise2.kr(0.2 ! 4).range(0.005, 0.08));
	sig = Mix.ar(sig) * 0.25;
	sig = sig + (SinOsc.ar(freq * 0.25) * Decay2.kr(trig, 0.001, 0.05) * 0.3);
	filt = BPF.ar(sig, freq * (1 + (hue * 3)), 0.15, 3);
	sig = (sig + filt).clip2(0.8);
	sig = HPF.ar(sig, 60);
	sig = LPF.ar(sig, 6000);
	sig = Pan2.ar(sig * env * amp, LFNoise2.kr(0.3).range(-0.7, 0.7));
	sig = LeakDC.ar(sig);
	SendReply.kr(Impulse.kr(30), '/audio/mid', Amplitude.kr(Mix.ar(sig)));
	Out.ar(0, sig);
}).add;

SynthDef(\overexposure, {
	arg freq=2200, amp=0.08;
	var sig, env, brightness, n1, n2;
	brightness = \brightness.kr(0.5);
	env = EnvGen.kr(Env.asr(10, 1, 10), \gate.kr(1), doneAction: 2);
	n1 = LFNoise0.kr(3).range(800, 5500);
	n2 = LFNoise0.kr(2.3).range(1200, 7000);
	sig = Resonz.ar(ClipNoise.ar(0.3), n1, 0.003, 8);
	sig = sig + Resonz.ar(ClipNoise.ar(0.2), n2, 0.002, 6);
	sig = sig + (Dust2.ar(40 + (brightness * 200)) * 0.04);
	sig = HPF.ar(sig, 400);
	sig = LPF.ar(sig, 9000);
	sig = (sig * (1 + (brightness * 3))).fold2(0.6);
	sig = Pan2.ar(sig * env * amp, SinOsc.kr(0.07).range(-0.5, 0.5));
	sig = LeakDC.ar(sig);
	SendReply.kr(Impulse.kr(30), '/audio/high', Amplitude.kr(Mix.ar(sig)));
	Out.ar(0, sig);
}).add;

fork {
	var thermalFreqs, gridFreqs;
	thermalFreqs = [36, 40, 43, 48, 31, 33];
	gridFreqs = [55, 73.4, 82.4, 98, 110, 65.4];

	1.wait;

	~thermal = nil;
	~grid = nil;
	~over = nil;

	inf.do { |i|
		var tf, gf, dur;

		if(~thermal.notNil, { ~thermal.set(\gate, 0) });
		if(~grid.notNil, { ~grid.set(\gate, 0) });
		if(~over.notNil, { ~over.set(\gate, 0) });

		2.wait;

		tf = thermalFreqs.choose.midicps;
		gf = gridFreqs.choose;
		dur = rrand(18, 35);

		~thermal = Synth(\thermal_wall, [
			\freq, tf,
			\amp, rrand(0.15, 0.35),
			\pan, rrand(-0.4, 0.4)
		]);

		rrand(0.5, 2.0).wait;

		~grid = Synth(\grid_pulse, [
			\freq, gf,
			\amp, rrand(0.06, 0.15),
			\density, rrand(2, 12)
		]);

		rrand(1.0, 3.0).wait;

		~over = Synth(\overexposure, [
			\freq, rrand(1500, 4000),
			\amp, rrand(0.03, 0.1)
		]);

		dur.wait;
	};
};