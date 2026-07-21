import js from '@eslint/js';

export default [
  js.configs.recommended,
  {
    files: ['**/*.js'],
    languageOptions: { ecmaVersion: 2024, sourceType: 'module', globals: { process: 'readonly', TextEncoder: 'readonly' } },
    rules: { 'no-console': 'error', 'no-unused-vars': ['error', { argsIgnorePattern: '^_' }] }
  }
];
