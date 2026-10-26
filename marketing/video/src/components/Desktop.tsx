import React from 'react';
import {AbsoluteFill} from 'remotion';
import {Battery, Cursor, Mug, Wifi} from './Glyphs';
import {MenuPanel, MenuState, PANEL_WIDTH} from './MenuPanel';
import {HEIGHT, SANS, WIDTH} from '../theme';

// The macOS screen is laid out in points and scaled up, so the menu keeps
// the app's real proportions. Every coordinate below is in points.
export const DESKTOP_SCALE = 1.7;
export const W_PT = WIDTH / DESKTOP_SCALE;
export const H_PT = HEIGHT / DESKTOP_SCALE;
const MENU_BAR = 26;
const MUG_RIGHT = 134;
const MUG_PILL = 30.5;

export const PANEL_LEFT = W_PT - 14 - PANEL_WIDTH;
export const PANEL_TOP = MENU_BAR + 6;
// Centre of the mug glyph while it has no countdown label.
export const MUG_TARGET = {x: W_PT - MUG_RIGHT - MUG_PILL / 2, y: MENU_BAR / 2};

export type Camera = {
	progress: number;
	zoom: number;
	focus: {x: number; y: number}; // points
	target: {x: number; y: number}; // pixels on the frame
};

export const Desktop: React.FC<{
	time: string;
	mug: {active: boolean; label?: string; highlighted?: boolean};
	panel?: {state: MenuState; open: number} | null;
	cursor?: {x: number; y: number; pressed?: boolean; opacity?: number} | null;
	camera?: Camera;
	children?: React.ReactNode;
}> = ({time, mug, panel, cursor, camera, children}) => {
	let transform = 'none';
	if (camera) {
		const px = camera.focus.x * DESKTOP_SCALE;
		const py = camera.focus.y * DESKTOP_SCALE;
		const z = 1 + (camera.zoom - 1) * camera.progress;
		const tx = px + (camera.target.x - px) * camera.progress - z * px;
		const ty = py + (camera.target.y - py) * camera.progress - z * py;
		transform = `translate(${tx}px, ${ty}px) scale(${z})`;
	}

	return (
		<AbsoluteFill style={{overflow: 'hidden', background: '#000'}}>
			<AbsoluteFill style={{transform, transformOrigin: '0 0'}}>
				<div
					style={{
						position: 'absolute',
						width: W_PT,
						// Taller than the frame, so a camera pan downwards never reveals the edge.
						height: H_PT * 2,
						transform: `scale(${DESKTOP_SCALE})`,
						transformOrigin: '0 0',
						fontFamily: SANS,
						background:
							'radial-gradient(ellipse 80% 60% at 20% 15%, rgba(110,140,255,0.55), transparent 60%), linear-gradient(160deg, #5b6bd0 0%, #8070c0 45%, #b27aa4 100%)',
					}}
				>
					<MenuBar time={time} mug={mug} />

					{panel && panel.open > 0 && (
						<div
							style={{
								position: 'absolute',
								left: PANEL_LEFT,
								top: PANEL_TOP,
								opacity: panel.open,
								transform: `translateY(${(1 - panel.open) * -6}px) scale(${0.97 + 0.03 * panel.open})`,
								transformOrigin: 'top center',
							}}
						>
							<MenuPanel state={panel.state} />
						</div>
					)}

					{cursor && (
						<div
							style={{
								position: 'absolute',
								left: cursor.x - 2,
								top: cursor.y - 1.5,
								opacity: cursor.opacity ?? 1,
								transform: `scale(${cursor.pressed ? 0.85 : 1})`,
								transformOrigin: '2px 1.5px',
							}}
						>
							<Cursor size={16} />
						</div>
					)}
				</div>
			</AbsoluteFill>
			{children}
		</AbsoluteFill>
	);
};

const MenuBar: React.FC<{time: string; mug: {active: boolean; label?: string; highlighted?: boolean}}> = ({time, mug}) => (
	<div
		style={{
			position: 'absolute',
			left: 0,
			right: 0,
			top: 0,
			height: MENU_BAR,
			background: 'rgba(18,18,26,0.62)',
			color: '#fff',
		}}
	>
		<div
			style={{
				position: 'absolute',
				right: MUG_RIGHT,
				top: 2,
				height: 22,
				minWidth: MUG_PILL,
				boxSizing: 'border-box',
				padding: '0 7px',
				borderRadius: 6,
				background: mug.highlighted ? 'rgba(255,255,255,0.22)' : 'transparent',
				display: 'flex',
				alignItems: 'center',
				gap: 5,
			}}
		>
			<Mug size={13} color="#fff" filled={mug.active} cutout="#2a2840" stroke={1.9} />
			{mug.label && (
				<span style={{fontFamily: '"SF Mono", ui-monospace, Menlo, monospace', fontSize: 13, fontWeight: 500}}>{mug.label}</span>
			)}
		</div>
		<div style={{position: 'absolute', right: 105, top: 7}}>
			<Wifi size={16} color="#fff" />
		</div>
		<div style={{position: 'absolute', right: 66, top: 8}}>
			<Battery size={10.5} color="#fff" level={0.6} />
		</div>
		<div style={{position: 'absolute', right: 12, top: 0, height: MENU_BAR, display: 'flex', alignItems: 'center', fontSize: 13, fontWeight: 600}}>
			{time}
		</div>
	</div>
);
