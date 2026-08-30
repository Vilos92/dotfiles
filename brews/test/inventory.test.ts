import {expect, test} from 'bun:test';

import {scanInventory, type CommandRunner} from '../src/inventory.ts';

const runner: CommandRunner = {
  async run(argv) {
    const command = argv.join(' ');
    const output: Record<string, string> = {
      'brew list --formula': 'fd\nbun\n',
      'brew list --cask': 'openemu\n',
      'brew outdated --formula': 'fd (10.0 -> 11.0)\n',
      'brew outdated --cask': 'openemu (1.0 -> 2.0)\n'
    };
    return {exitCode: 0, stdout: output[command] ?? '', stderr: ''};
  }
};

test('detects missing, installed, and outdated Homebrew packages', async () => {
  const inventory = await scanInventory(runner);

  expect(inventory.get('fd')).toBe('outdated');
  expect(inventory.get('bun')).toBe('installed');
  expect(inventory.get('openemu')).toBe('outdated');
  expect(inventory.get('ripgrep')).toBe('missing');
});
