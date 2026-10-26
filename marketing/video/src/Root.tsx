import React from 'react';
import {Composition} from 'remotion';
import {Ad} from './Ad';
import {LID_TOTAL_FRAMES, LidClosedAd} from './LidClosedAd';
import {FPS, HEIGHT, TOTAL_FRAMES, WIDTH} from './theme';

export const Root: React.FC = () => (
	<>
		<Composition id="KeepAwakeAd" component={Ad} durationInFrames={TOTAL_FRAMES} fps={FPS} width={WIDTH} height={HEIGHT} />
		<Composition
			id="KeepAwakeLidClosed"
			component={LidClosedAd}
			durationInFrames={LID_TOTAL_FRAMES}
			fps={FPS}
			width={WIDTH}
			height={HEIGHT}
		/>
	</>
);
