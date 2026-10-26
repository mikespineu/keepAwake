import React from 'react';
import {AbsoluteFill, Easing, interpolate, useCurrentFrame} from 'remotion';
import {Enter, GridBackground, Headline, fadeOut} from '../components/Common';
import {C, MONO, SANS} from '../theme';

const TESTS = 1204;
const STUCK_AT = 812;
const SLEEP = 72; // screen starts to dim
const WAKE = 104; // screen comes back

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const Hook: React.FC = () => {
	const frame = useCurrentFrame();
	const done = Math.round(
		interpolate(frame, [40, 74], [0, STUCK_AT], {...clamp, easing: Easing.out(Easing.quad)}),
	);
	const woke = frame >= WAKE;
	const dim =
		interpolate(frame, [SLEEP, SLEEP + 16], [0, 0.95], clamp) - interpolate(frame, [WAKE, WAKE + 10], [0, 0.95], clamp);
	const laterOpacity = interpolate(frame, [86, 94, WAKE - 4, WAKE + 2], [0, 1, 1, 0], clamp);
	const barColor = woke ? C.danger : C.accent;

	return (
		<AbsoluteFill>
			<GridBackground glow={0.1} />

			{/* Story text above the terminal */}
			<div style={{position: 'absolute', top: 150, left: 60, right: 60, height: 200}}>
				{!woke && (
					<div style={{opacity: fadeOut(frame, SLEEP - 6)}}>
						<Enter delay={2}>
							<Headline size={64}>Your AI agent is refactoring.</Headline>
						</Enter>
						<Enter delay={20} style={{marginTop: 18}}>
							<Headline size={44} weight={500} color={C.muted}>
								You go grab a coffee. ☕
							</Headline>
						</Enter>
					</div>
				)}
				{woke && (
					<>
						<Enter delay={WAKE + 4}>
							<Headline size={76}>Your Mac fell asleep.</Headline>
						</Enter>
						<Enter delay={WAKE + 14} style={{marginTop: 6}}>
							<Headline size={76} color={C.danger}>
								Again.
							</Headline>
						</Enter>
					</>
				)}
			</div>

			{/* Terminal */}
			<div
				style={{
					position: 'absolute',
					top: 440,
					left: 70,
					right: 70,
					borderRadius: 22,
					background: '#101217',
					border: `1px solid ${C.line}`,
					boxShadow: '0 40px 90px rgba(0,0,0,0.55)',
					overflow: 'hidden',
				}}
			>
				<div
					style={{
						height: 58,
						display: 'flex',
						alignItems: 'center',
						gap: 12,
						padding: '0 24px',
						background: '#181b22',
						borderBottom: `1px solid ${C.line}`,
					}}
				>
					{['#ff5f57', '#febc2e', '#28c840'].map((c) => (
						<div key={c} style={{width: 16, height: 16, borderRadius: 8, background: c}} />
					))}
					<div style={{flex: 1, textAlign: 'center', fontFamily: SANS, fontSize: 22, color: C.muted, marginRight: 76}}>
						agent — ~/payments-service
					</div>
				</div>
				<div style={{padding: '30px 36px 40px', fontFamily: MONO, fontSize: 28, lineHeight: 1.75, color: C.text}}>
					<Enter delay={6}>
						<span style={{color: C.accent}}>&gt;</span> Refactor payments/ and run all tests
					</Enter>
					<Enter delay={16}>
						<span style={{color: C.ok}}>●</span> Read 42 files
					</Enter>
					<Enter delay={26}>
						<span style={{color: C.ok}}>●</span> Edited 17 files <span style={{color: C.muted}}>(+612 −389)</span>
					</Enter>
					<Enter delay={36}>
						<span style={{color: woke ? C.danger : C.warn}}>●</span> Running tests{' '}
						<span style={{color: woke ? C.danger : C.muted}}>
							{done.toLocaleString('en-US')} / {TESTS.toLocaleString('en-US')}
						</span>
						<div style={{height: 12, borderRadius: 6, background: 'rgba(255,255,255,0.08)', marginTop: 14}}>
							<div style={{width: `${(done / TESTS) * 100}%`, height: '100%', borderRadius: 6, background: barColor}} />
						</div>
					</Enter>
					<div style={{height: 50, marginTop: 18}}>
						{woke && (
							<Enter delay={WAKE + 8}>
								<span style={{color: C.danger}}>⏸ Stuck at {STUCK_AT}. The Mac was asleep.</span>
							</Enter>
						)}
					</div>
				</div>
			</div>

			{/* The display goes to sleep */}
			<AbsoluteFill style={{background: '#000', opacity: dim}} />
			<AbsoluteFill style={{justifyContent: 'center', alignItems: 'center', opacity: laterOpacity}}>
				<div style={{fontFamily: MONO, fontSize: 40, color: C.muted}}>45 minutes later…</div>
			</AbsoluteFill>
		</AbsoluteFill>
	);
};
