import React from 'react';
import {AbsoluteFill, Easing, interpolate, spring} from 'remotion';
import {Caption} from './Common';

type Point = {x: number; y: number};
export type CursorKey = {at: number} & Point;

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// Moves the cursor through keyframes with an ease-in-out between each pair.
export const cursorAt = (frame: number, keys: CursorKey[]): Point => {
	if (frame <= keys[0].at) return keys[0];
	for (let i = 1; i < keys.length; i++) {
		const a = keys[i - 1];
		const b = keys[i];
		if (frame <= b.at) {
			const t = interpolate(frame, [a.at, b.at], [0, 1], {...clamp, easing: Easing.inOut(Easing.cubic)});
			return {x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t};
		}
	}
	return keys[keys.length - 1];
};

export const isPressed = (frame: number, clickAt: number) => frame >= clickAt && frame < clickAt + 5;

export const openAmount = (frame: number, openAt: number, fps: number, closeAt = Infinity) =>
	spring({frame: frame - openAt, fps, config: {damping: 20, mass: 0.5}}) *
	interpolate(frame, [closeAt, closeAt + 8], [1, 0], clamp);

// The same countdown text as KeepAwakeController.statusText and .menuBarText.
export const statusCountdown = (total: number) =>
	`${Math.floor(total / 3600)}:${String(Math.floor((total % 3600) / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;

export const menuBarCountdown = (total: number) => {
	const hours = Math.floor(total / 3600);
	const minutes = Math.floor((total % 3600) / 60);
	const seconds = total % 60;
	return hours > 0 ? `${hours}:${String(minutes).padStart(2, '0')}` : `${minutes}:${String(seconds).padStart(2, '0')}`;
};

// Bottom caption band over the wallpaper. Each caption fades in and out on its own window.
export const CaptionBand: React.FC<{frame: number; captions: {from: number; to: number; text: React.ReactNode}[]}> = ({
	frame,
	captions,
}) => (
	<AbsoluteFill>
		<AbsoluteFill
			style={{
				background: 'linear-gradient(to top, rgba(10,10,18,0.96) 0%, rgba(10,10,18,0.9) 20%, rgba(10,10,18,0) 38%)',
			}}
		/>
		{captions.map((c, i) => {
			const opacity = interpolate(frame, [c.from, c.from + 8, c.to - 6, c.to], [0, 1, 1, 0], clamp);
			const rise = interpolate(frame, [c.from, c.from + 10], [24, 0], {...clamp, easing: Easing.out(Easing.cubic)});
			return (
				<AbsoluteFill
					key={i}
					style={{justifyContent: 'flex-end', padding: '0 60px 92px', opacity, transform: `translateY(${rise}px)`}}
				>
					<Caption>{c.text}</Caption>
				</AbsoluteFill>
			);
		})}
	</AbsoluteFill>
);
