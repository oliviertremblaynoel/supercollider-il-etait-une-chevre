(
~window = Window.new("Server Levels",Rect(1000,1000,600,500));
~composite = CompositeView.new(~window,Rect(300,250,400,250));
~plotte=s.plotTreeView(parent:~window);
~scope=Stethoscope.new(s, view:~composite);
~meter=ServerMeterView.new(s, ~window, 300@0, 8, 10);
~window.onClose={	~scope.free;~meter.free;~plotte.free;};
~window.front;
)
/*
Title :
A)Cresc 60 sec
B)Chevres séquence 60 sec
- Basse (nouveau son)
- Perc
C) Fold rythmic pattern 3 min
Add
-FX processing*/
(
//1. Server config
s = Server.local;
~metro = TempoClock.new(200/60).permanent_(true);
s.options.numOutputBusChannels_(8);
s.options.numInputBusChannels_(10);
s.options.sampleRate_(44100);
s.options.memSize_(2.pow(20));
s.newBusAllocators;
ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;
//2. initialize global variables
~out = 0;
~path = PathName(thisProcess.nowExecutingPath).parentPath++"buffers/";
~freq=416;
~tempo=125;
~dur=60/~tempo;
~three=[
	1,
	3/2,
	4/3,
	9/8,
	16/9,
	32/27,
	81/64,
	128/81,
	243/128
];
~five=[
	1,
	3/2,
	4/3,
	5/4,
	8/5,
	9/8,
	16/9,
	25/16,
	32/25,
	5/3,
	6/5,
];
~seven=[
	1,
	3/2,
	4/3,
	5/4,
	8/5,
	7/4,
	8/7,
	9/8,
	16/9,
	25/16,
	32/25,
	5/3,
	6/5,
	7/6,
	9/7,
	7/5,
	10/7,
];
~eleven=[
	1,
	3/2,
	4/3,
	5/4,
	8/5,
	7/4,
	8/7,
	11/8,
	16/11,
	9/8,
	16/9,
	25/16,
	32/25,
	5/3,
	6/5,
	7/6,
	9/7,
	7/5,
	10/7,
	49/32,
	64/49,
	11/9,
	12/11
];
~thirteen=[
	1,
	3/2,
	4/3,
	5/4,
	8/5,
	7/4,
	8/7,
	11/8,
	16/11,
	13/8,
	16/13,
	9/8,
	16/9,
	25/16,
	32/25,
	5/3,
	6/5,
	7/6,
	9/7,
	7/5,
	10/7,
	49/32,
	64/49,
	11/9,
	12/11
];
~allScales=~three++~five++~seven++~eleven++~thirteen;
~allScalesArray=[~three,~five,~seven,~eleven,~thirteen];

//3. define piece-specific functions
~makeBuffers = {
	~wt_sig = 10.collect({
		arg i;
		var numSegs = i.linexp(0,9,4,40).round;
		Env(
			[0]++({1.0.rand}.dup(numSegs-1)*[1,-1]).scramble++[0],
			{exprand(1,i.linexp(0,9,1,50))}.dup(numSegs),
			{[\sine,0,exprand(1,20)*[1,-1].choose].wchoose([9-i,3,i].normalizeSum)}.dup(numSegs)
		).asSignal(1024);
	});
	~wt_buf=Buffer.allocConsecutive(10,s,2048,1,{
		arg buf, index;
		buf.setnMsg(0,~wt_sig[index].asWavetable);
	});
	//Dictionary for sample files
	b = Dictionary.new;
	PathName(~path).entries.do{
		arg subfolder;
		b.add(
			subfolder.folderName.asSymbol ->
			Array.fill(
				subfolder.entries.size,
				{
					arg i;
					Buffer.read(s, subfolder.entries[i].fullPath);
				}
			)
		);
	};
};
~makeBusses = {
	~bus = Dictionary.new;
	~bus.add(\reverb -> Bus.audio(s,2));
};
~cleanup = {
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};


~makeNodes = {
	s.bind({
		~mainGrp = Group.new;
		~reverbGrp = Group.after(~mainGrp);
		~reverbSynth = Synth.new(
			\reverb,
			[
				\amp,1,
				\predelay,0.1,
				\revtime,1.8,
				\lpf,4500,
				\mix,0.35,
				\in,~bus[\reverb],
				\out,~out,
			],
			~reverbGrp
		);
	});
};
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////
//////////////////////////////////////////////

~makeEvents = {
	e = Dictionary.new;
	e.add(\event1 -> {
		var ctdown=60;
		Routine({
			Synth(
				\osc,
				[
					\atk, ctdown,
					\sus, 0,
					\rel, 0.1,
					\buf, ~wt_buf[0],
					\detune, rrand(0.01,0.1),
					\amp, 0.3,
					\tremoloDepth, 0.4,
					\tremoloFreqRand,0.3,
					\tremoloFreq,5,
					\freq, ~freq*2.pow(-4),
					\out, ~bus[\reverb],
				], ~mainGrp
			);
			4.wait;
			25.do{
				arg i;
				Synth(
					\osc,
					[
						\dur,1,
						\atk, ctdown-4-(2*i),
						\sus, 0,
						\rel, 0.1,
						\buf, ~wt_buf[0..9].choose,
						\detune, rrand(0.01,0.1),
						\amp, 0.1,
						\tremoloDepth, exprand(0.2,0.9),
						\tremoloFreqRand,exprand(0.2,0.9),
						\tremoloFreq,i*2,
						\pan, rrand(-1.0,1.0),
						\freq, ~freq*~thirteen[i]*2.pow((-2..2).choose),
						\out, ~bus[\reverb],
					], ~mainGrp
				);
				2.wait;
			};
			6.wait;
			e[\event2].value;
		}).play(AppClock);
	});

	e.add(\event2 -> {
		~meloChevre = Pbind(
			\instrument, \bpfbuf,
			\dur, Pseq(~allScales/6,inf),
			\atk, 0.01,
			\sus,	0.3,
			\rel, Pexprand(0.05,0.1),
			\buf, b[\chevres][0..2].choose.bufnum,
			\rate, Pwhite(-12.0,-10.0).midiratio,
			\spos, Pwhite(0, b[\chevres][0..2].choose.numFrames/2),
			\amp, Pdefn(\meloAmp, Pexprand(2,2.7)),
			\pan, Pwhite(-0.5,0.1),
			\freq, Pseq((~allScales)*~freq*2.pow(2), inf),
			\rq, 0.01,
			\bpfmix, 0.97,
			\group, ~mainGrp,
			\out, ~out,
		).play;

		~chordChevre = Pbind(
			\instrument, \bpfbuf,
			\dur, Pseq(Array.fill(~allScalesArray.size,{arg i;~allScalesArray[i].sum;})/6,inf),
			\atk, Pwhite(0.3,0.8),
			\sus, Pkey(\dur),
			\rel, Pwhite(1,5),
			\buf, b[\chevres][0..2].choose.bufnum,
			\rate, Pwhite(-3.0,3).midiratio,
			\spos, Pwhite(0, b[\chevres][0..2].choose.numFrames/2),
			\amp, Pdefn(\chordAmp,Pexprand(1.5,2)),
			\pan, Pwhite(-1.0,1.0),
			\freq, Pseq(Array.fill(~allScalesArray.size, {arg i; {~allScalesArray[i].choose*2.pow((-1..1).choose)}!4*~freq;}),inf),
			\rq, 0.01,
			\bpfmix, 0.98,
			\group, ~mainGrp,
			\out, ~bus[\reverb],
		).play;
	});

	e.add(\event3 -> {
		Routine({
			Pdefn(\meloAmp,Pseq((2.5,2.48..0),1));
			Pdefn(\chordAmp,Pexprand(1.8,2.2));
			20.wait;
			~meloChevre.stop(\amp);
			~traffic = 10.collect{arg i,amp=0.02;
				{Resonz.ar({var freq, numcps;
					freq= {~thirteen.choose}*~freq*0.5;
					numcps= rrand(2,20);
					Pan2.ar(Gendy2.ar(6.rand,6.rand,1.0.rand,1.0.rand,freq ,freq,
						1.0.rand, 1.0.rand, numcps, SinOsc.kr(exprand(0.02,0.2), 0,
							numcps/2, numcps/2), 0.5/(10.sqrt)), 1.0.rand2)
},LFNoise1.kr(0.5).range(400,1000), LFNoise1.kr(0.33).range(0.5,1.0), amp)}.play(fadeTime:10);
}

			// 10.wait;
			/*			~oscPerc= Pbind(
			\instrument, \osc,
			\dur, Pseq([1,1,3,1,2,1,1,1,2]*({rrand(0.85,1.15)}!9).normalizeSum*10*~dur/4,32),
			\freq, Pstutter(4,Prand(~thirteen*~freq*0.5,inf)),
			\detune, 100,
			\buf,  Pstutter(inf,Prand(~wt_buf[5..9])),
			\atk, 0.0,
			\sus, 0,
			\rel, Pstutter(2,Pexprand(0.01,0.06)),
			\c0, Prand((-5..-8),inf),
			\c1, Prand((5..8),inf),
			\amp, Pseq([6,2,1,2,1,2,1,4],inf)/20,
			\pan, Pseq([-1,-0.6],inf),
			\group, ~mainGrp,
			\out, ~out,
			).play;*/
		}).play(AppClock);
	});

	e.add(\event4 -> {
		~clochesPerc= 2.do{
			var k;
			k=~seven.choose;
			Pbind(
				\instrument, \bpfbuf,
				\dur, Pseq(k!k*(~dur/2)*(({rrand(0.85,1.15)}!k).normalizeSum*k),inf),
				\atk,0,
				\sus, 0,
				\rel, 0.8,
				\buf, Prand(b[\cloches],inf),
				\amp, Pseq([0.8,1.2,1,1.1]*((0,0.1..2.5)++(2.5,2.4..0)),1),
				\pan, Pwhite(0.2,1),
				// \rate, ~three,
				\freq, Prand(~three*~freq*4,inf),
				\rq, 0.04,
				\bpfmix, 0.92,
				\group, ~mainGrp,
				\out, ~bus[\reverb],
			).play;
		}
	});

	e.add(\event5 -> {
		~oscBass= Pbind(
			\instrument, \osc,
			\dur, Pwrand([
				Pseq([1/2,3],2),
				Pseq([1/2,1],3),
				Pseq([1/2,6],2),
				Pseq([4,6],1)
			]*~dur,[6,4,2,1].normalizeSum, 50),
			\atk, 0.04,
			\sus,0,
			\rel, Pwrand([
				Pseq([0.1, 0.07]),
				Pseq([0.1, 0.05]),
				Pseq([1, 0.1])
			]*2,
			[10,5,1].normalizeSum,inf),
			\buf,  Prand(~wt_buf[0..2],inf),
			\amp, Pdefn(\bassAmp,Pseq([0.5,0.4,0.3],inf)),
			\pan, Pwhite(-0.5,-0.3),
			\detune, rrand(0.1,0.2),
			\tremoloDepth, 0.5,
			\tremoloFreq,Pwhite(8,12),
			\freq, Pwrand([
				Pseq([~three[0]],17),
				Pseq([~three[1]],13),
				Pseq([~three[2]],11),
				Pseq([~three[3]],8),
				Pseq([~three[4]],4)
			],[2,1,1,1,1].normalizeSum,inf)*~freq*2.pow(-4),
			\group, ~mainGrp,
			\out, ~bus[\reverb],
		).play;
	});

	e.add(\event6 -> {
		~meloBol = Pbind(
			\instrument, \bpfbuf,
			\dur, Prand(~three,inf)*3,
			\atk, 0.05,
			\sus, 1,
			\rel, 10,
			\buf, b[\bols][0],
			\spos, Pwhite(1/10,1/8)*b[\bols][0].numFrames,
			\rate, Prand(~thirteen, inf)*2.pow(-3),
			\amp, Pexprand(0.5,0.8),
			\pan, Pwhite(-0.30,0.3),
			\bpfmix, 0,
			\group, ~mainGrp,
			\out, ~out,
		).play;
	});

	e.add(\event7 -> {
		~meloNoise = Pbind(
			\instrument, \sub,
			\dur, Pwrand([
				Pseq([1/4,1/4],4),
				Pseq([1/8,1],2),
				Pseq([1/8,1/8,1/8,2]),
				Pseq([1/6,1/6,1/4,1/9,1],2)
			]*~dur,[20,8,6,4].normalizeSum, 32)*Pwhite(0.9,1.1),
			\atk, 0.01,
			\sus, 0.2,
			\rel, 0.1,
			\amp, Pexprand(0.2,0.25),
			\pan, Pwhite(-0.30,0.3),
			\bpfmix, 1,
			\rq,0.01,
			\freq, Prand(~thirteen*~freq*4,200),
			\group, ~mainGrp,
			\out, ~bus[\reverb],
		).play;
	});

	e.add(\event8 -> {
		~meloShaker = Pbind(
			\instrument, \bpfbuf,
			\dur, Pseq(~thirteen,3)/2,
			\atk, Pwhite(0.05,0.2),
			\sus, Pkey(\dur),
			\rel, 0.3,
			\buf, Prand(b[\shaker],inf),
			\rate, Prand(~thirteen, inf)/1.5,
			\amp, Pexprand(0.5,0.6)*3,
			\pan, Pwhite(-0.30,0.3),
			\bpfmix, 1,
			\rq,0.01,
			\freq, Prand(~thirteen*~freq*4,inf),
			\group, ~mainGrp,
			\out, ~out,
		).play;
	});

	e.add(\event9 -> {
		~meloWhip = 2.do{
			Pbind(
			\instrument, \bpfbuf,
			\dur, Pseq([
				Pseq([1,1,1,2],4),
				Pseq([1,1,2,1,2],1),
				Pseq([1/4,1/4,1,1/2,1],1),
			],6)*~dur/2,
			\atk, 0.05,
			\sus, 0,
			\rel, 1,
			\buf, Prand(b[\whip],inf),
			// \rate, Prand(~thirteen, inf)/2,
			\amp, Pexprand(0.5,0.8),
			\pan, Pwhite(-0.30,0.3),
			\bpfmix, 1,
			\rq,0.01,
			\freq, Prand(~thirteen*~freq*2,200),
			\group, ~mainGrp,
			\out, ~bus[\reverb],
		).play;
			};
//	});

//	e.add(\event10 -> {
		~meloCabasa = Pbind(
			\instrument, \bpfbuf,
			\dur, Pseq([
				Pseq([1,1,1,2],4),
				Pseq([1,1,2,1,2],1),
				Pseq([1/4,1/4,1,1/2,1],1),
			],6)*~dur/2,
			\atk, 0.05,
			\sus, 0,
			\rel, 0.1,
			\buf, Prand(b[\cabasa],inf),
			\rate, Prand(~thirteen, inf)/2,
			\amp, Pexprand(1.0,1.2)*2,
			\pan, Pwhite(-0.30,0.3),
			\bpfmix, 1,
			\rq,0.01,
			\freq, Prand(~thirteen*~freq*4,200),
			\group, ~mainGrp,
			\out, ~bus[\reverb],
		).play;
	});

	e.add(\oneshot2 -> {
		~chordChevre.stop;
		~meloChevre.stop;
	});

	e.add(\oneshot3 -> {
(
Routine({
	~traffic.do{arg i;
		100.do{arg j;
			i.set(\amp,0.05/2.pow(j));
			// i.set(\amp,0);
			wait(0.01);};
	i.free;1.wait;};
	"asd".postln;
}).play;
)
	});

	e.add(\oneshot4 -> {
			Pdefn(\clochesAmp,Pseq((2.5,2.3..0),1));
	});

	e.add(\oneshot5 -> {
		Pdefn(\bassAmp,Pseq((0.4,0.35..0),1));
	});

	e.add(\oneshot6 -> {
		~meloBol.stop;
	});

	e.add(\oneshot7 -> {
		~meloNoise.stop;
	});
	e.add(\oneshot8 -> {
		~meloShaker.stop;
	});
	e.add(\oneshot9 -> {
		~meloWhip.stop;
	});

	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event1].value;"event1-Build".postln;}},'/event1');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event2].value;"event2-Chevres".postln;}},'/event2');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event3].value;"event3-Traffic".postln;}},'/event3');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event4].value;"event4-Cloches".postln;}},'/event4');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event5].value;"event5-Bass".postln;}},'/event5');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event6].value;"event6-MeloBol".postln;}},'/event6');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event7].value;"event7-Noise".postln;}},'/event7');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event8].value;"event8-MeloShaker".postln;}},'/event8');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event9].value;"event9-Whip".postln;}},'/event9');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\event10].value;"event10-Cabasa".postln;}},'/event10');
	// OSCFunc.new({	arg msg;if(msg[1]==1){e[\event11].value;"event11-stop All".postln;}},'/event11');

	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot1].value;"oneshot1".postln;}},'/oneshot1');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot2].value;"oneshot2-StopChord Chevres".postln;}},'/oneshot2');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot3].value;"oneshot3-Stop Traffic".postln;}},'/oneshot3');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot4].value;"oneshot4-Stop Cloches".postln;}},'/oneshot4');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot5].value;"oneshot5-Stop Bass".postln;}},'/oneshot5');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot6].value;"oneshot6-Stop Bols".postln;}},'/oneshot6');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot7].value;"oneshot7-Stop Noise".postln;}},'/oneshot7');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot8].value;"oneshot8-Stop Shaker".postln;}},'/oneshot8');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot9].value;"oneshot9-Stop Whip".postln;}},'/oneshot9');
	OSCFunc.new({	arg msg;if(msg[1]==1){e[\oneshot10].value;"oneshot10-Stop Cabasa".postln;}},'/oneshot10');

};
//4. register functions with ServerBoot/Quit/Tree
ServerBoot.add(~makeBuffers);
ServerBoot.add(~makeBusses);
ServerQuit.add(~cleanup);
//5. boot server
s.waitForBoot({
	s.sync;
	//6a. Here place all synth Defs
	SynthDef(\osc,{
		arg buf=0, freq=220, detune=0.2,amp=0.2,tremoloDepth=0, tremoloFreqRand=0, tremoloFreq=3,pan=0, out=0, atk=0.01, sus=1, rel=0.01, c0=1, c1=(-1);
		var env, sig, detuneCtrl, tri;
		env = EnvGen.ar(Env([0,1,1,0],[atk,sus,rel],[c0,0,c1]),doneAction:2);
		detuneCtrl = LFNoise1.kr(0.1!8).bipolar(detune).midiratio;
		tri=LFTri.ar(tremoloFreq*LFNoise0.ar(20).range((1-tremoloFreqRand),0,6,0.5*9-4));
		sig = env * Osc.ar(~wt_buf,freq*detuneCtrl,{Rand(0,2pi)}!8);
		sig = Splay.ar(sig);
		sig = sig*Clip.ar(tri,1-tremoloDepth,1);
		sig = LeakDC.ar(sig);
		sig = Balance2.ar(sig[0], sig[1], pan, amp);
		Out.ar(out,sig);
	}).add;

	SynthDef(\pulse,{
		arg
		amp=0.2,
		out=0,
		topFreq=440;
		var sig;
		sig = Pulse.ar(topFreq);
		sig = sig*amp;
		Out.ar(out,sig);
	}).add;

	SynthDef(\bpfbuf, {
		arg atk=0, sus=0, rel=3, c1=1, c2=(-1),
		buf=0, rate=1, spos=0, freq=440, rq=1, bpfmix=0,
		pan=0, amp=1, out=0;
		var sig, env;
		env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]),doneAction:2);
		sig = PlayBuf.ar(1, buf, rate*BufRateScale.ir(buf),startPos:spos);
		sig = XFade2.ar(sig, BPF.ar(sig, freq, rq, 1/rq.sqrt), bpfmix*2-1);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\sub, {
		arg atk=0, sus=0, rel=3, c1=1, c2=(-1),freq=440, rq=1, bpfmix=0,
		pan=0, amp=1, out=0;
		var sig, env;
		env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]),doneAction:2);
		sig = LFNoise2.ar(10000);
		sig = XFade2.ar(sig, BPF.ar(sig, freq, rq, 1/rq.sqrt), bpfmix*2-1);
		sig = sig * env;
		sig = Pan2.ar(sig, pan, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\reverb, {
		arg in, predelay=0.1, revtime=1.2,
		lpf=4500, mix=0.15, amp=1, out=0;
		var dry, wet, temp, sig;
		dry=In.ar(in,2);
		temp=In.ar(in,2);
		wet=0;
		temp=DelayN.ar(temp, 0.2,predelay);
		16.do{
			temp=AllpassN.ar(temp, 0.05, {Rand(0.001,0.05)}!2,revtime);
			temp=LPF.ar(temp, lpf);
			wet=wet+temp;
		};
		sig=XFade2.ar(dry,wet,mix*2-1,amp);
		Out.ar(out,sig);
	}).add;

	s.sync;
	//6b. register remaining functions
	ServerTree.add(~makeNodes);
	ServerTree.add(~makeEvents);
	s.freeAll;
	s.sync;
	"done".postln;
});
)
