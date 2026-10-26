import React from 'react';
import {AbsoluteFill} from 'remotion';
import {Enter, GridBackground, Headline} from '../components/Common';
import {FeatureIcon} from '../components/Glyphs';
import {C, MONO, SANS} from '../theme';

const FEATURES = [
	{icon: 'clock', title: 'Any duration', sub: '15 min to 30 days, or Always'},
	{icon: 'agent', title: 'AI agents', sub: 'Claude Code, Cursor, any MCP client'},
	{icon: 'battery', title: 'Battery guard', sub: 'Turns off below 10%'},
	{icon: 'lid', title: 'Lid closed', sub: 'Keeps running with the lid shut'},
	{icon: 'display', title: 'Keep display on', sub: 'No black screen mid-demo'},
	{icon: 'login', title: 'Launch at login', sub: 'Set it once, forget it'},
] as const;

export const Features: React.FC = () => (
	<AbsoluteFill>
		<GridBackground glow={0.14} />
		<div style={{position: 'absolute', top: 120, left: 60, right: 60}}>
			<Enter delay={2}>
				<Headline size={72}>
					Small app.
					<br />
					<span style={{color: C.accent}}>Smart defaults.</span>
				</Headline>
			</Enter>
		</div>
		<div
			style={{
				position: 'absolute',
				top: 380,
				left: 60,
				right: 60,
				display: 'grid',
				gridTemplateColumns: '1fr 1fr',
				gap: 22,
			}}
		>
			{FEATURES.map((f, i) => (
				<Enter key={f.title} delay={12 + i * 7}>
					<div
						style={{
							height: 222,
							boxSizing: 'border-box',
							padding: '28px 28px',
							borderRadius: 24,
							background: C.surface,
							border: `1px solid ${C.line}`,
						}}
					>
						<div
							style={{
								width: 64,
								height: 64,
								borderRadius: 16,
								background: 'rgba(79,140,255,0.14)',
								display: 'flex',
								alignItems: 'center',
								justifyContent: 'center',
							}}
						>
							<FeatureIcon name={f.icon} size={38} color={C.accent} />
						</div>
						<div style={{fontFamily: SANS, fontSize: 34, fontWeight: 700, color: C.text, marginTop: 20, letterSpacing: '-0.01em'}}>
							{f.title}
						</div>
						<div style={{fontFamily: SANS, fontSize: 23, color: C.muted, marginTop: 6, lineHeight: 1.3}}>{f.sub}</div>
					</div>
				</Enter>
			))}
		</div>
		<Enter delay={64} style={{position: 'absolute', bottom: 92, left: 0, right: 0, textAlign: 'center'}}>
			<span style={{fontFamily: MONO, fontSize: 26, color: C.muted}}>No Dock icon · CLI · keepawake:// URLs</span>
		</Enter>
	</AbsoluteFill>
);
