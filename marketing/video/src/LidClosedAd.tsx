import React from 'react';
import {AbsoluteFill} from 'remotion';
import {linearTiming, TransitionSeries} from '@remotion/transitions';
import {fade} from '@remotion/transitions/fade';
import {Cta} from './scenes/Cta';
import {Commute} from './scenes/lid/Commute';
import {Intro} from './scenes/lid/Intro';
import {LidMenu} from './scenes/lid/LidMenu';
import {Recap} from './scenes/lid/Recap';
import {C, TRANSITION} from './theme';

// "Close the lid, your agents keep working": the clip for the Slack post.
const SCENES: [string, number, React.FC][] = [
	['intro', 84, Intro],
	['commute', 390, Commute],
	['menu', 190, LidMenu],
	['recap', 120, Recap],
	['cta', 135, Cta],
];

export const LID_TOTAL_FRAMES = SCENES.reduce((sum, [, d]) => sum + d, 0) - TRANSITION * (SCENES.length - 1);

export const LidClosedAd: React.FC = () => (
	<AbsoluteFill style={{background: C.bg}}>
		<TransitionSeries>
			{SCENES.flatMap(([name, duration, Scene], i) => [
				...(i > 0
					? [
							<TransitionSeries.Transition
								key={`${name}-in`}
								presentation={fade()}
								timing={linearTiming({durationInFrames: TRANSITION})}
							/>,
						]
					: []),
				<TransitionSeries.Sequence key={name} durationInFrames={duration}>
					<Scene />
				</TransitionSeries.Sequence>,
			])}
		</TransitionSeries>
	</AbsoluteFill>
);
