import React from 'react';
import {AbsoluteFill} from 'remotion';
import {Enter, GridBackground, Headline} from '../../components/Common';
import {C} from '../../theme';

export const Intro: React.FC = () => (
	<AbsoluteFill>
		<GridBackground glow={0.2} />
		<AbsoluteFill style={{justifyContent: 'center', padding: '0 70px'}}>
			<Enter delay={2}>
				<Headline size={92}>
					Nobody knew they
					<br />
					needed this.
				</Headline>
			</Enter>
			<Enter delay={30} style={{marginTop: 34}}>
				<Headline size={54} weight={500} color={C.muted}>
					Including me. 😅
				</Headline>
			</Enter>
		</AbsoluteFill>
	</AbsoluteFill>
);
