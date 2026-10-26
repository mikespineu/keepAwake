import React from 'react';

// The terminal mug from the app icon, drawn as a line glyph.
// `filled` matches the active state: solid cup with the prompt cut out.
export const Mug: React.FC<{size: number; color: string; filled?: boolean; cutout?: string; stroke?: number}> = ({
	size,
	color,
	filled = false,
	cutout = '#000',
	stroke = 2.2,
}) => (
	<svg width={size * (28 / 22)} height={size} viewBox="0 0 28 22" fill="none">
		<rect
			x={1.5}
			y={1.5}
			width={18.5}
			height={19}
			rx={3.2}
			stroke={color}
			strokeWidth={stroke}
			fill={filled ? color : 'none'}
		/>
		<path
			d="M20 6h2.6a3.4 3.4 0 0 1 3.4 3.4v1.2a3.4 3.4 0 0 1-3.4 3.4H20"
			stroke={color}
			strokeWidth={stroke}
			strokeLinecap="round"
		/>
		<polyline
			points="6,7.6 9.6,10.8 6,14"
			stroke={filled ? cutout : color}
			strokeWidth={stroke}
			strokeLinecap="round"
			strokeLinejoin="round"
		/>
		<line x1={11.6} y1={15} x2={15.6} y2={15} stroke={filled ? cutout : color} strokeWidth={stroke} strokeLinecap="round" />
	</svg>
);

export const Cursor: React.FC<{size?: number}> = ({size = 34}) => (
	<svg width={size} height={size * 1.3} viewBox="0 0 20 26" style={{filter: 'drop-shadow(0 2px 3px rgba(0,0,0,0.45))'}}>
		<path d="M2 1.5 L2 20.5 L6.8 16 L10.2 23.8 L13.6 22.3 L10.3 14.7 L16.8 14.7 Z" fill="#000" stroke="#fff" strokeWidth={1.4} strokeLinejoin="round" />
	</svg>
);

export const Wifi: React.FC<{size: number; color: string}> = ({size, color}) => (
	<svg width={size} height={size * 0.78} viewBox="0 0 18 14" fill="none">
		<path d="M1 4.8a11.5 11.5 0 0 1 16 0" stroke={color} strokeWidth={1.9} strokeLinecap="round" />
		<path d="M3.9 7.9a7.4 7.4 0 0 1 10.2 0" stroke={color} strokeWidth={1.9} strokeLinecap="round" />
		<path d="M6.8 10.9a3.2 3.2 0 0 1 4.4 0" stroke={color} strokeWidth={1.9} strokeLinecap="round" />
		<circle cx={9} cy={13} r={0.9} fill={color} />
	</svg>
);

export const Battery: React.FC<{size: number; color: string; level: number}> = ({size, color, level}) => (
	<svg width={size * 2.1} height={size} viewBox="0 0 25 12" fill="none">
		<rect x={0.8} y={0.8} width={20.4} height={10.4} rx={3} stroke={color} strokeOpacity={0.55} strokeWidth={1.3} />
		<rect x={2.6} y={2.6} width={16.8 * level} height={6.8} rx={1.6} fill={color} />
		<path d="M22.6 4.2v3.6a1.9 1.9 0 0 0 0-3.6z" fill={color} fillOpacity={0.55} />
	</svg>
);

type IconName = 'clock' | 'agent' | 'battery' | 'lid' | 'display' | 'login';

// Line icons for the feature tiles.
export const FeatureIcon: React.FC<{name: IconName; size: number; color: string}> = ({name, size, color}) => {
	const p = {stroke: color, strokeWidth: 1.8, strokeLinecap: 'round' as const, strokeLinejoin: 'round' as const, fill: 'none'};
	return (
		<svg width={size} height={size} viewBox="0 0 24 24">
			{name === 'clock' && (
				<>
					<circle cx={12} cy={12} r={9} {...p} />
					<path d="M12 7v5l3.5 2" {...p} />
				</>
			)}
			{name === 'agent' && (
				<>
					<rect x={4} y={7} width={16} height={12} rx={3} {...p} />
					<path d="M12 7V4M9 12.5v1.5M15 12.5v1.5M2 12v3M22 12v3" {...p} />
				</>
			)}
			{name === 'battery' && (
				<>
					<rect x={2.5} y={7} width={17} height={10} rx={2.5} {...p} />
					<path d="M22 10.5v3" {...p} />
					<path d="M6 10v4" {...p} stroke="#ff5f57" />
				</>
			)}
			{name === 'lid' && (
				<>
					<path d="M5 15.5 L7 5.5 h10 l2 10" {...p} />
					<path d="M2.5 15.5h19l-1.5 3h-16z" {...p} />
				</>
			)}
			{name === 'display' && (
				<>
					<rect x={2.5} y={4} width={19} height={12.5} rx={2} {...p} />
					<path d="M9 20.5h6M12 16.5v4" {...p} />
					<path d="M12 7.5v1M12 13v1M8.6 10.8h1M14.4 10.8h1" {...p} />
				</>
			)}
			{name === 'login' && (
				<>
					<path d="M12 3v8" {...p} />
					<path d="M7 6.5a7.5 7.5 0 1 0 10 0" {...p} />
				</>
			)}
		</svg>
	);
};
