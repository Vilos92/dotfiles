import {expect, test} from 'bun:test';

const runCli = async (args: string[]) => {
  const process = Bun.spawn(['bun', 'src/main.ts', ...args], {stdout: 'pipe', stderr: 'pipe'});
  const [exitCode, stdout, stderr] = await Promise.all([
    process.exited,
    new Response(process.stdout).text(),
    new Response(process.stderr).text()
  ]);
  return {exitCode, stdout, stderr};
};

test('reports a missing dry-run selection without a stack trace', async () => {
  const result = await runCli(['--dry-run']);

  expect(result.exitCode).toBe(1);
  expect(result.stdout).toBe('');
  expect(result.stderr).toBe('--dry-run requires at least one package or group ID\n');
});

test('reports an unknown dry-run selection without starting an inventory scan', async () => {
  const result = await runCli(['--dry-run', 'not-a-package']);

  expect(result.exitCode).toBe(1);
  expect(result.stdout).toBe('');
  expect(result.stderr).toBe('Unknown package or group: not-a-package\n');
});
