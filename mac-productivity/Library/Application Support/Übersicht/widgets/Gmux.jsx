import {css, run} from 'uebersicht';
import {cardStyle, headerStyle} from './shared/Card.jsx';

/*
 * Constants.
 */

export const refreshFrequency = 2000;

/*
 * Styles.
 */

export const className = cardStyle({bottom: '20px', right: '20px', maxWidth: '200px'});

const sessionRowStyle = isClickable => css`
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  margin: 2px 0;
  border-radius: 4px;
  cursor: ${isClickable ? 'pointer' : 'default'};
  transition: background-color 0.2s;
  ${isClickable
    ? `
    &:hover {
      background-color: rgba(255,255,255,0.1);
    }
  `
    : ''}
`;

const statusDot = color => css`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: ${color};
  box-shadow: 0 0 4px ${color};
  flex-shrink: 0;
`;

const sessionNameStyle = css`
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
`;

const sessionInfoStyle = css`
  font-size: 11px;
  opacity: 0.6;
  margin-left: auto;
`;

const emptyStateStyle = css`
  padding: 8px;
  text-align: center;
  opacity: 0.6;
  font-size: 12px;
`;

/*
 * Command.
 */

/**
 * Get all tmux sessions with details, plus all possible projects.
 */
export const command = `
  # Get all tmux sessions with details
  /opt/homebrew/bin/tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null | while IFS='|' read -r name windows attached; do
    panes=$(/opt/homebrew/bin/tmux list-panes -t "$name" 2>/dev/null | wc -l | tr -d " " || echo "0")
    clients=$(/opt/homebrew/bin/tmux list-clients -t "$name" 2>/dev/null | wc -l | tr -d " " || echo "0")
    echo "SESSION:$name|$windows|$panes|$attached|$clients"
  done
  
  # Get all possible projects from ~/greg_projects (same logic as gmux)
  if [ -d "$HOME/greg_projects" ]; then
    /opt/homebrew/bin/fd -t d -d 1 . "$HOME/greg_projects" 2>/dev/null | xargs -n 1 basename | sed 's/\.nvim$/_nvim/' | while read -r project; do
      echo "PROJECT:$project"
    done
  fi
`;

/*
 * Component.
 */

export const render = ({output, error}) => {
  if (error) {
    return (
      <div>
        <div className={headerStyle}>Gmux Sessions</div>
        <div className={emptyStateStyle}>Error: {String(error)}</div>
      </div>
    );
  }

  const sessions = parseOutput(output);
  if (!sessions || sessions.length === 0) {
    return (
      <div>
        <div className={headerStyle}>Gmux Sessions</div>
        <div className={emptyStateStyle}>No sessions</div>
      </div>
    );
  }

  return (
    <div>
      <div className={headerStyle}>Gmux Sessions</div>
      {sessions.map(session => (
        <div
          key={session.name}
          className={sessionRowStyle(true)}
          onClick={() => handleSessionClick(session.name)}
          title={`Click to open ${session.name} in Alacritty`}
        >
          <div className={statusDot(getStatusColor(session))} />
          <div className={sessionNameStyle}>{session.name}</div>
          {session.isSession && (
            <div className={sessionInfoStyle}>
              {session.windows}w/{session.panes}p/{session.clients}c
            </div>
          )}
        </div>
      ))}
    </div>
  );
};

/*
 * Helpers.
 */

/**
 * Parse a session line from command output.
 * @param {string} line - A line starting with "SESSION:"
 * @returns {Object|undefined} Session object or undefined if invalid
 * @example
 * parseSessionLine("SESSION:dotfiles|1|1|1|2")
 * // => { name: "dotfiles", windows: 1, panes: 1, attached: true, clients: 2, isSession: true }
 * parseSessionLine("SESSION:invalid") // => undefined
 */
function parseSessionLine(line) {
  if (!line.startsWith('SESSION:')) return undefined;

  const parts = line.replace('SESSION:', '').split('|');
  if (parts.length < 5) return undefined;

  const [name, windows, panes, attached, clients] = parts;
  return {
    name: name.trim(),
    windows: parseInt(windows) ?? 0,
    panes: parseInt(panes) ?? 0,
    attached: attached.trim() === '1',
    clients: parseInt(clients) ?? 0,
    isSession: true
  };
}

/**
 * Parse a project line from command output.
 * @param {string} line - A line starting with "PROJECT:"
 * @returns {string|undefined} Project name or undefined if invalid
 * @example
 * parseProjectLine("PROJECT:astor-greg") // => "astor-greg"
 * parseProjectLine("PROJECT:") // => undefined
 */
function parseProjectLine(line) {
  if (!line.startsWith('PROJECT:')) return undefined;

  const projectName = line.replace('PROJECT:', '').trim();
  return projectName ?? undefined;
}

/**
 * Parse all lines from command output into sessions and projects.
 * @param {string[]} lines - Array of trimmed lines from command output
 * @returns {Object} Object with sessionsMap and projectsSet
 * @example
 * // Input: ["SESSION:dotfiles|1|1|1|2", "PROJECT:astor-greg"]
 * // Output: { sessionsMap: Map([["dotfiles", {...}]]), projectsSet: Set(["astor-greg"]) }
 */
function parseLines(lines) {
  const sessionsMap = new Map();
  const projectsSet = new Set();

  lines.forEach(line => {
    const trimmed = line.trim();
    const session = parseSessionLine(trimmed);
    if (session) {
      sessionsMap.set(session.name, session);
      return;
    }

    const project = parseProjectLine(trimmed);
    if (project) {
      projectsSet.add(project);
    }
  });

  return {sessionsMap, projectsSet};
}

/**
 * Create a project item (no session exists yet).
 * @param {string} projectName - Name of the project
 * @returns {Object} Project item object
 * @example
 * createProjectItem("astor-greg")
 * // => { name: "astor-greg", windows: 0, panes: 0, attached: false, isSession: false }
 */
function createProjectItem(projectName) {
  return {
    name: projectName,
    windows: 0,
    panes: 0,
    attached: false,
    isSession: false
  };
}

/**
 * Combine sessions and projects into a single array.
 * @param {Map} sessionsMap - Map of session name to session object
 * @param {Set} projectsSet - Set of project names
 * @returns {Object[]} Array of combined session and project items
 * @example
 * // Input: sessionsMap with "dotfiles", projectsSet with ["dotfiles", "astor-greg"]
 * // Output: [session("dotfiles"), project("astor-greg")]
 */
function combineSessionsAndProjects(sessionsMap, projectsSet) {
  const allItems = [];

  // Add all projects (sessions or not)
  projectsSet.forEach(projectName => {
    if (sessionsMap.has(projectName)) {
      // It's a session, use the session data
      allItems.push(sessionsMap.get(projectName));
    } else {
      // It's just a project, no session exists
      allItems.push(createProjectItem(projectName));
    }
  });

  // Add any sessions that aren't in the projects list (edge case)
  sessionsMap.forEach((session, name) => {
    if (!projectsSet.has(name)) {
      allItems.push(session);
    }
  });

  return allItems;
}

/**
 * Check if an item is a session with attached clients.
 * @param {Object} item - Session or project item
 * @returns {boolean} True if session has clients > 0
 * @example
 * checkHasAttachedClients({ isSession: true, clients: 2 }) // => true
 * checkHasAttachedClients({ isSession: true, clients: 0 }) // => false
 * checkHasAttachedClients({ isSession: false }) // => false
 */
function checkHasAttachedClients(item) {
  return item.isSession && item.clients > 0;
}

/**
 * Sort sessions: sessions with clients first, then sessions, then projects, then alphabetically.
 * @param {Object} a - First item to compare
 * @param {Object} b - Second item to compare
 * @returns {number} Comparison result for sort
 */
function sortSessions(a, b) {
  // Sessions with clients first
  const aHasClients = checkHasAttachedClients(a);
  const bHasClients = checkHasAttachedClients(b);
  if (aHasClients && !bHasClients) return -1;
  if (bHasClients && !aHasClients) return 1;

  // Then sessions vs projects
  if (a.isSession !== b.isSession) return b.isSession ? 1 : -1;

  // Then alphabetically
  return a.name.localeCompare(b.name);
}

/**
 * Get status color for a session or project.
 * @param {Object} item - Session or project item
 * @returns {string} Color hex code
 * @example
 * getStatusColor({ isSession: true, clients: 2 }) // => '#00e676' (green)
 * getStatusColor({ isSession: true, clients: 0 }) // => '#2196f3' (blue)
 * getStatusColor({ isSession: false }) // => '#9e9e9e' (grey)
 */
function getStatusColor(item) {
  if (item.isSession && item.clients > 0) {
    return '#00e676'; // Green - session has attached clients
  }
  if (item.isSession) {
    return '#2196f3'; // Blue - session exists but detached
  }
  return '#9e9e9e'; // Grey - project exists but no session
}

/**
 * Handle clicking on a session to open it in Alacritty.
 * @param {string} sessionName - Name of the session to open
 */
function handleSessionClick(sessionName) {
  run(
    `/opt/homebrew/bin/alacritty -e zsh -lc "source ~/.zshrc 2>/dev/null || true; gmux ${sessionName}"`
  ).catch(err => {
    console.error('Failed to open session:', err);
  });
}

/**
 * Parse command output into structured session and project data.
 * @param {string} output - Raw command output from the shell script
 * @returns {Object[]|undefined} Array of session/project items or undefined if invalid
 * @example
 * // Input:
 * // "SESSION:dotfiles|1|1|1|2\nPROJECT:astor-greg"
 * // Output:
 * // [
 * //   { name: "dotfiles", windows: 1, panes: 1, attached: true, clients: 2, isSession: true },
 * //   { name: "astor-greg", windows: 0, panes: 0, attached: false, isSession: false }
 * // ]
 */
function parseOutput(output) {
  if (typeof output !== 'string' || output.trim() === '') {
    return undefined;
  }

  const lines = output
    .trim()
    .split('\n')
    .filter(line => line.trim() !== '');
  const {sessionsMap, projectsSet} = parseLines(lines);
  const allItems = combineSessionsAndProjects(sessionsMap, projectsSet);

  return allItems.sort(sortSessions);
}
