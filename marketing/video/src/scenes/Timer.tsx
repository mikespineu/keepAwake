import React from 'react';
import {interpolate, Easing, useCurrentFrame, useVideoConfig} from 'remotion';
import {CaptionBand, cursorAt, isPressed, menuBarCountdown, openAmount, statusCountdown} from '../components/Demo';
import {Desktop, DESKTOP_SCALE, H_PT, MUG_TARGET, PANEL_LEFT, W_PT} from '../components/Desktop';
import {MenuState} from '../components/MenuPanel';
import {C} from '../theme';

const CLICK_MUG = 40;
const CLICK_PRESET = 90;
const STARTED = CLICK_PRESET + 5;
const CLOSE = 138;
const ONE_HOUR_BUTTON = {x: PANEL_LEFT + 243, y: 138};
const ZOOM = 3.2;

export const Timer: React.FC = () => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();
	const running = frame >= STARTED;
	const remaining = 3600 - Math.max(0, Math.floor((frame - STARTED) / fps));

	const cursor = cursorAt(frame, [
		{at: 6, x: W_PT * 0.42, y: H_PT * 0.5},
		{at: CLICK_MUG - 2, ...MUG_TARGET},
		{at: 58, ...MUG_TARGET},
		{at: CLICK_PRESET - 2, ...ONE_HOUR_BUTTON},
		{at: CLICK_PRESET + 6, ...ONE_HOUR_BUTTON},
		{at: CLICK_PRESET + 30, x: W_PT * 0.3, y: H_PT * 0.45},
	]);

	const state: MenuState = running
		? {
				status: `Active · ${statusCountdown(remaining)} (until 22:31)`,
				activeText: 'Your Mac stays awake until the countdown ends.',
				showPresets: false,
				battery: 64,
			}
		: {status: 'Inactive', showPresets: true, pressed: isPressed(frame, CLICK_PRESET) ? '1 h' : undefined, battery: 64};

	const zoom = interpolate(frame, [CLOSE + 4, CLOSE + 36], [0, 1], {
		extrapolateLeft: 'clamp',
		extrapolateRight: 'clamp',
		easing: Easing.inOut(Easing.cubic),
	});

	return (
		<Desktop
			time="21:31"
			mug={{active: running, label: running ? menuBarCountdown(remaining) : undefined, highlighted: frame >= CLICK_MUG && frame < CLOSE}}
			panel={{state, open: openAmount(frame, CLICK_MUG + 2, fps, CLOSE)}}
			cursor={{...cursor, pressed: isPressed(frame, CLICK_MUG) || isPressed(frame, CLICK_PRESET), opacity: interpolate(frame, [CLOSE - 10, CLOSE], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})}}
			// The menu bar stays pinned to the top edge while the camera zooms in on the countdown.
			camera={{progress: zoom, zoom: ZOOM, focus: {x: W_PT - 134 - 34, y: 13}, target: {x: 540, y: 13 * DESKTOP_SCALE * ZOOM}}}
		>
			<CaptionBand
				frame={frame}
				captions={[
					{from: 6, to: STARTED + 6, text: 'Click the mug. Pick a time.'},
					{
						from: STARTED + 8,
						to: 220,
						text: (
							<>
								Countdown right in
								<br />
								<span style={{color: C.accent}}>your menu bar.</span>
							</>
						),
					},
				]}
			/>
		</Desktop>
	);
};
