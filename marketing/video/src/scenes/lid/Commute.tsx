import React from 'react';
import {AbsoluteFill, Easing, interpolate, useCurrentFrame} from 'remotion';
import {GridBackground, Headline} from '../../components/Common';
import {Mug} from '../../components/Glyphs';
import {Laptop, LAPTOP_W} from '../../components/Laptop';
import {C, MONO, SANS, WIDTH} from '../../theme';

// Close the lid, carry the laptop to a meeting, come back to finished work.
const CLOSE = [76, 104];
const WALK = [104, 300];
const TESTS_RUN = [0, 255];
const DONE = 255;
const OPEN = [302, 334];
const TESTS = 1204;

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const ease = Easing.inOut(Easing.cubic);

const CAPTIONS: {from: number; to: number; text: React.ReactNode}[] = [
	{from: 0, to: 74, text: <>Claude Code is mid-refactor.<br /><span style={{color: C.muted}}>You're late for a meeting.</span></>},
	{from: 76, to: 128, text: <>Close the lid.<br /><span style={{color: C.muted}}>Laptop under your arm.</span></>},
	{from: 130, to: 254, text: <>Your agents<br /><span style={{color: C.accent}}>keep working.</span></>},
	{from: 256, to: 302, text: <>Done?<br /><span style={{color: C.muted}}>Now the Mac can sleep.</span></>},
	{from: 304, to: 420, text: <>Back at your desk:<br /><span style={{color: C.ok}}>the work is done.</span></>},
];

export const Commute: React.FC = () => {
	const frame = useCurrentFrame();
	const tests = Math.round(
		interpolate(frame, TESTS_RUN, [0, TESTS], {...clamp, easing: Easing.bezier(0.3, 0.1, 0.5, 1)}),
	);
	const done = frame >= DONE;
	const lid =
		interpolate(frame, CLOSE, [0, 1], {...clamp, easing: ease}) - interpolate(frame, OPEN, [0, 1], {...clamp, easing: ease});

	// Carried along: sway and a walking bob while the lid is shut.
	const walking = interpolate(frame, [WALK[0], WALK[0] + 12, WALK[1] - 12, WALK[1]], [0, 1, 1, 0], clamp);
	const step = frame - WALK[0];
	const swayX = Math.sin(step / 14) * 36 * walking;
	const bobY = -Math.abs(Math.sin(step / 7)) * 16 * walking;
	const tilt = Math.sin(step / 14) * 2.5 * walking;

	const hud = interpolate(frame, [114, 124, 292, 302], [0, 1, 1, 0], clamp);
	const meetingMinutes = Math.round(interpolate(frame, [120, DONE], [1, 38], clamp));

	return (
		<AbsoluteFill>
			<GridBackground glow={0.12} />

			{/* Story captions */}
			{CAPTIONS.map((c, i) => {
				const opacity = interpolate(frame, [c.from, c.from + 8, c.to - 6, c.to], [0, 1, 1, 0], clamp);
				const rise = interpolate(frame, [c.from, c.from + 12], [24, 0], {...clamp, easing: Easing.out(Easing.cubic)});
				return (
					<div key={i} style={{position: 'absolute', top: 120, left: 60, right: 60, opacity, transform: `translateY(${rise}px)`}}>
						<Headline size={68}>{c.text}</Headline>
					</div>
				);
			})}

			{/* Floor shadow */}
			<div
				style={{
					position: 'absolute',
					left: WIDTH / 2 - 430 + swayX,
					top: 1090,
					width: 860,
					height: 70,
					borderRadius: '50%',
					background: 'radial-gradient(closest-side, rgba(0,0,0,0.55), transparent)',
					transform: `scale(${1 - walking * 0.12})`,
				}}
			/>

			<div
				style={{
					position: 'absolute',
					left: (WIDTH - LAPTOP_W) / 2 + swayX,
					top: 560 + bobY,
					transform: `rotate(${tilt}deg)`,
				}}
			>
				<Laptop lid={lid} screen={<Terminal tests={tests} done={done} />} />
			</div>

			{/* What keepAwake is doing while the lid is shut */}
			<div style={{position: 'absolute', left: 110, right: 110, top: 400, opacity: hud, transform: `translateY(${(1 - hud) * 20}px)`}}>
				<Hud done={done} tests={tests} minutes={meetingMinutes} />
			</div>
		</AbsoluteFill>
	);
};

const Terminal: React.FC<{tests: number; done: boolean}> = ({tests, done}) => (
	<div style={{padding: '26px 28px', fontFamily: MONO, fontSize: 21, lineHeight: 1.75, color: C.text}}>
		<div style={{color: C.muted, fontSize: 17, marginBottom: 8}}>claude — ~/payments</div>
		<div>
			<span style={{color: C.accent}}>&gt;</span> refactor payments/, run all tests
		</div>
		<div>
			<span style={{color: C.ok}}>●</span> Edited 17 files <span style={{color: C.muted}}>(+612 −389)</span>
		</div>
		<div>
			<span style={{color: done ? C.ok : C.warn}}>●</span> Tests {tests.toLocaleString('en-US')} / {TESTS.toLocaleString('en-US')}
		</div>
		<div style={{height: 10, borderRadius: 5, background: 'rgba(255,255,255,0.08)', margin: '10px 0 14px'}}>
			<div style={{width: `${(tests / TESTS) * 100}%`, height: '100%', borderRadius: 5, background: done ? C.ok : C.accent}} />
		</div>
		{done && <div style={{color: C.ok}}>✓ All 1,204 tests passed. Done.</div>}
	</div>
);

const Hud: React.FC<{done: boolean; tests: number; minutes: number}> = ({done, tests, minutes}) => (
	<div
		style={{
			borderRadius: 26,
			background: 'rgba(21,23,28,0.92)',
			border: `1px solid ${done ? C.line : 'rgba(79,140,255,0.4)'}`,
			boxShadow: done ? 'none' : '0 0 50px rgba(79,140,255,0.18)',
			padding: '26px 30px',
			fontFamily: SANS,
		}}
	>
		<div style={{display: 'flex', alignItems: 'center', gap: 18}}>
			{done ? <Mug size={40} color={C.muted} stroke={2.2} /> : <Mug size={40} color={C.accent} filled cutout="#fff" stroke={2.2} />}
			<div style={{flex: 1}}>
				<div style={{fontSize: 30, fontWeight: 700, color: C.text}}>keepAwake</div>
				<div style={{fontSize: 23, color: C.muted, marginTop: 2}}>{done ? 'Inactive' : 'Active · held by Claude Code'}</div>
			</div>
			<div
				style={{
					fontSize: 21,
					color: C.muted,
					padding: '8px 14px',
					borderRadius: 12,
					background: 'rgba(255,255,255,0.06)',
					fontVariantNumeric: 'tabular-nums',
				}}
			>
				📅 Meeting · {minutes} min
			</div>
		</div>
		<div style={{display: 'flex', alignItems: 'center', gap: 12, marginTop: 20, fontSize: 25, color: C.text}}>
			<div style={{width: 12, height: 12, borderRadius: 6, background: done ? C.muted : C.ok}} />
			{done ? 'Claude Code finished, so the Mac goes to sleep' : 'Lid closed · Mac still awake'}
		</div>
		<div style={{fontFamily: MONO, fontSize: 22, color: done ? C.ok : C.muted, marginTop: 10}}>
			{done ? '✓ 1,204 / 1,204 tests passed' : `Tests ${tests.toLocaleString('en-US')} / 1,204`}
		</div>
	</div>
);
