export default {
  testEnvironment: 'node',
  roots: ['<rootDir>/server', '<rootDir>/frontend', '<rootDir>/collector'],
  testMatch: [
    '**/__tests__/**/*.+(ts|tsx|js)',
    '**/*.(test|spec).+(ts|tsx|js)'
  ],
  transform: {
    '^.+\\.(ts|tsx)$': 'ts-jest',
    '^.+\\.(js|jsx)$': 'babel-jest'
  },
  collectCoverageFrom: [
    'server/**/*.{js,ts}',
    'frontend/src/**/*.{js,ts,tsx}',
    'collector/**/*.{js,ts}',
    '!**/*.d.ts',
    '!**/node_modules/**',
    '!**/dist/**',
    '!**/build/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/frontend/src/$1',
    '^@server/(.*)$': '<rootDir>/server/$1',
    '^@collector/(.*)$': '<rootDir>/collector/$1'
  },
  testTimeout: 30000,
  verbose: true,
  extensionsToTreatAsEsm: ['.ts'],
  globals: {
    'ts-jest': {
      useESM: true
    }
  }
};
