import {expect, test} from 'bun:test';

import {scanInventory, type CommandResult, type CommandRunner} from '../src/inventory.ts';
import type {Catalog} from '../src/types.ts';

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

const milkTeaCatalog = (path: string): Catalog => ({
  groups: [
    {
      id: 'media',
      label: 'Media',
      packages: [
        {
          id: 'milktea',
          label: 'MilkTea',
          description: 'MilkDrop music visualizer',
          action: {
            kind: 'managed-shell',
            installCommand: 'install MilkTea',
            updateCommand: 'update MilkTea'
          },
          probe: {kind: 'github-release-macos-app', repository: 'Vilos92/MilkTea', path}
        }
      ]
    }
  ]
});

const versionRunner = (installed: string, latest: string): CommandRunner => ({
  async run(argv): Promise<CommandResult> {
    if (argv[0] === '/usr/libexec/PlistBuddy') {
      return {exitCode: 0, stdout: `${installed}\n`, stderr: ''};
    }
    if (argv[0] === 'curl') {
      return {
        exitCode: 0,
        stdout: `https://github.com/Vilos92/MilkTea/releases/tag/v${latest}`,
        stderr: ''
      };
    }
    return {exitCode: 0, stdout: '', stderr: ''};
  }
});

test('detects missing, current, outdated, and newer MilkTea installations', async () => {
  const path = '/tmp/MilkTea.app';
  const options = {
    catalog: milkTeaCatalog(path),
    pathExists: async () => true,
    platform: 'darwin'
  };

  const missing = await scanInventory(versionRunner('0.1.0', '0.1.0'), {
    ...options,
    pathExists: async () => false
  });
  const current = await scanInventory(versionRunner('0.1.0', '0.1.0'), options);
  const outdated = await scanInventory(versionRunner('0.1.0', '0.2.0'), options);
  const newer = await scanInventory(versionRunner('0.3.0', '0.2.0'), options);

  expect(missing.get('milktea')).toBe('missing');
  expect(current.get('milktea')).toBe('installed');
  expect(outdated.get('milktea')).toBe('outdated');
  expect(newer.get('milktea')).toBe('installed');
});
