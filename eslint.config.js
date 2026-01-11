// eslint.config.js
import eslintPluginImport from 'eslint-plugin-import';
import eslintPluginPrettier from 'eslint-plugin-prettier';

export default [
  {
    // Specify which files this config applies to
    files: ['**/*.js'],

    // Language options replace "env"
    languageOptions: {
      parserOptions: {
        ecmaVersion: 2021,
        sourceType: 'module',
      },
      globals: {
        // Globals for Node, browser, Jest
        process: 'readonly',
        module: 'readonly',
        require: 'readonly',
        __dirname: 'readonly',
        console: 'readonly',
        jest: 'readonly',
      },
    },

    // Plugins
    plugins: {
      import: eslintPluginImport,
      prettier: eslintPluginPrettier,
    },

    // Rules
    rules: {
      'no-console': 'warn',
      semi: ['error', 'always'],
      'prettier/prettier': 'error',
      'import/no-unresolved': 'error',
      'import/order': ['warn', { alphabetize: { order: 'asc' } }],
    },
  },
];
