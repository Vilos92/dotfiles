import {expect, test} from 'bun:test';
import {createTestRenderer} from '@opentui/core/testing';

import {runApp} from '../src/app.ts';
import {packageById} from '../src/catalog.ts';
import type {Inventory} from '../src/types.ts';

const missingInventory = (): Inventory =>
  new Map(Array.from(packageById().keys(), id => [id, 'missing'] as const));

test('renders the V92 header and plans a package only after keyboard selection', async () => {
  const setup = await createTestRenderer({width: 80, height: 30});
  const app = runApp(missingInventory(), setup.renderer);
  await Promise.resolve();
  await setup.renderOnce();

  expect(setup.captureCharFrame()).toContain('___ ____');
  expect(setup.captureCharFrame()).toContain('0 actions planned');

  await setup.mockInput.pressArrow('right');
  await setup.mockInput.pressArrow('down');
  await setup.mockInput.pressKey(' ');
  await setup.renderOnce();
  expect(setup.captureCharFrame()).toContain('1 install');

  await setup.mockInput.pressKey('q');
  await expect(app).resolves.toBeNull();
});

test('keeps the focused group visible in a short viewport', async () => {
  const setup = await createTestRenderer({width: 80, height: 16});
  const app = runApp(missingInventory(), setup.renderer);
  await Promise.resolve();

  for (let index = 0; index < 19; index++) {
    await setup.mockInput.pressArrow('down');
  }
  await setup.flush();

  expect(setup.captureCharFrame()).toContain('Offline and gaming');

  await setup.mockInput.pressKey('q');
  await expect(app).resolves.toBeNull();
});
