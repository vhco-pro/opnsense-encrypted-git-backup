import { expect, test } from "bun:test";
import { verifySite } from "../../web/packages/smoke";
import { verifySource } from "../../web/packages/verify";

// The browser fixture and its local HTTP checks use native Wrangler.
// Source restoration integration runs through the aggregate verification command.
test("only the reviewed public assets pass source verification", async () => {
  await verifySource();
});

test("the public checker accepts loopback fixtures and rejects unrelated hosts", async () => {
  await expect(verifySite("https://example.invalid", { timeoutMs: 0 })).rejects.toThrow("site URL");
});

test("the official pipeline isolates publication from package releases", async () => {
  const workflow = Bun.YAML.parse(await Bun.file(".github/workflows/packages-site.yml").text());
  expect(workflow.permissions).toEqual({ contents: "read" });
  expect(workflow.concurrency).toBeUndefined();
  expect(workflow.jobs.deploy.needs).toBe("verify");
  expect(workflow.jobs.deploy.if).toBe("github.ref == 'refs/heads/main' && github.event_name != 'pull_request' && vars.PACKAGES_SITE_PUBLISH_ENABLED == 'true'");
  expect(JSON.stringify(workflow.jobs.verify)).not.toContain("secrets.");
  expect(JSON.stringify(workflow.jobs.verify)).not.toContain("vars.CLOUDFLARE");
  expect(workflow.jobs.verify.concurrency).toEqual({
    group: "${{ format('packages-site-verify-{0}', github.event.pull_request.number || github.ref) }}",
    "cancel-in-progress": true,
  });
  expect(workflow.jobs.deploy.environment).toBe("packages-site-production");
  expect(workflow.jobs.deploy.concurrency).toEqual({
    group: "vhco-packages-site-production",
    "cancel-in-progress": false,
  });
  const deployAction = workflow.jobs.deploy.steps.find((step) => step.uses?.startsWith("cloudflare/wrangler-action@"));
  expect(Object.keys(deployAction.with).sort()).toEqual(["accountId", "apiToken", "command", "packageManager"]);
  expect(deployAction.with.apiToken).toBe("${{ secrets.CLOUDFLARE_API_TOKEN }}");
  expect(deployAction.with.accountId).toBe("${{ vars.CLOUDFLARE_ACCOUNT_ID }}");
  expect(deployAction.with.packageManager).toBe("bun");
  expect(deployAction.with.command).toContain("versions upload --config web/packages/wrangler.toml");
  expect(deployAction.with.command).toContain("versions deploy --config web/packages/wrangler.toml");
  expect(JSON.stringify(workflow.jobs.deploy)).not.toContain("git tag");
  expect(JSON.stringify(workflow.jobs.deploy)).not.toContain("gh release");
  expect(workflow.jobs.verify.steps.find((step) => step.id === "secrets").uses).toMatch(/^docker:\/\/ghcr.io\/gitleaks\/gitleaks:v[\d.]+@sha256:[a-f0-9]{64}$/);
});
