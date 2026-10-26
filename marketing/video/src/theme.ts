// Brand tokens, taken from docs/index.html (the keepAwake website).
export const C = {
	bg: '#0b0c0f',
	surface: '#15171c',
	surface2: '#1d2027',
	text: '#f2f3f5',
	muted: '#a2a7b3',
	line: 'rgba(255, 255, 255, 0.08)',
	grid: 'rgba(120, 150, 255, 0.07)',
	accent: '#4f8cff',
	danger: '#ff5f57',
	ok: '#3ddc84',
	warn: '#ffbd2e',
};

export const SANS = '-apple-system, "SF Pro Display", "SF Pro Text", "Helvetica Neue", Arial, sans-serif';
export const MONO = '"SF Mono", ui-monospace, Menlo, Monaco, monospace';

export const FPS = 30;
export const WIDTH = 1080;
export const HEIGHT = 1350;
export const TRANSITION = 12;

// Scene lengths in frames, in playback order. Neighbouring scenes overlap by TRANSITION.
export const SCENES = {
	hook: 140,
	pain: 105,
	reveal: 100,
	timer: 200,
	agents: 230,
	features: 150,
	cta: 135,
};

export const TOTAL_FRAMES =
	Object.values(SCENES).reduce((sum, d) => sum + d, 0) - TRANSITION * (Object.keys(SCENES).length - 1);
