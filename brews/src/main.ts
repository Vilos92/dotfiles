import {runApp} from './app.ts';
import {allPackages, catalog} from './catalog.ts';
import {executePlan, describePlan} from './installer.ts';
import {bunRunner, scanInventory, type CommandResult, type CommandRunner} from './inventory.ts';
import {defaultAction, setAction, validateCatalog} from './planner.ts';
import type {Inventory, Plan} from './types.ts';

const liveRunner: CommandRunner = {
  async run(argv): Promise<CommandResult> {
    const process = Bun.spawn(argv, {stdout: 'inherit', stderr: 'inherit'});
    return {exitCode: await process.exited, stdout: '', stderr: ''};
  }
};

const usage = (): string => `Usage:
  bun run start
  bun run start -- --dry-run <package-or-group> [...package-or-group]

The interactive app starts with no actions selected.`;

const fail = (message: string): never => {
  console.error(message);
  process.exit(1);
};

const validateRequestedIds = (ids: string[]): void => {
  const packages = new Set(allPackages().map(pkg => pkg.id));
  const groups = new Set(catalog.groups.map(group => group.id));
  for (const id of ids) {
    if (!packages.has(id) && !groups.has(id)) fail(`Unknown package or group: ${id}`);
  }
};

const planDefaults = (ids: string[], inventory: Inventory): Plan => {
  const plan: Plan = new Map();
  const packages = new Map(allPackages().map(pkg => [pkg.id, pkg]));
  const groups = new Map(catalog.groups.map(group => [group.id, group]));

  for (const id of ids) {
    const selectedPackage = packages.get(id);
    const selected = selectedPackage
      ? [selectedPackage]
      : (groups.get(id)?.packages ?? fail(`Unknown package or group: ${id}`));
    for (const pkg of selected) {
      const action = defaultAction(pkg, inventory.get(pkg.id) ?? 'unknown');
      if (action) setAction(plan, pkg, action, inventory);
    }
  }
  return plan;
};

validateCatalog(catalog);
const args = process.argv.slice(2);

if (args[0] === '--help' || args[0] === '-h') {
  console.log(usage());
  process.exit(0);
}

if (args[0] === '--dry-run' && args.length === 1) {
  fail('--dry-run requires at least one package or group ID');
}
if (args[0] !== '--dry-run' && args.length > 0) fail(usage());
if (args[0] === '--dry-run') validateRequestedIds(args.slice(1));

const inventory = await scanInventory(bunRunner);
if (args[0] === '--dry-run') {
  const plan = planDefaults(args.slice(1), inventory);
  const lines = describePlan(plan);
  console.log(
    lines.length === 0 ? 'No actions are available for the requested selection.' : lines.join('\n')
  );
  process.exit(0);
}

const plan = await runApp(inventory);
if (!plan || plan.size === 0) process.exit(0);

console.log('\nRunning plan:\n');
for (const line of describePlan(plan)) console.log(line);
console.log('');

const results = await executePlan(plan, liveRunner);
const failure = results.find(result => result.exitCode !== 0);
if (failure) {
  console.error(`\n${failure.id} failed with exit code ${failure.exitCode}.`);
  process.exit(failure.exitCode);
}
