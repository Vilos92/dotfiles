import { css, run } from "uebersicht"

export const refreshFrequency = 2000

export const className = css`
  bottom: 20px;
  right: 20px;
  position: absolute;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  font-size: 13px;
  line-height: 1.4;
  color: #fff;
  background-color: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(10px);
  padding: 12px 16px;
  border-radius: 10px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  display: flex;
  flex-direction: column;
  min-width: 200px;
  max-width: 300px;
`

const headerStyle = css`
  font-weight: 600;
  margin-bottom: 8px;
  padding-bottom: 6px;
  border-bottom: 1px solid rgba(255,255,255,0.2);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  opacity: 0.8;
`

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
  
  # Get currently active session (the one you're viewing)
  CURRENT=$(/opt/homebrew/bin/tmux list-sessions -F "#{session_name}" -f "#{session_attached}" 2>/dev/null | head -n 1 || echo "")
  echo "CURRENT:$CURRENT"
  
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
        <div className={headerStyle}>Tmux Sessions</div>
        <div className={emptyStateStyle}>Error: {String(error)}</div>
      </div>
    )
  }

  if (typeof output !== 'string' || output.trim() === '') {
    return (
      <div>
        <div className={headerStyle}>Tmux Sessions</div>
        <div className={emptyStateStyle}>No sessions</div>
      </div>
    )
  }

  const lines = output.trim().split('\n').filter(line => line.trim() !== '')
  const currentLine = lines.find(line => line.trim().startsWith('CURRENT:'))
  const currentSession = currentLine ? currentLine.trim().replace('CURRENT:', '').trim() : ''
  
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
          isActive: name.trim() === currentSession,
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
        isActive: false,
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
  
  // Sort: active first, then sessions (blue), then projects (grey), then alphabetically
  const sessions = allItems.sort((a, b) => {
    if (a.isActive !== b.isActive) return b.isActive ? 1 : -1
    if (a.isSession !== b.isSession) return b.isSession ? 1 : -1
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

