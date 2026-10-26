import React from 'react';
import {AbsoluteFill} from 'remotion';
import {linearTiming, TransitionSeries} from '@remotion/transitions';
import {fade} from '@remotion/transitions/fade';
import {Agents} from './scenes/Agents';
import {Cta} from './scenes/Cta';
import {Features} from './scenes/Features';
import {Hook} from './scenes/Hook';
import {Pain} from './scenes/Pain';
import {Reveal} from './scenes/Reveal';
import {Timer} from './scenes/Timer';
import {C, SCENES, TRANSITION} from './theme';

const ORDER: [keyof typeof SCENES, React.FC][] = [
	['hook', Hook],
	['pain', Pain],
	['reveal', Reveal],
	['timer', Timer],
	['agents', Agents],
	['features', Features],
	['cta', Cta],
];

export const Ad: React.FC = () => (
	<AbsoluteFill style={{background: C.bg}}>
		<TransitionSeries>
			{ORDER.flatMap(([name, Scene], i) => [
				...(i > 0
					? [
							<TransitionSeries.Transition
								key={`${name}-in`}
								presentation={fade()}
								timing={linearTiming({durationInFrames: TRANSITION})}
							/>,
						]
					: []),
				<TransitionSeries.Sequence key={name} durationInFrames={SCENES[name]}>
					<Scene />
				</TransitionSeries.Sequence>,
			])}
		</TransitionSeries>
	</AbsoluteFill>
);
