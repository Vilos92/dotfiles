import {describe, expect, test} from 'bun:test';

import {catalog, packageById} from '../src/catalog.ts';
import {
  availableActions,
  defaultAction,
  isRequiredByPlan,
  setAction,
  toggleDefaultAction,
  toggleGroupDefaults,
  validateCatalog
} from '../src/planner.ts';
import type {Inventory, Plan} from '../src/types.ts';

const inventory = (
  overrides: Record<string, 'missing' | 'installed' | 'outdated' | 'unknown'> = {}
): Inventory =>
  new Map(
    packageById()
      .keys()
      .map(id => [id, overrides[id] ?? 'missing'])
  );

describe('catalog', () => {
  test('has valid package IDs and prerequisites', () => {
    expect(() => validateCatalog(catalog)).not.toThrow();
  });

  test('classifies the Meslo Nerd Font as a cask', () => {
    const font = packageById().get('font-meslo-lg-nerd-font')!;
    expect(font.action).toEqual({kind: 'brew', brewKind: 'cask', token: 'font-meslo-lg-nerd-font'});
  });
});

describe('planner', () => {
  test('chooses install for missing Brew packages and update for outdated ones', () => {
    const fd = packageById().get('fd')!;
    expect(defaultAction(fd, 'missing')).toBe('install');
    expect(defaultAction(fd, 'outdated')).toBe('update');
    expect(defaultAction(fd, 'installed')).toBeUndefined();
  });

  test('keeps non-Brew packages install-only even when detected', () => {
    const dex = packageById().get('dex')!;
    expect(defaultAction(dex, 'installed')).toBe('install');
    expect(availableActions(dex, 'installed')).toEqual(['install']);
  });

  test('selecting an action includes missing prerequisites', () => {
    const packages = packageById();
    const plan: Plan = new Map();
    const states = inventory({dex: 'missing', bun: 'missing'});

    setAction(plan, packages.get('dex')!, 'install', states);

    expect(plan).toEqual(
      new Map([
        ['dex', 'install'],
        ['bun', 'install']
      ])
    );
  });

  test('keeps a prerequisite selected while a planned package requires it', () => {
    const packages = packageById();
    const plan: Plan = new Map();
    const states = inventory({dex: 'missing', bun: 'missing'});

    setAction(plan, packages.get('dex')!, 'install', states);
    expect(isRequiredByPlan(plan, 'bun')).toBeTrue();

    toggleDefaultAction(plan, packages.get('bun')!, states);
    expect(plan.get('bun')).toBe('install');
  });

  test('marks only Brew packages as removable', () => {
    const packages = packageById();
    expect(availableActions(packages.get('fd')!, 'installed')).toEqual(['remove']);
    expect(availableActions(packages.get('fd')!, 'outdated')).toEqual(['update', 'remove']);
    expect(availableActions(packages.get('dex')!, 'installed')).not.toContain('remove');
  });

  test('toggles a group without selecting packages at startup', () => {
    const plan: Plan = new Map();
    const group = catalog.groups.find(candidate => candidate.id === 'dotfile-pkgs')!;
    const states = inventory({stow: 'missing'});

    expect(plan.size).toBe(0);
    toggleGroupDefaults(plan, group, states);
    expect(plan).toEqual(new Map([['stow', 'install']]));
    toggleGroupDefaults(plan, group, states);
    expect(plan.size).toBe(0);
  });
});
