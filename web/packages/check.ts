const commands = [
  ["bun", "test", "tests/packages/source.test.ts", "tests/packages/delivery.test.ts"],
  ["bun", "web/packages/verify.ts"],
  ["bun", "web/packages/scan.ts"],
  ["bun", "web/packages/scanner-check.ts"],
  ["bun", "web/packages/restoration-check.ts"],
  ["bun", "run", "packages:browser"],
];
for (const command of commands) {
  const child = Bun.spawn(command, { stdout: "inherit", stderr: "inherit", env: process.env });
  const code = await child.exited;
  if (code !== 0) process.exit(code);
}
