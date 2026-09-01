import type {CommandRunner} from './inventory.ts';
import {bunRunner} from './inventory.ts';
import {orderedPlan} from './planner.ts';
import type {PackageDefinition, Plan, PlannedAction} from './types.ts';

export type ExecutionResult = {
  id: string;
  action: string;
  exitCode: number;
  stderr: string;
};

const commandFor = (action: PlannedAction, pkg: PackageDefinition): string[] => {
  if (pkg.action.kind === 'shell') {
    if (action !== 'install') throw new Error(`${action} is not supported for ${pkg.id}`);
    return ['/usr/bin/env', 'bash', '-lc', pkg.action.command];
  }

  if (pkg.action.kind === 'managed-shell') {
    if (action === 'remove') throw new Error(`${action} is not supported for ${pkg.id}`);
    const command = action === 'install' ? pkg.action.installCommand : pkg.action.updateCommand;
    return ['/usr/bin/env', 'bash', '-lc', command];
  }

  const type = `--${pkg.action.brewKind}`;
  switch (action) {
    case 'install':
      return ['brew', 'install', type, pkg.action.token];
    case 'update':
      return ['brew', 'upgrade', type, pkg.action.token];
    case 'remove':
      return ['brew', 'uninstall', type, pkg.action.token];
  }
};

export const describePlan = (plan: Plan): string[] =>
  orderedPlan(plan).map(({pkg, action}) => `${action.padEnd(7)} ${pkg.id} — ${pkg.label}`);

export const executePlan = async (
  plan: Plan,
  runner: CommandRunner = bunRunner
): Promise<ExecutionResult[]> => {
  const results: ExecutionResult[] = [];
  for (const {pkg, action} of orderedPlan(plan)) {
    const result = await runner.run(commandFor(action, pkg));
    results.push({id: pkg.id, action, exitCode: result.exitCode, stderr: result.stderr});
    if (result.exitCode !== 0) break;
  }
  return results;
};
