export type BrewKind = 'formula' | 'cask';

export type InstallAction =
  | {kind: 'brew'; brewKind: BrewKind; token: string}
  | {kind: 'shell'; command: string}
  | {kind: 'managed-shell'; installCommand: string; updateCommand: string};

export type Probe =
  | {kind: 'brew'; brewKind: BrewKind; token: string}
  | {kind: 'command'; command: string}
  | {kind: 'path'; path: string}
  | {kind: 'github-release-macos-app'; repository: string; path: string}
  | {kind: 'unknown'};

export type PackageDefinition = {
  id: string;
  label: string;
  description: string;
  action: InstallAction;
  probe: Probe;
  requires?: string[];
};

export type GroupDefinition = {
  id: string;
  label: string;
  packages: PackageDefinition[];
};

export type Catalog = {
  groups: GroupDefinition[];
};

export type PackageStatus = 'missing' | 'installed' | 'outdated' | 'unknown';
export type PlannedAction = 'install' | 'update' | 'remove';

export type Inventory = Map<string, PackageStatus>;
export type Plan = Map<string, PlannedAction>;

export type PackageWithGroup = PackageDefinition & {group: GroupDefinition};
