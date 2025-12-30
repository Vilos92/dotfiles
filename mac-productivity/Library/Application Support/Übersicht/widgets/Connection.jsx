import { css } from "uebersicht"
import { cardStyle, headerStyle } from "./shared/Card.jsx"

export const refreshFrequency = 5000

export const className = cardStyle({ top: '20px', right: '20px', alignItems: 'flex-end' })

const rowStyle = css`
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  justify-content: flex-start;
`

const statusDot = (color) => css`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: ${color};
  box-shadow: 0 0 4px ${color};
`

// COMMAND
// We switched from 'status --json' to 'exit-node list'
export const command = `
  # 1. Check Online Status
  if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
    printf "ONLINE:true"
  else
    printf "ONLINE:false"
  fi

  printf "|||"

  # 2. Check Tailscale Status and Exit Nodes
  TS_PATH="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
   
  if [ -f "$TS_PATH" ]; then
    # First check if Tailscale is actually running
    STATUS_OUTPUT=$("$TS_PATH" status 2>&1 | head -1)
    if echo "$STATUS_OUTPUT" | grep -q "Tailscale is stopped"; then
      echo "TAILSCALE_STOPPED"
    else
      # Tailscale is running, get exit node list
      "$TS_PATH" exit-node list 2>&1
    fi
  else
    echo "BINARY_MISSING"
  fi
`

export const render = ({ output, error }) => {
  if (error) return <div>Error: {String(error)}</div>
  if (!output) {
    // Treat no output as offline
    return (
      <div>
        <div className={headerStyle}>Connection</div>
        <div className={rowStyle}>
          <div className={statusDot('#ff1744')} />
          <span>macOS Online</span>
        </div>
        <div className={rowStyle} style={{ marginTop: '4px' }}>
          <div className={statusDot('#9e9e9e')} />
          <span>Tailscale</span>
        </div>
      </div>
    )
  }

  const [onlinePart, tailscalePart] = output.split('|||')
  
  // 1. Parse Online Status
  const isOnline = onlinePart ? onlinePart.trim() === 'ONLINE:true' : false
  
  // 2. Parse Tailscale Status
  const tsOutput = tailscalePart ? tailscalePart.trim() : ""
  
  // Explicitly check for stopped state first (this takes priority)
  let isTsRunning = false
  if (!tsOutput.includes("Tailscale is stopped") && 
      !tsOutput.includes("TAILSCALE_STOPPED") &&
      !tsOutput.includes("BINARY_MISSING") &&
      tsOutput !== "") {
    // Only consider running if we have the table headers
    // This means Tailscale returned a valid exit node list
    isTsRunning = tsOutput.includes("HOSTNAME") && tsOutput.includes("COUNTRY")
  }

  // 3. Find Selected Exit Node
  let routingInfo = null
  
  if (isTsRunning) {
    // Find the line ending in "selected"
    const selectedLine = tsOutput.split('\n').find(line => line.trim().endsWith('selected'))
    
    if (selectedLine) {
      // Split by 2 or more spaces to handle columns cleanly
      // Columns: [IP, HOSTNAME, COUNTRY, CITY, STATUS]
      const cols = selectedLine.trim().split(/\s{2,}/)
      
      if (cols.length >= 4) {
        // We can show City + Country, or just Hostname. 
        // City is usually friendlier (e.g. "San Jose, CA")
        const city = cols[3]
        const hostname = cols[1]
        routingInfo = city !== "Any" ? city : hostname
      }
    }
  }

  return (
    <div>
      <div className={headerStyle}>Connection</div>
      <div className={rowStyle}>
        <div className={statusDot(isOnline ? '#00e676' : '#ff1744')} />
        <span>macOS Online</span>
      </div>

      <div className={rowStyle} style={{ marginTop: '4px' }}>
        {/* Yellow if running but macOS offline, Green if running and online, Gray if off */}
        <div className={statusDot(
          isTsRunning 
            ? (isOnline ? '#00e676' : '#ffea00') 
            : '#9e9e9e'
        )} />
        <span>Tailscale</span>
      </div>

      {isTsRunning && (
        <div style={{ marginTop: '8px', borderTop: '1px solid rgba(255,255,255,0.2)', paddingTop: '4px', fontSize: '11px', opacity: 0.9 }}>
          {routingInfo ? (
            <div className={rowStyle}>
              <div className={statusDot(isOnline ? '#00e676' : '#ffea00')} />
              <span>→ <strong>{routingInfo}</strong></span>
            </div>
          ) : (
            <div className={rowStyle}>
              <div className={statusDot('#ff1744')} />
              <span>Exit Node</span>
            </div>
          )}
        </div>
      )}
    </div>
  )
}