import * as fs from 'fs';
import * as path from 'path';

import kleur from 'kleur'
import { select } from '@inquirer/prompts'
import { manageUsers } from './manage-users'


/**
 * Allow user to select inventory file (environment from a list)
 * 
 * @param {string} dirPath - Path to the inventory file
 * 
 * * @returns {string} Inventory file
 */
async function selectInventoryFile(
  dirPath: string = './infrastructure/server-setup/inventory/'
): Promise<string> {
  // Check if directory exists
  if (!fs.existsSync(dirPath)) {
    throw Error(`Directory ${dirPath} doesn't exist`)
  }

  // Read and filter files
  const files = fs.readdirSync(dirPath)
    .filter(file => {
      const filePath = path.join(dirPath, file);
      const isFile = fs.statSync(filePath).isFile();
      const ext = path.extname(file).slice(1).toLowerCase();
      return isFile && (ext === 'yml' || ext === 'yaml');
    })
    .sort();

  if (files.length === 0) {
    throw Error(`No environment configuration files found at ${dirPath}`)
  }

  // Create choices - remove extension from display
  const choices = files.map(file => ({
    name: path.basename(file, path.extname(file)),
    value: path.join(dirPath, file)
  }));

  const selectedFile = await select({
    message: 'Select environment (inventory file) to load users:',
    choices: choices
  });

  return selectedFile;
}

async function manageUsersStandalone(){
  console.log('\n', kleur.bold().underline("Manage users"), '\n')
  const inventory_file = await selectInventoryFile();
  manageUsers(inventory_file)
}

manageUsersStandalone()
