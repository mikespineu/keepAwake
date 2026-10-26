import React from 'react';
import {AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {C, SANS} from '../theme';

// Website background: near-black with a faint blue grid and a soft accent glow.
export const GridBackground: React.FC<{glow?: number}> = ({glow = 0.18}) => (
	<AbsoluteFill
		style={{
			background: `radial-gradient(ellipse 70% 45% at 50% 42%, rgba(79,140,255,${glow}), transparent 70%),
				linear-gradient(${C.grid} 1px, transparent 1px) 0 0 / 48px 48px,
				linear-gradient(90deg, ${C.grid} 1px, transparent 1px) 0 0 / 48px 48px,
				${C.bg}`,
		}}
	/>
);

// Fade + rise in, starting at `delay` frames.
export const useEnter = (delay: number, damping = 18) => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();
	const s = spring({frame: frame - delay, fps, config: {damping, mass: 0.7}});
	return {
		opacity: interpolate(frame - delay, [0, 8], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}),
		transform: `translateY(${(1 - s) * 40}px)`,
	};
};

export const Enter: React.FC<{delay: number; style?: React.CSSProperties; children: React.ReactNode}> = ({
	delay,
	style,
	children,
}) => {
	const enter = useEnter(delay);
	return <div style={{...style, ...enter}}>{children}</div>;
};

// Fades a block out between two frames (inclusive start, exclusive end).
export const fadeOut = (frame: number, from: number, len = 8) =>
	interpolate(frame, [from, from + len], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

export const Headline: React.FC<{
	children: React.ReactNode;
	size?: number;
	color?: string;
	weight?: number;
	style?: React.CSSProperties;
}> = ({children, size = 76, color = C.text, weight = 750, style}) => (
	<div
		style={{
			fontFamily: SANS,
			fontSize: size,
			fontWeight: weight,
			color,
			letterSpacing: '-0.025em',
			lineHeight: 1.08,
			textAlign: 'center',
			...style,
		}}
	>
		{children}
	</div>
);

// Caption card used over the macOS wallpaper, kept legible on any background.
export const Caption: React.FC<{children: React.ReactNode; size?: number}> = ({children, size = 58}) => (
	<div
		style={{
			fontFamily: SANS,
			fontSize: size,
			fontWeight: 750,
			color: '#fff',
			letterSpacing: '-0.02em',
			lineHeight: 1.12,
			textAlign: 'center',
			textShadow: '0 2px 18px rgba(0,0,0,0.45)',
		}}
	>
		{children}
	</div>
);
