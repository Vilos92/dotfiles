import {exists} from 'node:fs/promises';

import {allPackages, catalog} from './catalog.ts';
import type {BrewKind, Catalog, Inventory, PackageDefinition, PackageStatus} from './types.ts';

export type CommandResult = {
  exitCode: number;
  stdout: string;
  stderr: string;
};

export interface CommandRunner {
  run(argv: string[]): Promise<CommandResult>;
}

type InventoryOptions = {
  catalog?: Catalog;
  pathExists?: (path: string) => Promise<boolean>;
  platform?: string;
};

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

const parseVersion = (raw: string): [number, number, number] | null => {
  const match = /^v?(\d+)\.(\d+)\.(\d+)$/.exec(raw.trim());
  if (!match) return null;
  return [Number(match[1]), Number(match[2]), Number(match[3])];
};

const compareVersions = (installed: [number, number, number], latest: [number, number, number]): number => {
  for (let index = 0; index < installed.length; index++) {
    const difference = installed[index] - latest[index];
    if (difference !== 0) return difference;
  }
  return 0;
};

const readLatestReleaseVersion = async (
  repository: string,
  runner: CommandRunner
): Promise<[number, number, number] | null> => {
  const result = await runner.run([
    'curl',
    '--proto',
    '=https',
    '--tlsv1.2',
    '--fail',
    '--silent',
    '--show-error',
    '--location',
    '--output',
    '/dev/null',
    '--write-out',
    '%{url_effective}',
    `https://github.com/${repository}/releases/latest`
  ]);
  if (result.exitCode !== 0) return null;

  try {
    const tag = new URL(result.stdout.trim()).pathname.split('/').filter(Boolean).at(-1);
    return tag ? parseVersion(decodeURIComponent(tag)) : null;
  } catch {
    return null;
  }
};

const probeGithubReleaseMacosApp = async (
  pkg: PackageDefinition,
  runner: CommandRunner,
  options: Required<Pick<InventoryOptions, 'pathExists' | 'platform'>>
): Promise<PackageStatus> => {
  if (pkg.probe.kind !== 'github-release-macos-app') {
    throw new Error(`${pkg.id} does not use a GitHub release macOS app probe`);
  }
  if (options.platform !== 'darwin') return 'unknown';

  const appPath = expandHome(pkg.probe.path);
  if (!(await options.pathExists(appPath))) return 'missing';

  const installedResult = await runner.run([
    '/usr/libexec/PlistBuddy',
    '-c',
    'Print :CFBundleShortVersionString',
    `${appPath}/Contents/Info.plist`
  ]);
  if (installedResult.exitCode !== 0) return 'unknown';

  const installed = parseVersion(installedResult.stdout);
  const latest = await readLatestReleaseVersion(pkg.probe.repository, runner);
  if (!installed || !latest) return 'unknown';

  return compareVersions(installed, latest) < 0 ? 'outdated' : 'installed';
};

const probePackage = async (
  pkg: PackageDefinition,
  runner: CommandRunner,
  options: Required<Pick<InventoryOptions, 'pathExists' | 'platform'>>
): Promise<PackageStatus> => {
  switch (pkg.probe.kind) {
    case 'command':
      return Bun.which(pkg.probe.command) ? 'installed' : 'missing';
    case 'path':
      return (await options.pathExists(expandHome(pkg.probe.path))) ? 'installed' : 'missing';
    case 'github-release-macos-app':
      return probeGithubReleaseMacosApp(pkg, runner, options);
    case 'unknown':
      return 'unknown';
    case 'brew':
      return 'unknown';
  }
};

export const scanInventory = async (
  runner: CommandRunner = bunRunner,
  options: InventoryOptions = {}
): Promise<Inventory> => {
  const inventory: Inventory = new Map();
  const source = options.catalog ?? catalog;
  const probeOptions = {
    pathExists: options.pathExists ?? exists,
    platform: options.platform ?? process.platform
  };
  const formulae = await readBrewTokens(runner, 'formula', 'list');
  const casks = await readBrewTokens(runner, 'cask', 'list');
  const outdatedFormulae = formulae ? await readBrewTokens(runner, 'formula', 'outdated') : null;
  const outdatedCasks = casks ? await readBrewTokens(runner, 'cask', 'outdated') : null;

  for (const pkg of allPackages(source)) {
    if (pkg.probe.kind !== 'brew') {
      inventory.set(pkg.id, await probePackage(pkg, runner, probeOptions));
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
