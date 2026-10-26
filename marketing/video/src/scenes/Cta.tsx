import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Enter, GridBackground, Headline} from '../components/Common';
import {C, MONO, SANS} from '../theme';

export const Cta: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();
	const pop = spring({frame, fps, config: {damping: 13}});
	const pulse = frame > 44 ? 1 + 0.035 * Math.sin(((frame - 44) / fps) * Math.PI * 2 * 0.9) : 1;

	return (
		<AbsoluteFill>
			<GridBackground glow={0.3} />
			<AbsoluteFill style={{alignItems: 'center', top: 190}}>
				<Img
					src={staticFile('icon.png')}
					style={{
						width: 250,
						height: 250,
						transform: `scale(${0.6 + 0.4 * pop})`,
						opacity: interpolate(frame, [0, 6], [0, 1], {extrapolateRight: 'clamp'}),
						filter: 'drop-shadow(0 24px 50px rgba(79,140,255,0.35))',
					}}
				/>
				<Enter delay={8} style={{marginTop: 26}}>
					<Headline size={88}>keepAwake for Mac</Headline>
				</Enter>
				<Enter delay={16} style={{marginTop: 14}}>
					<Headline size={42} weight={500} color={C.muted}>
						Free &amp; open source
					</Headline>
				</Enter>
				<Enter delay={26} style={{marginTop: 64}}>
					<div
						style={{
							transform: `scale(${pulse})`,
							display: 'flex',
							alignItems: 'center',
							gap: 18,
							padding: '30px 64px',
							borderRadius: 24,
							background: C.accent,
							color: '#fff',
							fontFamily: SANS,
							fontSize: 46,
							fontWeight: 700,
							boxShadow: '0 20px 50px rgba(79,140,255,0.45)',
						}}
					>
						<svg width={40} height={40} viewBox="0 0 24 24" fill="none">
							<path d="M12 4v11M7 10.5l5 5 5-5M5 20h14" stroke="#fff" strokeWidth={2.4} strokeLinecap="round" strokeLinejoin="round" />
						</svg>
						Download free
					</div>
				</Enter>
				<Enter delay={36} style={{marginTop: 46}}>
					<div style={{fontFamily: MONO, fontSize: 34, color: C.text}}>mikespineu.github.io/keepAwake</div>
				</Enter>
				<Enter delay={44} style={{marginTop: 18}}>
					<div style={{fontFamily: SANS, fontSize: 28, color: C.muted}}>macOS 14+ · Apple Silicon &amp; Intel</div>
				</Enter>
			</AbsoluteFill>
		</AbsoluteFill>
	);
};
