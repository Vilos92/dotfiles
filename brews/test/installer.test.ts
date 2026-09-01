import {expect, test} from 'bun:test';

import {executePlan} from '../src/installer.ts';
import type {CommandRunner} from '../src/inventory.ts';

const updateCommand =
  "curl --proto '=https' --tlsv1.2 -fsSL https://github.com/Vilos92/MilkTea/releases/latest/download/install.sh | sh -s -- update";

test('runs the MilkTea installer in update mode', async () => {
  const calls: string[][] = [];
  const runner: CommandRunner = {
    async run(argv) {
      calls.push(argv);
      return {exitCode: 0, stdout: '', stderr: ''};
    }
  };

  const results = await executePlan(new Map([['milktea', 'update']]), runner);

  expect(calls).toEqual([['/usr/bin/env', 'bash', '-lc', updateCommand]]);
  expect(results).toEqual([{id: 'milktea', action: 'update', exitCode: 0, stderr: ''}]);
});
