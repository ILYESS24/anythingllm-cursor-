#!/usr/bin/env node

/**
 * Script to update vulnerable dependencies
 * This script updates packages to their latest secure versions
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function updatePackageJson(packagePath, updates) {
  const packageJsonPath = path.join(packagePath, 'package.json');
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
  
  let updated = false;
  
  // Update dependencies
  if (packageJson.dependencies) {
    for (const [pkg, version] of Object.entries(updates.dependencies || {})) {
      if (packageJson.dependencies[pkg]) {
        packageJson.dependencies[pkg] = version;
        updated = true;
        log(`Updated ${pkg} to ${version} in dependencies`, 'green');
      }
    }
  }
  
  // Update devDependencies
  if (packageJson.devDependencies) {
    for (const [pkg, version] of Object.entries(updates.devDependencies || {})) {
      if (packageJson.devDependencies[pkg]) {
        packageJson.devDependencies[pkg] = version;
        updated = true;
        log(`Updated ${pkg} to ${version} in devDependencies`, 'green');
      }
    }
  }
  
  if (updated) {
    fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2) + '\n');
    log(`Updated package.json in ${packagePath}`, 'blue');
  }
  
  return updated;
}

function runCommand(command, cwd) {
  try {
    execSync(command, { 
      cwd, 
      stdio: 'inherit',
      encoding: 'utf8'
    });
    return true;
  } catch (error) {
    log(`Error running command: ${command}`, 'red');
    log(error.message, 'red');
    return false;
  }
}

// Critical security updates
const securityUpdates = {
  // Root package updates
  root: {
    devDependencies: {
      'jest': '^29.7.0',
      'concurrently': '^9.1.2'
    }
  },
  
  // Server package updates
  server: {
    dependencies: {
      'body-parser': '^1.20.3',
      'express': '^4.19.2',
      'langchain': '^0.2.19',
      'openai': '^4.95.1',
      'form-data': '^4.0.4'
    },
    devDependencies: {
      'jest': '^29.7.0',
      'prettier': '^3.0.3'
    }
  },
  
  // Frontend package updates
  frontend: {
    dependencies: {
      'vite': '^5.4.21'
    },
    devDependencies: {
      'vite': '^5.4.21',
      'esbuild': '^0.25.0',
      'rollup': '^3.29.5',
      'micromatch': '^4.0.8',
      'nanoid': '^3.3.8',
      'jest': '^29.7.0',
      'prettier': '^3.0.3'
    }
  },
  
  // Collector package updates
  collector: {
    dependencies: {
      'body-parser': '^1.20.3',
      'express': '^4.19.2',
      'langchain': '^0.2.19',
      'mammoth': '^1.11.0',
      'nodemailer': '^7.0.7'
    },
    devDependencies: {
      'jest': '^29.7.0',
      'prettier': '^3.0.3'
    }
  }
};

async function main() {
  log('🔒 Starting security dependency updates...', 'blue');
  
  const packages = [
    { path: '.', name: 'root' },
    { path: './server', name: 'server' },
    { path: './frontend', name: 'frontend' },
    { path: './collector', name: 'collector' }
  ];
  
  for (const pkg of packages) {
    log(`\n📦 Updating ${pkg.name} package...`, 'yellow');
    
    if (updatePackageJson(pkg.path, securityUpdates[pkg.name] || {})) {
      // Install updated dependencies
      log(`Installing updated dependencies for ${pkg.name}...`, 'blue');
      if (runCommand('yarn install --frozen-lockfile', pkg.path)) {
        log(`✅ Successfully updated ${pkg.name}`, 'green');
      } else {
        log(`❌ Failed to install dependencies for ${pkg.name}`, 'red');
      }
    } else {
      log(`No updates needed for ${pkg.name}`, 'yellow');
    }
  }
  
  log('\n🔍 Running security audit...', 'blue');
  
  // Run security audit
  for (const pkg of packages) {
    log(`\nAuditing ${pkg.name}...`, 'yellow');
    runCommand('yarn audit --level moderate', pkg.path);
  }
  
  log('\n✅ Security updates completed!', 'green');
  log('Please review the changes and test thoroughly before deploying.', 'yellow');
}

main().catch(error => {
  log(`❌ Error: ${error.message}`, 'red');
  process.exit(1);
});
