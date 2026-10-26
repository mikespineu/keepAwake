import React from 'react';
import {Mug} from './Glyphs';
import {SANS} from '../theme';

// The keepAwake 1.2.0 menu, rebuilt from Sources/KeepAwake/MenuView.swift.
// Sizes are in macOS points; <Desktop> scales the whole screen up.

export type MenuState = {
	status: string;
	// Text above Turn Off. When set, the active section is shown.
	activeText?: string;
	// Presets are hidden while your own timer runs, shown otherwise.
	showPresets: boolean;
	pressed?: string;
	hold?: {name: string; until: string} | null;
	claudeConnected?: boolean;
	connectMessage?: string;
	battery: number;
	lidClosed?: boolean;
	// After the first time lid mode is turned on, the admin-password hint is replaced.
	lidHelperInstalled?: boolean;
	glow?: 'hold' | 'connect' | 'lid' | null;
};

export const PANEL_WIDTH = 300;

const T = {
	text: '#ececec',
	muted: '#9b9b9b',
	button: 'rgba(255,255,255,0.11)',
	pressed: 'rgba(255,255,255,0.30)',
	divider: 'rgba(255,255,255,0.11)',
	box: 'rgba(255,255,255,0.12)',
	accent: '#3478f6',
	glow: '#4f8cff',
};

const Divider = () => <div style={{height: 1, background: T.divider, margin: '11px 0'}} />;

const Btn: React.FC<{
	label: React.ReactNode;
	pressed?: boolean;
	height?: number;
	size?: number;
	style?: React.CSSProperties;
}> = ({label, pressed, height = 24, size = 13, style}) => (
	<div
		style={{
			height,
			borderRadius: 6,
			background: pressed ? T.pressed : T.button,
			boxShadow: '0 0.5px 0 rgba(255,255,255,0.08) inset, 0 0.5px 1px rgba(0,0,0,0.3)',
			display: 'flex',
			alignItems: 'center',
			justifyContent: 'center',
			gap: 6,
			fontSize: size,
			color: T.text,
			padding: '0 10px',
			...style,
		}}
	>
		{label}
	</div>
);

const Check: React.FC<{on: boolean}> = ({on}) => (
	<div
		style={{
			width: 15,
			height: 15,
			borderRadius: 4,
			background: on ? 'rgba(255,255,255,0.22)' : T.box,
			display: 'flex',
			alignItems: 'center',
			justifyContent: 'center',
			flexShrink: 0,
		}}
	>
		{on && (
			<svg width={10} height={10} viewBox="0 0 10 10">
				<path d="M1.5 5.2 L4 7.8 L8.6 2" stroke="#fff" strokeWidth={1.7} fill="none" strokeLinecap="round" strokeLinejoin="round" />
			</svg>
		)}
	</div>
);

const Toggle: React.FC<{on: boolean; label: string}> = ({on, label}) => (
	<div style={{display: 'flex', alignItems: 'center', gap: 7, height: 20, fontSize: 13, color: T.text}}>
		<Check on={on} />
		{label}
	</div>
);

const Stepper: React.FC<{label: string}> = ({label}) => (
	<div style={{display: 'flex', alignItems: 'center', gap: 8}}>
		<span style={{fontSize: 13, color: T.text, fontVariantNumeric: 'tabular-nums'}}>{label}</span>
		<div
			style={{
				width: 19,
				height: 24,
				borderRadius: 5,
				background: 'rgba(255,255,255,0.07)',
				display: 'flex',
				alignItems: 'center',
				justifyContent: 'center',
			}}
		>
			<svg width={11} height={16} viewBox="0 0 11 16">
				<path d="M2 6 L5.5 2.6 L9 6 M2 10 L5.5 13.4 L9 10" stroke="#bbb" strokeWidth={1.3} fill="none" strokeLinecap="round" />
			</svg>
		</div>
	</div>
);

const Caption: React.FC<{children: React.ReactNode; style?: React.CSSProperties}> = ({children, style}) => (
	<div style={{fontSize: 10.5, lineHeight: '14px', color: T.muted, ...style}}>{children}</div>
);

const glowStyle = (on: boolean): React.CSSProperties =>
	on ? {boxShadow: `0 0 0 2px ${T.glow}, 0 0 18px rgba(79,140,255,0.55)`, borderRadius: 7} : {};

export const MenuPanel: React.FC<{state: MenuState}> = ({state}) => {
	const presets = ['15 min', '30 min', '1 h', '2 h', '4 h', 'Always'];
	const active = Boolean(state.activeText);
	return (
		<div
			style={{
				width: PANEL_WIDTH,
				boxSizing: 'border-box',
				padding: 14,
				borderRadius: 12,
				background: 'rgba(31,31,33,0.97)',
				border: '0.5px solid rgba(255,255,255,0.2)',
				boxShadow: '0 0 0 0.5px rgba(0,0,0,0.8), 0 18px 50px rgba(0,0,0,0.45)',
				fontFamily: SANS,
				color: T.text,
			}}
		>
			{/* Header */}
			<div style={{display: 'flex', alignItems: 'center', gap: 10, height: 32}}>
				<div style={{width: 28, display: 'flex', justifyContent: 'center'}}>
					{active ? (
						<Mug size={21} color={T.accent} filled cutout="#fff" stroke={2.3} />
					) : (
						<Mug size={21} color="#9b9b9b" stroke={2.3} />
					)}
				</div>
				<div>
					<div style={{fontSize: 13, fontWeight: 700, lineHeight: '16px'}}>keepAwake</div>
					<div style={{fontSize: 11, color: T.muted, lineHeight: '15px', fontVariantNumeric: 'tabular-nums', marginTop: 1}}>
						{state.status}
					</div>
				</div>
			</div>

			<Divider />

			{active && (
				<div style={{marginBottom: state.showPresets ? 12 : 0}}>
					<div style={{fontSize: 12.5, lineHeight: '16px', marginBottom: 8}}>{state.activeText}</div>
					<Btn
						height={28}
						style={{borderRadius: 14}}
						label={
							<>
								<div style={{width: 9, height: 9, borderRadius: 1.5, background: '#e8e8e8'}} />
								Turn Off
							</>
						}
					/>
				</div>
			)}

			{state.showPresets && (
				<>
					<div style={{fontSize: 12.5, lineHeight: '16px', marginBottom: 9}}>Keep awake for:</div>
					<div style={{display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '6px 8px'}}>
						{presets.map((p) => (
							<Btn key={p} label={p} pressed={state.pressed === p} />
						))}
					</div>
					<div style={{display: 'flex', alignItems: 'center', gap: 10, marginTop: 9}}>
						<Stepper label="0 d" />
						<Stepper label="1 h" />
						<Stepper label="0 min" />
						<div style={{flex: 1}} />
						<Btn label="Start" />
					</div>
				</>
			)}

			<Divider />

			{/* Battery guard */}
			<Toggle on label="Turn off when battery < 10%" />
			<div style={{display: 'flex', alignItems: 'center', gap: 10, marginTop: 6}}>
				<div style={{position: 'relative', flex: 1, height: 16}}>
					<div style={{position: 'absolute', top: 5, left: 0, right: 0, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.14)'}} />
					<div
						style={{
							position: 'absolute',
							top: 1,
							left: 10,
							width: 20,
							height: 13,
							borderRadius: 7,
							background: '#e9e9e9',
							boxShadow: '0 1px 2px rgba(0,0,0,0.4)',
						}}
					/>
				</div>
				<span style={{fontSize: 13, width: 34, textAlign: 'right'}}>10%</span>
			</div>
			<Caption style={{marginTop: 4}}>Applies only when running on battery.</Caption>
			<Caption style={{marginTop: 4}}>Battery {state.battery}% · on battery</Caption>

			<Divider />

			{/* AI agents */}
			<Toggle on label="Let AI agents keep your Mac awake" />
			{state.hold && (
				<div
					style={{
						display: 'flex',
						alignItems: 'center',
						justifyContent: 'space-between',
						marginTop: 6,
						padding: '2px 4px',
						marginLeft: -4,
						marginRight: -4,
						...glowStyle(state.glow === 'hold'),
					}}
				>
					<span style={{fontSize: 11, fontWeight: 500}}>
						{state.hold.name} · until {state.hold.until}
					</span>
					<svg width={13} height={13} viewBox="0 0 13 13">
						<circle cx={6.5} cy={6.5} r={6.5} fill="#8e8e8e" />
						<path d="M4.4 4.4 L8.6 8.6 M8.6 4.4 L4.4 8.6" stroke="#1f1f21" strokeWidth={1.5} strokeLinecap="round" />
					</svg>
				</div>
			)}
			<div style={{display: 'flex', alignItems: 'center', gap: 7, marginTop: 7}}>
				<span style={{fontSize: 11, color: T.muted, marginRight: 1}}>Connect:</span>
				<div style={glowStyle(state.glow === 'connect')}>
					<Btn
						size={12}
						height={22}
						pressed={state.pressed === 'Claude Code'}
						label={state.claudeConnected ? <>✓&nbsp;&nbsp;Claude Code</> : 'Claude Code'}
					/>
				</div>
				<Btn size={12} height={22} label="Cursor" />
			</div>
			<Caption style={{marginTop: 7, minHeight: 28}}>
				{state.connectMessage ?? 'Agents hold the Mac awake while they work, and let it sleep when they finish.'}
			</Caption>

			<Divider />

			<Toggle on={false} label="Keep display on" />
			<div style={{height: 4}} />
			<div style={{padding: '2px 4px', margin: '-2px -4px', ...glowStyle(state.glow === 'lid')}}>
				<Toggle on={Boolean(state.lidClosed)} label="Keep awake with lid closed" />
				{!state.lidHelperInstalled ? (
					<Caption style={{marginTop: 2}}>Asks for your admin password once.</Caption>
				) : state.lidClosed ? (
					<Caption style={{marginTop: 2}}>Don't put a running Mac in a bag — it can overheat.</Caption>
				) : null}
			</div>
			<div style={{height: 4}} />
			<Toggle on={false} label="Launch at login" />

			<Divider />

			<div style={{display: 'flex', justifyContent: 'flex-end'}}>
				<Btn label="Quit keepAwake" />
			</div>
		</div>
	);
};
