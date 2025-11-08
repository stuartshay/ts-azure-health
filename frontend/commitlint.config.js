export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat', // New feature
        'fix', // Bug fix
        'docs', // Documentation
        'style', // Formatting
        'refactor', // Code refactoring
        'perf', // Performance
        'test', // Tests
        'build', // Build system
        'ci', // CI/CD
        'chore', // Maintenance
        'revert', // Revert commit
        'infra', // Infrastructure (Bicep)
      ],
    ],
    'subject-case': [2, 'never', ['upper-case']],
  },
};
