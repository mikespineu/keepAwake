import React from 'react';
import {Easing, interpolate, useCurrentFrame} from 'remotion';
import {CaptionBand, cursorAt, isPressed} from '../../components/Demo';
import {DESKTOP_SCALE, Desktop, PANEL_LEFT, W_PT} from '../../components/Desktop';
import {MenuState} from '../../components/MenuPanel';
import {C, WIDTH} from '../../theme';

// The two settings behind the story: the Claude Code hold and the lid-closed switch.
const PAN = [8, 40];
const CLICK_LID = 62;
const LID_ON = CLICK_LID + 5;
const LID_TOGGLE = {x: PANEL_LEFT + 110, y: 559};
const ZOOM = 1.15;

export const LidMenu: React.FC = () => {
	const frame = useCurrentFrame();
	const lidOn = frame >= LID_ON;

	const cursor = cursorAt(frame, [
		{at: 16, x: W_PT * 0.3, y: 420},
		{at: CLICK_LID - 2, ...LID_TOGGLE},
		{at: CLICK_LID + 14, ...LID_TOGGLE},
		{at: CLICK_LID + 40, x: W_PT * 0.25, y: 470},
	]);

	const state: MenuState = {
		status: 'Active · held by Claude Code',
		activeText: 'Kept awake by Claude Code.',
		showPresets: true,
		hold: {name: 'Claude Code', until: '22:13'},
		claudeConnected: true,
		battery: 59,
		lidClosed: lidOn,
		lidHelperInstalled: lidOn,
		glow: lidOn ? 'lid' : frame < CLICK_LID - 10 ? 'hold' : null,
	};

	const pan = interpolate(frame, PAN, [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.inOut(Easing.cubic)});

	return (
		<Desktop
			time="21:43"
			mug={{active: true, highlighted: true}}
			panel={{state, open: 1}}
			cursor={{...cursor, pressed: isPressed(frame, CLICK_LID), opacity: interpolate(frame, [10, 18], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})}}
			camera={{
				progress: pan,
				zoom: ZOOM,
				focus: {x: PANEL_LEFT + 150, y: 470},
				// As far left as possible while the right edge of the screen stays in frame.
				target: {x: ZOOM * (PANEL_LEFT + 150) * DESKTOP_SCALE + WIDTH * (1 - ZOOM), y: 470 * DESKTOP_SCALE - 300},
			}}
		>
			<CaptionBand
				frame={frame}
				captions={[
					{
						from: 2,
						to: LID_ON + 4,
						text: (
							<>
								Connect Claude Code,
								<br />
								<span style={{color: C.accent}}>then flip one switch.</span>
							</>
						),
					},
					{
						from: LID_ON + 6,
						to: 230,
						text: (
							<>
								Keep awake with lid closed.
								<br />
								<span style={{color: C.muted, fontSize: 40, fontWeight: 600}}>No external display needed.</span>
							</>
						),
					},
				]}
			/>
		</Desktop>
	);
};
