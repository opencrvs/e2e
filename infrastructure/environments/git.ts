import { execSync } from "child_process";

export function getRepoInfo() {

  const remoteUrl = execSync("git config --get remote.origin.url")
    .toString()
    .trim();

  // Handle both SSH and HTTPS formats
  const match = remoteUrl.match(/github\.com[:/](.+?)\/(.+?)(\.git)?$/);
  if (!match) {
    throw new Error("Not a GitHub repository or invalid remote URL");
  }

  return { organization: match[1], repository: match[2]}
}
