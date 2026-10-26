import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Enter, GridBackground, Headline} from '../components/Common';
import {C, MONO} from '../theme';

const NAME = 'keepAwake';
const TYPE_START = 20;

export const Reveal: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();
	const pop = spring({frame, fps, config: {damping: 12, mass: 0.8}});
	const typed = Math.max(0, Math.min(NAME.length, Math.floor((frame - TYPE_START) / 2)));
	const caretOn = Math.floor(frame / 8) % 2 === 0;

	return (
		<AbsoluteFill>
			<GridBackground glow={0.3} />
			<AbsoluteFill style={{alignItems: 'center', top: 230}}>
				<Img
					src={staticFile('icon.png')}
					style={{
						width: 360,
						height: 360,
						transform: `scale(${0.55 + 0.45 * pop})`,
						opacity: interpolate(frame, [0, 6], [0, 1], {extrapolateRight: 'clamp'}),
						filter: 'drop-shadow(0 30px 60px rgba(79,140,255,0.35))',
					}}
				/>
				<div
					style={{
						marginTop: 30,
						fontFamily: MONO,
						fontSize: 112,
						fontWeight: 600,
						color: C.text,
						letterSpacing: '-0.03em',
						display: 'flex',
						alignItems: 'center',
						height: 140,
					}}
				>
					<span style={{color: C.muted, marginRight: 28}}>&gt;</span>
					{NAME.slice(0, typed)}
					<span
						style={{
							display: 'inline-block',
							width: 52,
							height: 100,
							marginLeft: 8,
							background: C.accent,
							opacity: caretOn || typed < NAME.length ? 1 : 0,
						}}
					/>
				</div>
				<Enter delay={46} style={{marginTop: 36}}>
					<Headline size={50} weight={600} color={C.muted}>
						Keeps your Mac awake.
						<br />
						<span style={{color: C.text}}>Right from the menu bar.</span>
					</Headline>
				</Enter>
			</AbsoluteFill>
		</AbsoluteFill>
	);
};
