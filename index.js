#!/usr/bin/env node
const { program } = require('commander');
const fs = require('fs-extra');
const chalk = require('chalk');
const path = require('path');

const TEMPLATE_MAP = {
  crud:                'crudSlice.js.t',
  create:              'createApiSlice.js.t',
  token:               'tokenSlice.js.t',
  customheader:        'customHeaderSlice.js.t',
  secretkey:           'secretKeySlice.js.t',
  infinite:            'infiniteSlice.js.t',
  search:              'searchSlice.js.t',
  upload:              'uploadSlice.js.t',
  polling:             'pollingSlice.js.t',
  analytics:           'analyticsSlice.js.t',
  optimistic:          'optimisticSlice.js.t',
  cache:               'cacheSlice.js.t',
  debounce:            'debounceSlice.js.t',
  retry:               'retrySlice.js.t',
  rollback:            'rollbackSlice.js.t',
  tokenrefresh:        'tokenRefreshSlice.js.t',
  offline:             'offlineSlice.js.t',
  prefetch:            'prefetchSlice.js.t',
  batch:               'batchSlice.js.t',
  dedupe:              'dedupeSlice.js.t',
  websocket:           'websocketSlice.js.t',
  stream:              'streamSlice.js.t',
  abort:               'abortSlice.js.t',
  encrypt:             'encryptSlice.js.t',
  heartbeat:           'heartbeatSlice.js.t',
  focusrevalidation:   'focusRevalidationSlice.js.t',
  circuitbreaker:      'circuitBreakerSlice.js.t',
  gracefuldegradation: 'gracefulDegradationSlice.js.t',
  sessionidle:         'sessionIdleSlice.js.t',
  mfa:                 'mfaSlice.js.t',
  predictivescroll:    'predictiveScrollSlice.js.t',
};

async function generateSlice(name, type, apiUrl) {
  const lowerName = name.charAt(0).toLowerCase() + name.slice(1);
  const capitalName = name.charAt(0).toUpperCase() + name.slice(1);

  const templateFileName = TEMPLATE_MAP[type];
  const templatePath = path.join(__dirname, 'templates', templateFileName);
  const sliceFileName = type === 'auth' ? 'authSlice.js' : `${lowerName}Slice.js`;
  const storeDir = path.join(process.cwd(), 'src', 'store');
  const sliceOutputPath = path.join(storeDir, sliceFileName);
  const reactStoreFile = path.join(storeDir, 'store.js');

  if (!await fs.pathExists(templatePath)) {
    throw new Error(`Template not found: ${templatePath}`);
  }

  let sliceTemplate = await fs.readFile(templatePath, 'utf8');
  sliceTemplate = sliceTemplate
    .replace(/{{Name}}/g, capitalName)
    .replace(/{{lowerName}}/g, lowerName)
    .replace(/{{apiUrl}}/g, apiUrl);

  await fs.outputFile(sliceOutputPath, sliceTemplate);
  console.log(chalk.green(`✔ Slice generated [${type}]: src/store/${sliceFileName}`));

  const reducerKey = type === 'auth' ? 'auth' : lowerName;
  const reducerVar = type === 'auth' ? 'authReducer' : `${lowerName}Reducer`;
  const importLine = `import ${reducerVar} from './${sliceFileName}';`;

  let storeContent;
  if (await fs.pathExists(reactStoreFile)) {
    storeContent = await fs.readFile(reactStoreFile, 'utf8');
    if (!storeContent.includes(importLine)) {
      storeContent = importLine + '\n' + storeContent;
    }
    if (storeContent.includes('reducer: {') && !storeContent.includes(`${reducerKey}: ${reducerVar}`)) {
      storeContent = storeContent.replace(
        /reducer:\s*\{([^}]*)\}/s,
        (_, inner) => {
          const lines = inner.trim().split('\n').map(l => '    ' + l.trim()).filter(l => l.trim());
          const existing = lines.length ? lines.join('\n') + '\n' : '';
          return `reducer: {\n${existing}    ${reducerKey}: ${reducerVar},\n  }`;
        }
      );
    }
  } else {
    storeContent = `${importLine}\nimport { configureStore } from '@reduxjs/toolkit';\n\nexport const store = configureStore({\n  reducer: {\n    ${reducerKey}: ${reducerVar},\n  },\n});\n`;
  }

  await fs.outputFile(reactStoreFile, storeContent);
  console.log(chalk.blue(`✔ Store updated: src/store/store.js`));
}

// ─── Register make:<type> commands for all template types ────────────────────

for (const type of Object.keys(TEMPLATE_MAP)) {
  program
    .command(`make:${type} <name>`)
    .description(`Create a Redux "${type}" API slice`)
    .option('-u, --url <url>', 'API base URL', 'https://your-api-url.com')
    .action(async (name, options) => {
      try {
        await generateSlice(name, type, options.url);
        console.log(chalk.bold.magenta('\n🚀 Done!'));
      } catch (err) {
        console.error(chalk.red('Error:'), err.message);
        process.exit(1);
      }
    });
}

// ─── make:auth command ───────────────────────────────────────────────────────

const AUTH_TYPES = ['login', 'register', 'logout', 'all'];

const AUTH_TEMPLATE_MAP = {
  login:    { template: 'loginSlice.js.t',    file: 'loginSlice.js',    key: 'login',    var: 'loginReducer' },
  register: { template: 'registerSlice.js.t', file: 'registerSlice.js', key: 'register', var: 'registerReducer' },
  logout:   { template: 'logoutSlice.js.t',   file: 'logoutSlice.js',   key: 'logout',   var: 'logoutReducer' },
};

async function generateAuthSlice(type, apiUrl) {
  const { template, file, key, var: reducerVar } = AUTH_TEMPLATE_MAP[type];
  const templatePath = path.join(__dirname, 'templates', template);
  const storeDir = path.join(process.cwd(), 'src', 'store');
  const sliceOutputPath = path.join(storeDir, file);
  const reactStoreFile = path.join(storeDir, 'store.js');

  if (!await fs.pathExists(templatePath)) {
    throw new Error(`Template not found: ${templatePath}`);
  }

  let content = await fs.readFile(templatePath, 'utf8');
  content = content.replace(/{{apiUrl}}/g, apiUrl);

  await fs.outputFile(sliceOutputPath, content);
  console.log(chalk.green(`✔ Slice generated: src/store/${file}`));

  const importLine = `import ${reducerVar} from './${file}';`;

  let storeContent;
  if (await fs.pathExists(reactStoreFile)) {
    storeContent = await fs.readFile(reactStoreFile, 'utf8');
    if (!storeContent.includes(importLine)) {
      storeContent = importLine + '\n' + storeContent;
    }
    if (storeContent.includes('reducer: {') && !storeContent.includes(`${key}: ${reducerVar}`)) {
      storeContent = storeContent.replace(
        /reducer:\s*\{([^}]*)\}/s,
        (_, inner) => {
          const lines = inner.trim().split('\n').map(l => '    ' + l.trim()).filter(l => l.trim());
          const existing = lines.length ? lines.join('\n') + '\n' : '';
          return `reducer: {\n${existing}    ${key}: ${reducerVar},\n  }`;
        }
      );
    }
  } else {
    storeContent = `${importLine}\nimport { configureStore } from '@reduxjs/toolkit';\n\nexport const store = configureStore({\n  reducer: {\n    ${key}: ${reducerVar},\n  },\n});\n`;
  }

  await fs.outputFile(reactStoreFile, storeContent);
  console.log(chalk.blue(`✔ Store updated: src/store/store.js`));
}

program
  .command('make:auth <type>')
  .description(`Create auth slice(s). Types: ${AUTH_TYPES.join(', ')}`)
  .option('-u, --url <url>', 'API base URL', 'https://your-api-url.com')
  .action(async (type, options) => {
    const selectedType = type.toLowerCase();

    if (!AUTH_TYPES.includes(selectedType)) {
      console.error(chalk.red(`Unknown type "${selectedType}". Valid types: ${AUTH_TYPES.join(', ')}`));
      process.exit(1);
    }

    try {
      const types = selectedType === 'all' ? ['login', 'register', 'logout'] : [selectedType];
      for (const t of types) {
        await generateAuthSlice(t, options.url);
      }
      console.log(chalk.bold.magenta('\n🚀 Done!'));
    } catch (err) {
      console.error(chalk.red('Error:'), err.message);
      process.exit(1);
    }
  });

program.parse(process.argv);
