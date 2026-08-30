import {allPackages, packageById} from './catalog.ts';
import type {
  Catalog,
  GroupDefinition,
  Inventory,
  PackageDefinition,
  PackageStatus,
  Plan,
  PlannedAction
} from './types.ts';

export const defaultAction = (pkg: PackageDefinition, status: PackageStatus): PlannedAction | undefined => {
  if (pkg.action.kind === 'brew') {
    if (status === 'missing') return 'install';
    if (status === 'outdated') return 'update';
    return undefined;
  }

  return 'install';
};

export const availableActions = (pkg: PackageDefinition, status: PackageStatus): PlannedAction[] => {
  if (pkg.action.kind !== 'brew') return ['install'];
  if (status === 'missing') return ['install'];
  if (status === 'unknown') return [];
  return status === 'outdated' ? ['update', 'remove'] : ['remove'];
};

export const validateCatalog = (catalog: Catalog): void => {
  const packages = allPackages(catalog);
  const ids = new Set<string>();
  const byId = packageById(catalog);

  for (const pkg of packages) {
    if (ids.has(pkg.id)) throw new Error(`Duplicate package ID: ${pkg.id}`);
    ids.add(pkg.id);
    for (const requirement of pkg.requires ?? []) {
      if (!byId.has(requirement)) throw new Error(`${pkg.id} requires unknown package ${requirement}`);
    }
  }

  const visiting = new Set<string>();
  const visited = new Set<string>();
  const visit = (id: string): void => {
    if (visited.has(id)) return;
    if (visiting.has(id)) throw new Error(`Dependency cycle includes ${id}`);
    visiting.add(id);
    for (const requirement of byId.get(id)?.requires ?? []) visit(requirement);
    visiting.delete(id);
    visited.add(id);
  };

  for (const pkg of packages) visit(pkg.id);
};

const addRequirements = (plan: Plan, pkg: PackageDefinition, inventory: Inventory): void => {
  for (const requirementId of pkg.requires ?? []) {
    const requirement = packageById().get(requirementId);
    if (!requirement) throw new Error(`${pkg.id} requires unknown package ${requirementId}`);
    const action = defaultAction(requirement, inventory.get(requirementId) ?? 'unknown');
    if (plan.get(requirementId) === 'remove') plan.delete(requirementId);
    if (action && !plan.has(requirementId)) {
      plan.set(requirementId, action);
      addRequirements(plan, requirement, inventory);
    }
  }
};

export const setAction = (
  plan: Plan,
  pkg: PackageDefinition,
  action: PlannedAction,
  inventory: Inventory
): void => {
  if (!availableActions(pkg, inventory.get(pkg.id) ?? 'unknown').includes(action)) {
    throw new Error(`${action} is not available for ${pkg.id}`);
  }
  if (action === 'remove' && isRequiredByPlan(plan, pkg.id)) {
    throw new Error(`${pkg.id} is required by another planned action`);
  }
  plan.set(pkg.id, action);
  if (action !== 'remove') addRequirements(plan, pkg, inventory);
};

const requiresPackage = (pkg: PackageDefinition, targetId: string, visited = new Set<string>()): boolean => {
  if (visited.has(pkg.id)) return false;
  visited.add(pkg.id);
  for (const requirementId of pkg.requires ?? []) {
    if (requirementId === targetId) return true;
    const requirement = packageById().get(requirementId);
    if (requirement && requiresPackage(requirement, targetId, visited)) return true;
  }
  return false;
};

export const isRequiredByPlan = (plan: Plan, packageId: string): boolean => {
  const packages = packageById();
  return [...plan].some(([id, action]) => {
    if (id === packageId || action === 'remove') return false;
    const pkg = packages.get(id);
    return pkg ? requiresPackage(pkg, packageId) : false;
  });
};

export const unsetAction = (plan: Plan, packageId: string): void => {
  if (!isRequiredByPlan(plan, packageId)) plan.delete(packageId);
};

export const toggleDefaultAction = (plan: Plan, pkg: PackageDefinition, inventory: Inventory): void => {
  if (plan.has(pkg.id)) {
    unsetAction(plan, pkg.id);
    return;
  }

  const action = defaultAction(pkg, inventory.get(pkg.id) ?? 'unknown');
  if (action) setAction(plan, pkg, action, inventory);
};

export const toggleGroupDefaults = (plan: Plan, group: GroupDefinition, inventory: Inventory): void => {
  const defaults = group.packages
    .map(pkg => ({pkg, action: defaultAction(pkg, inventory.get(pkg.id) ?? 'unknown')}))
    .filter((item): item is {pkg: PackageDefinition; action: PlannedAction} => item.action !== undefined);

  const isSelected = defaults.length > 0 && defaults.every(({pkg}) => plan.has(pkg.id));
  for (const {pkg, action} of defaults) {
    if (isSelected) unsetAction(plan, pkg.id);
    else setAction(plan, pkg, action, inventory);
  }
};

export const actionsForGroup = (plan: Plan, group: GroupDefinition): Plan =>
  new Map([...plan].filter(([id]) => group.packages.some(pkg => pkg.id === id)));

export const orderedPlan = (plan: Plan): Array<{pkg: PackageDefinition; action: PlannedAction}> => {
  const byId = packageById();
  const ordered: Array<{pkg: PackageDefinition; action: PlannedAction}> = [];
  const added = new Set<string>();

  const add = (id: string): void => {
    if (added.has(id)) return;
    const pkg = byId.get(id);
    const action = plan.get(id);
    if (!pkg || !action) return;
    if (action !== 'remove') for (const requirement of pkg.requires ?? []) add(requirement);
    added.add(id);
    ordered.push({pkg, action});
  };

  for (const pkg of allPackages()) add(pkg.id);
  return ordered;
};
