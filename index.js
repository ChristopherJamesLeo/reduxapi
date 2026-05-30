#!/usr/bin/env node
const { program } = require('commander');
const fs = require('fs-extra');
const chalk = require('chalk');
const path = require('path');

const TEMPLATE_MAP = {
  crud:   'crudSlice.js.t',
  create: 'createApiSlice.js.t',
  token:  'tokenSlice.js.t',
  auth:   'authSlice.js.t',
};

program
  .command('make:api <name>')
  .description('Create a Redux API slice from a template')
  .option('-t, --type <type>', `Template type: ${Object.keys(TEMPLATE_MAP).join(', ')}`, 'crud')
  .option('-u, --url <url>', 'API base URL (used by auth and token templates)', 'https://your-api-url.com')
  .action(async (name, options) => {
    const lowerName = name.charAt(0).toLowerCase() + name.slice(1);
    const capitalName = name.charAt(0).toUpperCase() + name.slice(1);
    const selectedType = options.type.toLowerCase();

    const templateFileName = TEMPLATE_MAP[selectedType];
    if (!templateFileName) {
      console.error(chalk.red(`Unknown type "${selectedType}". Valid types: ${Object.keys(TEMPLATE_MAP).join(', ')}`));
      process.exit(1);
    }

    const templatePath = path.join(__dirname, 'templates', templateFileName);
    const sliceFileName = selectedType === 'auth' ? 'authSlice.js' : `${lowerName}Slice.js`;
    const packageSlicePath = path.join(__dirname, 'slices', sliceFileName);
    const reactStoreFile = path.join(process.cwd(), 'src', 'store', 'store.js');

    try {
      if (!await fs.pathExists(templatePath)) {
        throw new Error(`Template not found: ${templatePath}`);
      }

      let sliceTemplate = await fs.readFile(templatePath, 'utf8');
      sliceTemplate = sliceTemplate
        .replace(/{{Name}}/g, capitalName)
        .replace(/{{lowerName}}/g, lowerName)
        .replace(/{{apiUrl}}/g, options.url);

      await fs.outputFile(packageSlicePath, sliceTemplate);
      console.log(chalk.green(`✔ Slice generated [${selectedType}]: slices/${sliceFileName}`));

      const packageJsonPath = path.join(__dirname, 'package.json');
      const packageName = (await fs.readJson(packageJsonPath)).name;

      const reducerKey = selectedType === 'auth' ? 'auth' : lowerName;
      const reducerVar = selectedType === 'auth' ? 'authReducer' : `${lowerName}Reducer`;
      const importLine = `import ${reducerVar} from '${packageName}/slices/${sliceFileName}';`;

      let storeContent;
      if (await fs.pathExists(reactStoreFile)) {
        storeContent = await fs.readFile(reactStoreFile, 'utf8');
        if (!storeContent.includes(importLine)) {
          storeContent = importLine + '\n' + storeContent;
        }
        if (storeContent.includes('reducer: {') && !storeContent.includes(`${reducerKey}: ${reducerVar}`)) {
          storeContent = storeContent.replace(
            /reducer: {/,
            `reducer: {\n    ${reducerKey}: ${reducerVar},`
          );
        }
      } else {
        storeContent = `${importLine}\nimport { configureStore } from '@reduxjs/toolkit';\n\nexport const store = configureStore({\n  reducer: {\n    ${reducerKey}: ${reducerVar},\n  },\n});\n`;
      }

      await fs.outputFile(reactStoreFile, storeContent);
      console.log(chalk.blue(`✔ Store updated: src/store/store.js`));
      console.log(chalk.bold.magenta('\n🚀 Done!'));

    } catch (err) {
      console.error(chalk.red('Error:'), err.message);
      process.exit(1);
    }
  });

program.parse(process.argv);
