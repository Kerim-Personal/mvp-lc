const globals = require('globals');
const js = require('@eslint/js');
const googleConfig = require('eslint-config-google');

module.exports = [
  js.configs.recommended,
  googleConfig,
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
    },
  },
  {
    rules: {
      'max-len': 'off',
    },
  },
];
