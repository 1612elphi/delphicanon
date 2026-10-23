import js from '@eslint/js';
import ts from 'typescript-eslint';

export default ts.config(
	{ ignores: ['.build/', 'public/'] },
	js.configs.recommended,
	...ts.configs.recommended,
);
