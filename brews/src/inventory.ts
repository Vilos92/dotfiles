import {exists} from 'node:fs/promises';

import {allPackages} from './catalog.ts';
import type {BrewKind, Inventory, PackageDefinition, PackageStatus} from './types.ts';

export type CommandResult = {
  exitCode: number;
  stdout: string;
  stderr: string;
};

export interface CommandRunner {
  run(argv: string[]): Promise<CommandResult>;
}

export const bunRunner: CommandRunner = {
  async run(argv) {
    const process = Bun.spawn(argv, {stdout: 'pipe', stderr: 'pipe'});
    const [exitCode, stdout, stderr] = await Promise.all([
      process.exited,
      new Response(process.stdout).text(),
      new Response(process.stderr).text()
    ]);
    return {exitCode, stdout, stderr};
  }
};

const brewToken = (pkg: PackageDefinition): string => {
  if (pkg.action.kind !== 'brew') throw new Error(`${pkg.id} is not a Brew package`);
  return pkg.action.token.split('/').at(-1) ?? pkg.action.token;
};

const readBrewTokens = async (
  runner: CommandRunner,
  brewKind: BrewKind,
  command: 'list' | 'outdated'
): Promise<Set<string> | null> => {
  const result = await runner.run(['brew', command, `--${brewKind}`]);
  if (result.exitCode !== 0) return null;

  return new Set(
    result.stdout
      .split('\n')
      .map(line => line.trim().split(/\s+/)[0])
      .filter(Boolean)
  );
};

const expandHome = (path: string): string => path.replace(/^\$HOME/, process.env.HOME ?? '');

const probePackage = async (pkg: PackageDefinition): Promise<PackageStatus> => {
  switch (pkg.probe.kind) {
    case 'command':
      return Bun.which(pkg.probe.command) ? 'installed' : 'missing';
    case 'path':
      return (await exists(expandHome(pkg.probe.path))) ? 'installed' : 'missing';
    case 'unknown':
      return 'unknown';
    case 'brew':
      return 'unknown';
  }
};

export const scanInventory = async (runner: CommandRunner = bunRunner): Promise<Inventory> => {
  const inventory: Inventory = new Map();
  const formulae = await readBrewTokens(runner, 'formula', 'list');
  const casks = await readBrewTokens(runner, 'cask', 'list');
  const outdatedFormulae = formulae ? await readBrewTokens(runner, 'formula', 'outdated') : null;
  const outdatedCasks = casks ? await readBrewTokens(runner, 'cask', 'outdated') : null;

  for (const pkg of allPackages()) {
    if (pkg.probe.kind !== 'brew') {
      inventory.set(pkg.id, await probePackage(pkg));
      continue;
    }

    const installed = pkg.probe.brewKind === 'formula' ? formulae : casks;
    const outdated = pkg.probe.brewKind === 'formula' ? outdatedFormulae : outdatedCasks;
    if (!installed) {
      inventory.set(pkg.id, 'unknown');
    } else if (outdated?.has(brewToken(pkg))) {
      inventory.set(pkg.id, 'outdated');
    } else {
      inventory.set(pkg.id, installed.has(brewToken(pkg)) ? 'installed' : 'missing');
    }
  }

  return inventory;
};
