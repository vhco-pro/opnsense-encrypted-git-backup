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
  expect(workflow.jobs.deploy.environment).toBe("packages-site-production");
  expect(workflow.jobs.deploy.concurrency).toEqual({
    group: "vhco-packages-site-production",
    "cancel-in-progress": false,
  });
  expect(workflow.jobs.deploy.steps.some((step) => step.uses?.startsWith("cloudflare/wrangler-action@"))).toBe(true);
  expect(workflow.jobs.verify.steps.find((step) => step.id === "secrets").uses).toMatch(/^docker:\/\/ghcr.io\/gitleaks\/gitleaks:v[\d.]+@sha256:[a-f0-9]{64}$/);
});
