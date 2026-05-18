import {css, run} from 'uebersicht';
import {cardStyle, headerStyle} from './shared/Card.jsx';

/*
 * Constants.
 */

export const refreshFrequency = 2000;

/*
 * Styles.
 */

export const className = cardStyle({bottom: '20px', right: '20px', maxWidth: '160px'});

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
  
  # Directory basenames for display; gmux uses tr '.' '_' only for tmux session names.
  if [ -d "$HOME/greg_projects" ]; then
    /opt/homebrew/bin/fd -t d -d 1 . "$HOME/greg_projects" -0 2>/dev/null \
      | xargs -0 -n 1 basename \
      | while IFS= read -r project; do
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
          title={`Click to open ${session.displayName} in Alacritty`}
        >
          <div className={statusDot(getStatusColor(session))} />
          <div className={sessionNameStyle}>{session.displayName}</div>
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

/** tmux maps '.' to '_' in session names; match gmux canonical names. */
function toSessionName(name) {
  return name.replaceAll('.', '_');
}

function parseIntOrZero(value) {
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? 0 : parsed;
}

/**
 * Parse a session line from command output.
 */
function parseSessionLine(line) {
  if (!line.startsWith('SESSION:')) return undefined;

  const parts = line.replace('SESSION:', '').split('|');
  if (parts.length < 5) return undefined;

  const [name, windows, panes, attached, clients] = parts;
  const sessionName = toSessionName(name.trim());
  return {
    name: sessionName,
    displayName: sessionName,
    windows: parseIntOrZero(windows),
    panes: parseIntOrZero(panes),
    attached: attached.trim() === '1',
    clients: parseIntOrZero(clients),
    isSession: true
  };
}

/**
 * Parse a project line from command output.
 */
function parseProjectLine(line) {
  if (!line.startsWith('PROJECT:')) return undefined;

  const displayName = line.replace('PROJECT:', '').trim();
  if (!displayName) return undefined;

  return {
    sessionName: toSessionName(displayName),
    displayName
  };
}

/**
 * Parse all lines from command output into sessions and projects.
 */
function parseLines(lines) {
  const sessionsMap = new Map();
  const projectDisplays = new Map();

  lines.forEach(line => {
    const trimmed = line.trim();
    const session = parseSessionLine(trimmed);
    if (session) {
      sessionsMap.set(session.name, session);
      return;
    }

    const project = parseProjectLine(trimmed);
    if (project) {
      projectDisplays.set(project.sessionName, project.displayName);
    }
  });

  return {sessionsMap, projectDisplays};
}

function withDisplayName(item, projectDisplays) {
  const displayName = projectDisplays.get(item.name) ?? item.displayName ?? item.name;
  return {...item, displayName};
}

/**
 * Create a project item (no session exists yet).
 */
function createProjectItem(sessionName, displayName) {
  return {
    name: sessionName,
    displayName,
    windows: 0,
    panes: 0,
    attached: false,
    isSession: false
  };
}

/**
 * Combine sessions and projects into a single array.
 */
function combineSessionsAndProjects(sessionsMap, projectDisplays) {
  const allItems = [];
  const seen = new Set();

  projectDisplays.forEach((displayName, sessionName) => {
    seen.add(sessionName);
    if (sessionsMap.has(sessionName)) {
      allItems.push(withDisplayName(sessionsMap.get(sessionName), projectDisplays));
    } else {
      allItems.push(createProjectItem(sessionName, displayName));
    }
  });

  sessionsMap.forEach((session, sessionName) => {
    if (!seen.has(sessionName)) {
      allItems.push(withDisplayName(session, projectDisplays));
    }
  });

  return allItems;
}

/**
 * Check if an item is a session with attached clients.
 */
function checkHasAttachedClients(item) {
  return item.isSession && item.clients > 0;
}

/**
 * Sort sessions: sessions with clients first, then sessions, then projects, then alphabetically.
 */
function sortSessions(a, b) {
  const aHasClients = checkHasAttachedClients(a);
  const bHasClients = checkHasAttachedClients(b);
  if (aHasClients && !bHasClients) return -1;
  if (bHasClients && !aHasClients) return 1;

  if (a.isSession !== b.isSession) return b.isSession ? 1 : -1;

  return a.displayName.localeCompare(b.displayName);
}

/**
 * Get status color for a session or project.
 */
function getStatusColor(item) {
  if (item.isSession && item.clients > 0) {
    return '#00e676';
  }
  if (item.isSession) {
    return '#2196f3';
  }
  return '#9e9e9e';
}

/**
 * Handle clicking on a session to open it in Alacritty.
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
 */
function parseOutput(output) {
  if (typeof output !== 'string' || output.trim() === '') {
    return undefined;
  }

  const lines = output
    .trim()
    .split('\n')
    .filter(line => line.trim() !== '');
  const {sessionsMap, projectDisplays} = parseLines(lines);
  const allItems = combineSessionsAndProjects(sessionsMap, projectDisplays);

  return allItems.sort(sortSessions);
}
