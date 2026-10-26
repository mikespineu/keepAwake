import React from 'react';
import {AbsoluteFill} from 'remotion';
import {Enter, GridBackground, Headline} from '../../components/Common';
import {FeatureIcon} from '../../components/Glyphs';
import {C, SANS} from '../../theme';

const ITEMS = [
	{icon: 'agent', title: 'Claude Code & Cursor', sub: 'Awake while they work, asleep when they finish'},
	{icon: 'lid', title: 'Lid closed', sub: 'Keeps running with the lid shut, no monitor'},
	{icon: 'clock', title: 'Timer', sub: '15 min to 30 days, countdown in the menu bar'},
	{icon: 'battery', title: 'Battery guard', sub: 'Turns itself off below 10%'},
] as const;

export const Recap: React.FC = () => (
	<AbsoluteFill>
		<GridBackground glow={0.14} />
		<div style={{position: 'absolute', top: 140, left: 60, right: 60}}>
			<Enter delay={2}>
				<Headline size={74}>
					One tiny
					<br />
					<span style={{color: C.accent}}>menu bar app.</span>
				</Headline>
			</Enter>
		</div>
		<div style={{position: 'absolute', top: 420, left: 70, right: 70, display: 'flex', flexDirection: 'column', gap: 22}}>
			{ITEMS.map((item, i) => (
				<Enter key={item.title} delay={10 + i * 7}>
					<div
						style={{
							display: 'flex',
							alignItems: 'center',
							gap: 26,
							padding: '24px 28px',
							borderRadius: 24,
							background: C.surface,
							border: `1px solid ${C.line}`,
						}}
					>
						<div
							style={{
								width: 76,
								height: 76,
								borderRadius: 18,
								flexShrink: 0,
								background: 'rgba(79,140,255,0.14)',
								display: 'flex',
								alignItems: 'center',
								justifyContent: 'center',
							}}
						>
							<FeatureIcon name={item.icon} size={44} color={C.accent} />
						</div>
						<div style={{fontFamily: SANS}}>
							<div style={{fontSize: 36, fontWeight: 700, color: C.text}}>{item.title}</div>
							<div style={{fontSize: 24, color: C.muted, marginTop: 4}}>{item.sub}</div>
						</div>
					</div>
				</Enter>
			))}
		</div>
	</AbsoluteFill>
);
