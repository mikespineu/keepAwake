import React from 'react';
import {Mug} from './Glyphs';

// A MacBook in CSS 3D. `lid` goes from 0 (open, screen facing us) to 1 (closed).
export const LAPTOP_W = 760;
const LID_H = 480;
const BASE_D = 480;
const TILT = 18; // camera looks down at the laptop
const BASE_DROP = 9; // base thickness, so the closed lid rests on it

export const Laptop: React.FC<{lid: number; screen: React.ReactNode; screenOn?: number}> = ({lid, screen, screenOn = 1}) => (
	<div style={{perspective: 2400, width: LAPTOP_W, height: LID_H}}>
		<div
			style={{
				position: 'relative',
				width: LAPTOP_W,
				height: LID_H,
				transformStyle: 'preserve-3d',
				transform: `rotateX(${-TILT}deg)`,
			}}
		>
			{/* Base, lying flat and pointing at the viewer */}
			<div
				style={{
					position: 'absolute',
					left: 0,
					top: LID_H,
					width: LAPTOP_W,
					height: BASE_D,
					transformOrigin: 'top center',
					transform: `rotateX(90deg) translateZ(${-BASE_DROP}px)`,
					borderRadius: '6px 6px 26px 26px',
					background: 'linear-gradient(180deg, #4a4e57 0%, #3a3d45 100%)',
					boxShadow: 'inset 0 0 0 2px rgba(255,255,255,0.08)',
				}}
			>
				{/* Keyboard */}
				<div
					style={{
						position: 'absolute',
						left: 70,
						right: 70,
						top: 34,
						height: 200,
						borderRadius: 10,
						background: '#1d1f24',
						backgroundImage:
							'linear-gradient(90deg, rgba(255,255,255,0.06) 1px, transparent 1px), linear-gradient(rgba(255,255,255,0.06) 1px, transparent 1px)',
						backgroundSize: '41px 40px',
					}}
				/>
				{/* Trackpad */}
				<div
					style={{
						position: 'absolute',
						left: '50%',
						top: 262,
						width: 290,
						height: 180,
						marginLeft: -145,
						borderRadius: 14,
						background: 'rgba(255,255,255,0.05)',
						boxShadow: 'inset 0 0 0 1.5px rgba(255,255,255,0.08)',
					}}
				/>
			</div>

			{/* Lid, hinged at its bottom edge */}
			<div
				style={{
					position: 'absolute',
					left: 0,
					top: 0,
					width: LAPTOP_W,
					height: LID_H,
					transformOrigin: 'bottom center',
					transformStyle: 'preserve-3d',
					transform: `rotateX(${-lid * 90}deg)`,
				}}
			>
				{/* Screen side */}
				<div
					style={{
						position: 'absolute',
						inset: 0,
						backfaceVisibility: 'hidden',
						borderRadius: 26,
						background: '#08090b',
						boxShadow: 'inset 0 0 0 2px #3a3d45',
						padding: 18,
						boxSizing: 'border-box',
					}}
				>
					<div
						style={{
							width: '100%',
							height: '100%',
							borderRadius: 10,
							overflow: 'hidden',
							background: '#0f1115',
							opacity: screenOn,
							position: 'relative',
						}}
					>
						{screen}
					</div>
				</div>
				{/* Back of the lid */}
				<div
					style={{
						position: 'absolute',
						inset: 0,
						backfaceVisibility: 'hidden',
						transform: 'rotateX(180deg)',
						borderRadius: 26,
						background: 'linear-gradient(160deg, #5a5e68 0%, #42454d 60%, #383b42 100%)',
						boxShadow: 'inset 0 0 0 2px rgba(255,255,255,0.1)',
						display: 'flex',
						alignItems: 'center',
						justifyContent: 'center',
					}}
				>
					<div style={{opacity: 0.35}}>
						<Mug size={70} color="#e6e8ee" stroke={1.6} />
					</div>
				</div>
			</div>
		</div>
	</div>
);
