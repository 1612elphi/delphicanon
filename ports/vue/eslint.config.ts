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
    // gallery file names mirror the Ember demo's
    files: ['demo/**/*.vue'],
    rules: { 'vue/multi-word-component-names': 'off' },
  },
  skipFormatting,
);
