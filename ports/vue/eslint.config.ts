import pluginVue from 'eslint-plugin-vue';
import {
	defineConfigWithVueTs,
	vueTsConfigs,
} from '@vue/eslint-config-typescript';
import skipFormatting from '@vue/eslint-config-prettier/skip-formatting';

export default defineConfigWithVueTs(
	{ ignores: ['dist/', 'node_modules/'] },
	pluginVue.configs['flat/recommended'],
	vueTsConfigs.recommended,
	{
		// optional typed props are undefined by design, as the Ember args are
		rules: { 'vue/require-default-prop': 'off' },
	},
	{
		// gallery file names mirror the Ember demo's
		files: ['demo/**/*.vue'],
		rules: { 'vue/multi-word-component-names': 'off' },
	},
	skipFormatting,
);
