import { resolve } from "node:path";

export async function scan(directory = import.meta.dir) {
  const workflow = Bun.YAML.parse(await Bun.file(resolve(import.meta.dir, "../../.github/workflows/packages-site.yml")).text());
  const reference = workflow.jobs.verify.steps.find((step: { id?: string }) => step.id === "secrets")?.uses;
  if (!/^docker:\/\/ghcr\.io\/gitleaks\/gitleaks:v\d+\.\d+\.\d+@sha256:[a-f0-9]{64}$/.test(reference)) {
    throw new Error("Missing immutable official Gitleaks workflow pin");
  }
  const process = Bun.spawn([
    "docker", "run", "--rm", "--network", "none", "--read-only", "--cap-drop", "ALL",
    "--security-opt", "no-new-privileges", "--mount", `type=bind,source=${resolve(directory)},target=/scan,readonly`,
    reference.slice("docker://".length), "dir", "--config", "/scan/.gitleaks.toml", "--redact=100", "--no-banner", "/scan",
  ], { stdout: "inherit", stderr: "inherit" });
  return process.exited;
}

if (import.meta.main) process.exit(await scan());
