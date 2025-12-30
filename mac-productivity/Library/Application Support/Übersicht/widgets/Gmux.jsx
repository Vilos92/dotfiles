import { css, run } from "uebersicht"
import { cardStyle, headerStyle } from "./shared/Card.jsx"

export const refreshFrequency = 2000

export const className = cardStyle({ bottom: '20px', right: '20px', maxWidth: '300px' })

const sessionRowStyle = (isClickable) => css`
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  margin: 2px 0;
  border-radius: 4px;
  cursor: ${isClickable ? 'pointer' : 'default'};
  transition: background-color 0.2s;
  ${isClickable ? `
    &:hover {
      background-color: rgba(255,255,255,0.1);
    }
  ` : ''}
`

const statusDot = (color) => css`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: ${color};
  box-shadow: 0 0 4px ${color};
  flex-shrink: 0;
`

const sessionNameStyle = css`
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
`

const sessionInfoStyle = css`
  font-size: 11px;
  opacity: 0.6;
  margin-left: auto;
`

const emptyStateStyle = css`
  padding: 8px;
  text-align: center;
  opacity: 0.6;
  font-size: 12px;
`

// COMMAND
// Get all tmux sessions with their details, plus all possible projects
export const command = `
  # Get all tmux sessions with details
  /opt/homebrew/bin/tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null | while IFS='|' read -r name windows attached; do
    panes=$(/opt/homebrew/bin/tmux list-panes -t "$name" 2>/dev/null | wc -l | tr -d " " || echo "0")
    clients=$(/opt/homebrew/bin/tmux list-clients -t "$name" 2>/dev/null | wc -l | tr -d " " || echo "0")
    echo "SESSION:$name|$windows|$panes|$attached|$clients"
  done
  
  # Get all possible projects from ~/greg_projects (same logic as gmux)
  if [ -d "$HOME/greg_projects" ]; then
    find "$HOME/greg_projects" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | xargs -n 1 basename | sed 's/\.nvim$/_nvim/' | while read -r project; do
      echo "PROJECT:$project"
    done
  fi
`

export const render = ({ output, error }) => {
  if (error) {
    return (
      <div>
        <div className={headerStyle}>Gmux Sessions</div>
        <div className={emptyStateStyle}>Error: {String(error)}</div>
      </div>
    )
  }

  if (typeof output !== 'string' || output.trim() === '') {
    return (
      <div>
        <div className={headerStyle}>Gmux Sessions</div>
        <div className={emptyStateStyle}>No sessions</div>
      </div>
    )
  }

  const lines = output.trim().split('\n').filter(line => line.trim() !== '')
  
  // Parse sessions and projects
  const sessionsMap = new Map()
  const projectsSet = new Set()
  
  lines.forEach(line => {
    const trimmed = line.trim()
    if (trimmed.startsWith('SESSION:')) {
      const parts = trimmed.replace('SESSION:', '').split('|')
      if (parts.length >= 4) {
        const [name, windows, panes, attached, clients] = parts
        sessionsMap.set(name.trim(), {
          name: name.trim(),
          windows: parseInt(windows) || 0,
          panes: parseInt(panes) || 0,
          attached: attached.trim() === '1',
          clients: parseInt(clients) || 0,
          isSession: true
        })
      }
    } else if (trimmed.startsWith('PROJECT:')) {
      const projectName = trimmed.replace('PROJECT:', '').trim()
      if (projectName) {
        projectsSet.add(projectName)
      }
    }
  })
  
  // Combine sessions and projects
  const allItems = []
  
  // Add all projects (sessions or not)
  projectsSet.forEach(projectName => {
    if (sessionsMap.has(projectName)) {
      // It's a session, use the session data
      allItems.push(sessionsMap.get(projectName))
    } else {
      // It's just a project, no session exists
      allItems.push({
        name: projectName,
        windows: 0,
        panes: 0,
        attached: false,
        isSession: false
      })
    }
  })
  
  // Add any sessions that aren't in the projects list (edge case)
  sessionsMap.forEach((session, name) => {
    if (!projectsSet.has(name)) {
      allItems.push(session)
    }
  })
  
  // Sort: sessions first (with clients), then sessions without clients, then projects, then alphabetically
  const sessions = allItems.sort((a, b) => {
    // Sessions with clients first
    if (a.isSession && a.clients > 0 && !(b.isSession && b.clients > 0)) return -1
    if (b.isSession && b.clients > 0 && !(a.isSession && a.clients > 0)) return 1
    // Then sessions vs projects
    if (a.isSession !== b.isSession) return b.isSession ? 1 : -1
    // Then alphabetically
    return a.name.localeCompare(b.name)
  })

  const handleSessionClick = (sessionName) => {
    // Open alacritty with gmux command to attach to the session
    // Source zshrc to ensure gmux is in PATH, then run gmux with the session name
    run(`/opt/homebrew/bin/alacritty -e zsh -lc "source ~/.zshrc 2>/dev/null || true; gmux ${sessionName}"`)
      .catch(err => {
        console.error('Failed to open session:', err)
      })
  }

  return (
    <div>
      <div className={headerStyle}>Gmux Sessions</div>
      {sessions.length === 0 ? (
        <div className={emptyStateStyle}>No sessions</div>
      ) : (
        sessions.map((session, idx) => {
          const isSession = session.isSession
          const clientCount = session.clients || 0
          
          // Color logic:
          // Green: session exists AND has attached clients (clients > 0)
          // Blue: session exists but detached (clients === 0)
          // Grey: project exists but no session created yet
          let statusColor
          if (isSession && clientCount > 0) {
            statusColor = '#00e676' // Green - session has attached clients
          } else if (isSession) {
            statusColor = '#2196f3' // Blue - session exists but detached
          } else {
            statusColor = '#9e9e9e' // Grey - project exists but no session
          }
          
          return (
            <div
              key={session.name}
              className={sessionRowStyle(true)}
              onClick={() => handleSessionClick(session.name)}
              title={`Click to open ${session.name} in Alacritty`}
            >
              <div className={statusDot(statusColor)} />
              <div className={sessionNameStyle}>{session.name}</div>
              {isSession && (
                <div className={sessionInfoStyle}>
                  {session.windows}w/{session.panes}p/{session.clients}c
                </div>
              )}
            </div>
          )
        })
      )}
    </div>
  )
}

