import React from 'react';
import {Easing, interpolate, useCurrentFrame} from 'remotion';
import {Enter} from '../components/Common';
import {CaptionBand, cursorAt, isPressed} from '../components/Demo';
import {Desktop, H_PT, PANEL_LEFT, W_PT} from '../components/Desktop';
import {MenuState} from '../components/MenuPanel';
import {C, MONO, SANS} from '../theme';

const CLICK_CONNECT = 36;
const CONNECTED = CLICK_CONNECT + 5;
const AGENT_START = 66;
const HOLD = 82;
const AGENT_DONE = 150;
const RELEASE = 160;
const CONNECT_BUTTON = {x: PANEL_LEFT + 111, y: 375};
const TESTS = 1204;

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const Agents: React.FC = () => {
	const frame = useCurrentFrame();
	const held = frame >= HOLD && frame < RELEASE;

	const cursor = cursorAt(frame, [
		{at: 4, x: W_PT * 0.5, y: H_PT * 0.42},
		{at: CLICK_CONNECT - 2, ...CONNECT_BUTTON},
	]);

	const base = {
		showPresets: true,
		battery: 59,
		claudeConnected: frame >= CONNECTED,
		pressed: isPressed(frame, CLICK_CONNECT) ? 'Claude Code' : undefined,
	};
	const state: MenuState = held
		? {
				...base,
				status: 'Active · held by Claude Code',
				activeText: 'Kept awake by Claude Code.',
				hold: {name: 'Claude Code', until: '22:13'},
				glow: frame < HOLD + 50 ? 'hold' : null,
			}
		: {
				...base,
				status: 'Inactive',
				connectMessage: frame >= CONNECTED && frame < HOLD ? 'Connected Claude Code. New sessions use it.' : undefined,
				glow: frame >= CONNECTED && frame < AGENT_START ? 'connect' : null,
			};

	return (
		<Desktop
			time="21:43"
			mug={{active: held, highlighted: true}}
			panel={{state, open: 1}}
			cursor={{
				...cursor,
				pressed: isPressed(frame, CLICK_CONNECT),
				opacity: interpolate(frame, [AGENT_START - 8, AGENT_START], [1, 0], clamp),
			}}
		>
			{frame >= AGENT_START && <AgentCard frame={frame} />}
			<CaptionBand
				frame={frame}
				captions={[
					{
						from: 4,
						to: HOLD,
						text: (
							<>
								Connect Claude Code or Cursor.
								<br />
								<span style={{color: C.accent}}>One click.</span>
							</>
						),
					},
					{from: HOLD + 2, to: RELEASE, text: 'Awake while your agent works.'},
					{
						from: RELEASE + 2,
						to: 250,
						text: (
							<>
								Asleep when <span style={{color: C.accent}}>it's done.</span>
							</>
						),
					},
				]}
			/>
		</Desktop>
	);
};

// A small terminal on the left of the screen, where the agent works.
const AgentCard: React.FC<{frame: number}> = ({frame}) => {
	const tests = Math.round(
		interpolate(frame, [AGENT_START + 18, AGENT_DONE], [0, TESTS], {...clamp, easing: Easing.inOut(Easing.quad)}),
	);
	const done = frame >= AGENT_DONE;
	const spinner = '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'[Math.floor(frame / 2) % 10];
	return (
		<div style={{position: 'absolute', left: 26, top: 300, width: 500}}>
			<Enter delay={AGENT_START}>
				<div
					style={{
						borderRadius: 18,
						background: 'rgba(14,16,22,0.94)',
						border: '1px solid rgba(255,255,255,0.12)',
						boxShadow: '0 24px 60px rgba(0,0,0,0.45)',
						overflow: 'hidden',
					}}
				>
					<div
						style={{
							height: 40,
							display: 'flex',
							alignItems: 'center',
							gap: 8,
							padding: '0 16px',
							background: 'rgba(255,255,255,0.05)',
							fontFamily: SANS,
							fontSize: 17,
							color: C.muted,
						}}
					>
						{['#ff5f57', '#febc2e', '#28c840'].map((c) => (
							<div key={c} style={{width: 11, height: 11, borderRadius: 6, background: c}} />
						))}
						<span style={{marginLeft: 10}}>claude — ~/payments</span>
					</div>
					<div style={{padding: '18px 20px 22px', fontFamily: MONO, fontSize: 19, lineHeight: 1.7, color: C.text}}>
						<div>
							<span style={{color: C.accent}}>&gt;</span> refactor payments/, run tests
						</div>
						<div style={{color: C.muted}}>
							<span style={{color: C.ok}}>●</span> Edited 17 files
						</div>
						<div style={{color: done ? C.ok : C.text}}>
							{done ? '✓' : spinner} Tests {tests.toLocaleString('en-US')} / {TESTS.toLocaleString('en-US')}
						</div>
						<div style={{height: 32, color: C.ok}}>{done && 'All tests passed. Done.'}</div>
					</div>
				</div>
			</Enter>
		</div>
	);
};
