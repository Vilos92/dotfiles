import {
  BoxRenderable,
  CliRenderEvents,
  ScrollBoxRenderable,
  TextRenderable,
  createCliRenderer,
  type CliRenderer
} from '@opentui/core';

import {catalog, packageById, v92Banner} from './catalog.ts';
import {
  availableActions,
  orderedPlan,
  setAction,
  toggleDefaultAction,
  toggleGroupDefaults
} from './planner.ts';
import type {GroupDefinition, Inventory, PackageDefinition, Plan, PlannedAction} from './types.ts';

type GroupRow = {kind: 'group'; group: GroupDefinition};
type PackageRow = {kind: 'package'; group: GroupDefinition; pkg: PackageDefinition};
type Row = GroupRow | PackageRow;
type TreeLine = {id: string; text: string};
type AppResult = Plan | null;

const statusLabel: Record<string, string> = {
  missing: 'missing',
  installed: 'installed',
  outdated: 'outdated',
  unknown: 'unknown'
};

const actionMarker: Record<PlannedAction, string> = {
  install: 'I',
  update: 'U',
  remove: 'D'
};

const actionLabel: Record<PlannedAction, string> = {
  install: 'Install',
  update: 'Update',
  remove: 'Remove'
};

export const runApp = async (inventory: Inventory, testRenderer?: CliRenderer): Promise<AppResult> => {
  const renderer = testRenderer ?? (await createCliRenderer({exitOnCtrlC: false, useMouse: false}));
  const layout = new BoxRenderable(renderer, {width: '100%', height: '100%', flexDirection: 'column'});
  const header = new TextRenderable(renderer, {width: '100%', height: 8, selectable: false});
  const tree = new ScrollBoxRenderable(renderer, {
    id: 'package-tree',
    width: '100%',
    flexGrow: 1,
    viewportCulling: true,
    scrollbarOptions: {showArrows: true}
  });
  const footer = new TextRenderable(renderer, {width: '100%', height: 4, selectable: false});
  layout.add(header);
  layout.add(tree);
  layout.add(footer);
  renderer.root.add(layout);

  const plan: Plan = new Map();
  const expanded = new Set<string>();
  let cursor = 0;
  let filter = '';
  let filtering = false;
  let planOpen = false;
  let actionMenuFor: string | null = null;
  let removeConfirmation = '';
  let notice = '';
  let settled = false;
  let pendingTreeFocus: string | undefined;
  let viewportSyncScheduled = false;

  const visibleRows = (): Row[] => {
    const query = filter.toLowerCase();
    const matches = (pkg: PackageDefinition): boolean =>
      !query || `${pkg.id} ${pkg.label} ${pkg.description}`.toLowerCase().includes(query);

    return catalog.groups.flatMap(group => {
      const packages = group.packages.filter(matches);
      if (query && packages.length === 0) return [];
      const isExpanded = expanded.has(group.id) || Boolean(query);
      return [
        {kind: 'group' as const, group},
        ...(isExpanded ? packages.map(pkg => ({kind: 'package' as const, group, pkg})) : [])
      ];
    });
  };

  const actionSummary = (): string => {
    const counts: Record<PlannedAction, number> = {install: 0, update: 0, remove: 0};
    for (const action of plan.values()) counts[action]++;
    const parts = (['install', 'update', 'remove'] as PlannedAction[])
      .filter(action => counts[action] > 0)
      .map(action => `${counts[action]} ${action}${counts[action] === 1 ? '' : 's'}`);
    return parts.length === 0 ? '0 actions planned' : parts.join(', ');
  };

  const groupSummary = (group: GroupDefinition): string => {
    const actions = group.packages.filter(pkg => plan.has(pkg.id)).map(pkg => plan.get(pkg.id)!);
    if (actions.length === 0) return '';
    const installs = actions.filter(action => action === 'install').length;
    const updates = actions.filter(action => action === 'update').length;
    const removals = actions.filter(action => action === 'remove').length;
    return ` ${installs ? `${installs}I ` : ''}${updates ? `${updates}U ` : ''}${removals ? `${removals}D` : ''}`.trimEnd();
  };

  const renderRows = (): {lines: TreeLine[]; focusedId: string | undefined} => {
    const rows = visibleRows();
    cursor = Math.max(0, Math.min(cursor, Math.max(0, rows.length - 1)));
    const focusedRow = rows[cursor];
    const focusedId = focusedRow
      ? `${focusedRow.kind}-${focusedRow.kind === 'group' ? focusedRow.group.id : focusedRow.pkg.id}`
      : undefined;
    const lines = rows.map((row, index) => {
      const focused = index === cursor ? '›' : ' ';
      if (row.kind === 'group') {
        const selected = row.group.packages.filter(pkg => plan.has(pkg.id)).length;
        const symbol = expanded.has(row.group.id) || Boolean(filter) ? '▾' : '▸';
        return {
          id: `group-${row.group.id}`,
          text: `${focused} ${symbol} ${row.group.label}  ${selected}/${row.group.packages.length}${groupSummary(row.group)}`
        };
      }

      const marker = plan.get(row.pkg.id);
      const status = statusLabel[inventory.get(row.pkg.id) ?? 'unknown'];
      return {
        id: `package-${row.pkg.id}`,
        text: `${focused}   [${marker ? actionMarker[marker] : ' '}] ${row.pkg.label.padEnd(28)} ${status}`
      };
    });
    return {lines, focusedId};
  };

  const renderPlan = (): TreeLine[] => {
    const entries = orderedPlan(plan);
    if (entries.length === 0) return [{id: 'plan-empty', text: 'No actions planned.'}];
    return entries.map(({pkg, action}) => ({
      id: `plan-${pkg.id}`,
      text: `[${actionMarker[action]}] ${actionLabel[action].padEnd(7)} ${pkg.label}`
    }));
  };

  const scheduleViewportSync = (focusId?: string): void => {
    pendingTreeFocus = focusId;
    if (viewportSyncScheduled) return;
    viewportSyncScheduled = true;
    renderer.once(CliRenderEvents.FRAME, () => {
      viewportSyncScheduled = false;
      if (pendingTreeFocus) tree.scrollChildIntoView(pendingTreeFocus);
      else tree.scrollTo(0);
    });
  };

  const replaceTree = (lines: TreeLine[], focusId?: string): void => {
    for (const child of tree.getChildren()) {
      tree.remove(child);
      child.destroy();
    }
    for (const line of lines) {
      tree.add(
        new TextRenderable(renderer, {
          id: line.id,
          width: '100%',
          height: 1,
          content: line.text,
          selectable: false
        })
      );
    }
    scheduleViewportSync(focusId);
  };

  const update = (): void => {
    header.content = `${v92Banner}\n\nBrews · ${actionSummary()}\n────────────────────────────────────────────────────────────────`;

    if (planOpen) {
      replaceTree(renderPlan());
      const hasRemovals = [...plan.values()].includes('remove');
      footer.content =
        hasRemovals && removeConfirmation !== 'REMOVE'
          ? `Review plan\n\nType REMOVE to confirm deletions: ${removeConfirmation}\nEsc: return to selection`
          : 'Review plan\n\nEnter: run plan · Esc: return to selection';
      return;
    }

    const {lines, focusedId} = renderRows();
    replaceTree(lines, focusedId);
    const controls = actionMenuFor
      ? (() => {
          const pkg = packageById().get(actionMenuFor);
          const actions = pkg ? availableActions(pkg, inventory.get(pkg.id) ?? 'unknown') : [];
          return `${pkg?.label ?? 'Package'}: ${actions.map(action => `${action[0].toUpperCase()}: ${actionLabel[action]}`).join(' · ')}\nEsc: close action chooser`;
        })()
      : '↑/↓ move · ←/→ collapse/expand · Space plan default · Enter actions · / filter · P review · Q quit';
    const filterLine = filtering ? `Filter: ${filter}_` : filter ? `Filter: ${filter}` : '';
    footer.content = [filterLine, controls, notice].filter(Boolean).join('\n');
  };

  const finish = (result: AppResult, resolve: (result: AppResult) => void): void => {
    if (settled) return;
    settled = true;
    renderer.destroy();
    resolve(result);
  };

  return new Promise<AppResult>(resolve => {
    const handleActionMenu = (key: string): boolean => {
      if (!actionMenuFor) return false;
      if (key === 'escape') {
        actionMenuFor = null;
        return true;
      }
      const pkg = packageById().get(actionMenuFor);
      if (!pkg) return false;
      const actions = availableActions(pkg, inventory.get(pkg.id) ?? 'unknown');
      const action = actions.find(candidate => candidate[0] === key);
      if (!action) return true;
      try {
        setAction(plan, pkg, action, inventory);
        actionMenuFor = null;
      } catch (error) {
        notice = error instanceof Error ? error.message : String(error);
      }
      return true;
    };

    renderer.keyInput.on('keypress', key => {
      notice = '';
      if (key.ctrl && key.name === 'c') {
        finish(null, resolve);
        return;
      }

      if (planOpen) {
        if (key.name === 'escape') {
          planOpen = false;
          removeConfirmation = '';
        } else if ([...plan.values()].includes('remove') && removeConfirmation !== 'REMOVE') {
          if (key.name === 'backspace') removeConfirmation = removeConfirmation.slice(0, -1);
          else if (key.sequence.length === 1 && /[a-z]/i.test(key.sequence))
            removeConfirmation += key.sequence.toUpperCase();
        } else if (key.name === 'return' || key.name === 'enter') {
          finish(new Map(plan), resolve);
          return;
        }
        update();
        return;
      }

      if (filtering) {
        if (key.name === 'escape') {
          filtering = false;
          filter = '';
        } else if (key.name === 'return' || key.name === 'enter') {
          filtering = false;
        } else if (key.name === 'backspace') {
          filter = filter.slice(0, -1);
        } else if (key.sequence.length === 1 && !key.ctrl && !key.meta) {
          filter += key.sequence;
        }
        cursor = 0;
        update();
        return;
      }

      if (handleActionMenu(key.name)) {
        update();
        return;
      }

      const rows = visibleRows();
      const row = rows[cursor];
      if (key.name === 'q' || key.name === 'escape') {
        finish(null, resolve);
        return;
      }
      if (key.name === 'up') cursor = Math.max(0, cursor - 1);
      else if (key.name === 'down') cursor = Math.min(rows.length - 1, cursor + 1);
      else if (key.name === 'left' && row?.kind === 'group') expanded.delete(row.group.id);
      else if (key.name === 'right' && row?.kind === 'group') expanded.add(row.group.id);
      else if (key.name === 'space' && row?.kind === 'group') toggleGroupDefaults(plan, row.group, inventory);
      else if (key.name === 'space' && row?.kind === 'package') toggleDefaultAction(plan, row.pkg, inventory);
      else if ((key.name === 'return' || key.name === 'enter') && row?.kind === 'group') {
        if (expanded.has(row.group.id)) expanded.delete(row.group.id);
        else expanded.add(row.group.id);
      } else if ((key.name === 'return' || key.name === 'enter') && row?.kind === 'package') {
        actionMenuFor = row.pkg.id;
      } else if (key.name === '/') {
        filtering = true;
      } else if (key.name === 'p') {
        planOpen = true;
      }
      update();
    });

    update();
  });
};
