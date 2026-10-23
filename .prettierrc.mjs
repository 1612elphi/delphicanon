export default {
	plugins: ['prettier-plugin-ember-template-tag'],
	useTabs: true,
	tabWidth: 8,
	overrides: [
		{
			files: '*.{js,gjs,ts,gts,mjs,mts,cjs,cts}',
			options: {
				singleQuote: true,
				templateSingleQuote: false,
			},
		},
	],
};
