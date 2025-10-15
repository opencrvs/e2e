import fs from "fs";
import path from "path";
import { log } from './logger'
/**
 * Replace placeholders in file content.
 * Customize the replacements map to your needs.
 */
function replacePlaceholders(content: string, replacements: Record<string, string>): string {
  let updated = content;
  for (const [key, value] of Object.entries(replacements)) {
    const regex = new RegExp(`\\{\\{${key}\\}\\}`, "g"); // matches ${KEY}
    updated = updated.replace(regex, value);
  }
  return updated;
}

/**
 * Copy charts-values directory into environments/<env>
 * @param env Environment name
 * Usage: copyChartsValues('dev')
 */
/**
 * Recursively copy a directory and replace placeholders in text files.
 */
export function copyChartsValues(env: string, replacements: Record<string, string>) {
  const srcDir = path.resolve(__dirname, "templates", "charts-values");
  const destDir = path.resolve(__dirname, "..", "..", "environments", env);
  fs.mkdirSync(destDir, { recursive: true });

  function copyRecursive(src: string, dest: string) {
    const stat = fs.statSync(src);

    if (stat.isDirectory()) {
      fs.mkdirSync(dest, { recursive: true });
      for (const item of fs.readdirSync(src)) {
        copyRecursive(path.join(src, item), path.join(dest, item));
      }
    } else {
      if (fs.existsSync(dest)) {
        log(`⚠️ Skipping existing file: ${dest}`);
        return;
      }
      // read file
      const content = fs.readFileSync(src, "utf8");

      // replace placeholders
      const updated = replacePlaceholders(content, replacements);

      // write updated file
      fs.writeFileSync(dest, updated, "utf8");
      log(`✅ Created: ${dest}`);
    }
  }

  copyRecursive(srcDir, destDir);
}

/**
 * Generate Ansible inventory file from template
 * @param env Environment name
 * @param number_of_servers Number of servers (1 for single-node, >1 for multi-node)
 * @param values Key-value pairs to replace in the template
 * Usage: generateInventory('dev', 1, {
 * HOST: process.env.APP_HOST || "localhost",
 * USER: process.env.SSH_USER || "ubuntu",
 * PORT: process.env.SSH_PORT || "22"
 * });
 */
export function generateInventory(env: string, number_of_servers: number, values: Record<string, string>){
  const env_type_template = number_of_servers > 1 ? "multi-node" : "single-node";
  const templatePath = path.join(__dirname, "templates", "inventory", `${env_type_template}.yml`);
  const outputPath = path.join(__dirname, "..", "server-setup", "inventory", `${env}.yml`);
  if (fs.existsSync(outputPath)) {
    log(`⚠️ Skipping ${templatePath}, file already exists at ${outputPath}`);
    return;
  }
  let template = fs.readFileSync(templatePath, "utf-8");
  const updated = replacePlaceholders(template, values);

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, updated);
  log(`✅ Generated inventory file at ${outputPath}`);
}