import React from 'react';
import {AbsoluteFill, Easing, interpolate, useCurrentFrame} from 'remotion';
import {Enter, GridBackground, Headline} from '../components/Common';
import {C, MONO, SANS} from '../theme';

const ROWS = [
	{title: 'AI agent · refactor', sub: '812 of 1,204 tests', stop: 0.67, fail: 'paused mid-run'},
	{title: 'macos-15.ipsw', sub: '13.4 GB download', stop: 0.91, fail: 'paused at 91%'},
	{title: 'Client demo · Zoom', sub: 'sharing your screen', stop: 0.55, fail: 'screen went black'},
	{title: 'ssh prod-db-01', sub: 'migration running', stop: 0.4, fail: 'connection dropped'},
];

const FILL = 22;

export const Pain: React.FC = () => {
	const frame = useCurrentFrame();
	return (
		<AbsoluteFill>
			<GridBackground glow={0.08} />
			<div style={{position: 'absolute', top: 130, left: 60, right: 60}}>
				<Enter delay={2}>
					<Headline size={70}>Mid-run. Mid-download.</Headline>
				</Enter>
				<Enter delay={8}>
					<Headline size={70} color={C.danger}>
						Mid-demo.
					</Headline>
				</Enter>
			</div>
			<div style={{position: 'absolute', top: 400, left: 70, right: 70, display: 'flex', flexDirection: 'column', gap: 26}}>
				{ROWS.map((row, i) => {
					const start = 12 + i * 11;
					const p = interpolate(frame, [start + 6, start + 6 + FILL], [0, row.stop], {
						extrapolateLeft: 'clamp',
						extrapolateRight: 'clamp',
						easing: Easing.out(Easing.quad),
					});
					const failed = frame >= start + 6 + FILL;
					return (
						<Enter key={row.title} delay={start}>
							<div
								style={{
									background: C.surface,
									border: `1px solid ${failed ? 'rgba(255,95,87,0.45)' : C.line}`,
									borderRadius: 22,
									padding: '26px 30px 28px',
								}}
							>
								<div style={{display: 'flex', alignItems: 'baseline', justifyContent: 'space-between'}}>
									<div>
										<div style={{fontFamily: MONO, fontSize: 30, color: C.text}}>{row.title}</div>
										<div style={{fontFamily: SANS, fontSize: 23, color: C.muted, marginTop: 4}}>{row.sub}</div>
									</div>
									<div
										style={{
											fontFamily: SANS,
											fontSize: 27,
											fontWeight: 650,
											color: C.danger,
											opacity: failed ? 1 : 0,
										}}
									>
										{row.fail}
									</div>
								</div>
								<div style={{height: 10, borderRadius: 5, background: 'rgba(255,255,255,0.07)', marginTop: 18}}>
									<div
										style={{
											width: `${p * 100}%`,
											height: '100%',
											borderRadius: 5,
											background: failed ? C.danger : C.accent,
										}}
									/>
								</div>
							</div>
						</Enter>
					);
				})}
			</div>
		</AbsoluteFill>
	);
};
