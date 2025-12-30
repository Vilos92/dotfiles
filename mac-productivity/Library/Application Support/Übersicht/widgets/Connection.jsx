import {css} from 'uebersicht';
import {cardStyle, headerStyle} from './shared/Card.jsx';

/*
 * Constants.
 */

export const refreshFrequency = 5000;

/*
 * Styles.
 */

export const className = cardStyle({bottom: '20px', left: '20px', alignItems: 'flex-end'});

const rowStyle = css`
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  justify-content: flex-start;
`;

const statusDot = color => css`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: ${color};
  box-shadow: 0 0 4px ${color};
`;

/*
 * Command.
 */

/**
 * Check online status and tailscale status and exit nodes.
 */
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
      # Tailscale is running, output status indicator
      echo "TAILSCALE_RUNNING"
      # Try to get exit node list (may not be available)
      "$TS_PATH" exit-node list 2>&1 || echo "EXIT_NODES_UNAVAILABLE"
    fi
  else
    echo "BINARY_MISSING"
  fi
`;

/*
 * Component.
 */

export const render = ({output, error}) => {
  if (error) return <div>Error: {String(error)}</div>;

  const data = parseOutput(output);
  if (!data) {
    // Treat no output as offline.
    return (
      <div>
        <div className={headerStyle}>Connection</div>
        <div className={rowStyle}>
          <div className={statusDot('#ff1744')} />
          <span>macOS Online</span>
        </div>
        <div className={rowStyle} style={{marginTop: '4px'}}>
          <div className={statusDot('#9e9e9e')} />
          <span>Tailscale</span>
        </div>
      </div>
    );
  }

  const {isOnline, tsOutput, isTsRunning} = data;
  const routingInfo = isTsRunning ? extractRoutingInfo(tsOutput) : undefined;

  return (
    <div>
      <div className={headerStyle}>Connection</div>
      <div className={rowStyle}>
        <div className={statusDot(isOnline ? '#00e676' : '#ff1744')} />
        <span>macOS Online</span>
      </div>

      <div className={rowStyle} style={{marginTop: '4px'}}>
        <div className={statusDot(getTailscaleColor(isTsRunning, isOnline))} />
        <span>Tailscale</span>
      </div>

      {isTsRunning && (
        <div
          style={{
            marginTop: '8px',
            borderTop: '1px solid rgba(255,255,255,0.2)',
            paddingTop: '4px',
            fontSize: '11px',
            opacity: 0.9
          }}
        >
          {routingInfo ? (
            <div className={rowStyle}>
              <div className={statusDot(getExitNodeColor(isOnline))} />
              <span>
                → <strong>{routingInfo}</strong>
              </span>
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
  );
};

/*
 * Helpers.
 */

/**
 * Parse online status from command output.
 * @param {string} onlinePart - The online status portion of the output
 * @returns {boolean} True if online, false otherwise
 * @example
 * parseOnlineStatus("ONLINE:true") // => true
 * parseOnlineStatus("ONLINE:false") // => false
 * parseOnlineStatus(null) // => false
 */
function parseOnlineStatus(onlinePart) {
  if (!onlinePart) return false;
  return onlinePart.trim() === 'ONLINE:true';
}

/**
 * Check if Tailscale output indicates it's stopped or missing.
 * @param {string} tsOutput - The Tailscale command output
 * @returns {boolean} True if stopped or missing, false otherwise
 * @example
 * checkIsTailscaleStopped("Tailscale is stopped") // => true
 * checkIsTailscaleStopped("BINARY_MISSING") // => true
 * checkIsTailscaleStopped("HOSTNAME COUNTRY...") // => false
 */
function checkIsTailscaleStopped(tsOutput) {
  if (!tsOutput) return true;
  return (
    tsOutput.includes('Tailscale is stopped') ||
    tsOutput.includes('TAILSCALE_STOPPED') ||
    tsOutput.includes('BINARY_MISSING')
  );
}

/**
 * Check if Tailscale is running based on output format.
 * @param {string} tsOutput - The Tailscale command output
 * @returns {boolean} True if running, false otherwise
 * @example
 * checkIsTailscaleRunning("TAILSCALE_RUNNING\nHOSTNAME COUNTRY...") // => true
 * checkIsTailscaleRunning("TAILSCALE_RUNNING\nEXIT_NODES_UNAVAILABLE") // => true
 * checkIsTailscaleRunning("Tailscale is stopped") // => false
 * checkIsTailscaleRunning("") // => false
 */
function checkIsTailscaleRunning(tsOutput) {
  if (checkIsTailscaleStopped(tsOutput)) return false;
  if (tsOutput === '') return false;
  // Consider running if we see the running indicator (exit nodes are optional)
  return tsOutput.includes('TAILSCALE_RUNNING');
}

/**
 * Extract routing info from Tailscale exit node output.
 * @param {string} tsOutput - The Tailscale exit node list output
 * @returns {string|undefined} City name if available, hostname otherwise, or undefined if not found
 * @example
 * extractRoutingInfo("TAILSCALE_RUNNING\n100.1.2.3  my-node  US  San Jose, CA  selected") // => "San Jose, CA"
 * extractRoutingInfo("TAILSCALE_RUNNING\n100.1.2.3  my-node  US  Any  selected") // => "my-node"
 * extractRoutingInfo("TAILSCALE_RUNNING\nEXIT_NODES_UNAVAILABLE") // => undefined
 * extractRoutingInfo("no selected line") // => undefined
 */
function extractRoutingInfo(tsOutput) {
  if (!tsOutput) return undefined;

  // Skip the TAILSCALE_RUNNING line and EXIT_NODES_UNAVAILABLE if present
  const lines = tsOutput
    .split('\n')
    .filter(line => !line.includes('TAILSCALE_RUNNING') && !line.includes('EXIT_NODES_UNAVAILABLE'));

  if (lines.length === 0) return undefined;

  // Find the line ending in "selected".
  const selectedLine = lines.find(line => line.trim().endsWith('selected'));
  if (!selectedLine) return undefined;

  // Split by 2 or more spaces to handle columns cleanly.
  // Columns: [IP, HOSTNAME, COUNTRY, CITY, STATUS].
  const cols = selectedLine.trim().split(/\s{2,}/);
  if (cols.length < 4) return undefined;

  // We can show City + Country, or just Hostname.
  // City is usually friendlier (e.g. "San Jose, CA").
  const city = cols[3];
  const hostname = cols[1];
  return city !== 'Any' ? city : hostname;
}

/**
 * Get Tailscale status dot color.
 * @param {boolean} isTsRunning - Whether Tailscale is running
 * @param {boolean} isOnline - Whether macOS is online
 * @returns {string} Color hex code for the status dot
 * @example
 * getTailscaleColor(true, true) // => '#00e676' (green)
 * getTailscaleColor(true, false) // => '#ffea00' (yellow)
 * getTailscaleColor(false, false) // => '#9e9e9e' (gray)
 */
function getTailscaleColor(isTsRunning, isOnline) {
  if (!isTsRunning) return '#9e9e9e';
  return isOnline ? '#00e676' : '#ffea00';
}

/**
 * Get exit node status dot color.
 * @param {boolean} isOnline - Whether macOS is online
 * @returns {string} Color hex code for the status dot
 * @example
 * getExitNodeColor(true) // => '#00e676' (green)
 * getExitNodeColor(false) // => '#ffea00' (yellow)
 */
function getExitNodeColor(isOnline) {
  return isOnline ? '#00e676' : '#ffea00';
}

/**
 * Parse command output into structured data.
 * @param {string} output - Raw command output from the shell script
 * @returns {Object|undefined} Parsed data object or undefined if no output
 * @example
 * // Input:
 * // "ONLINE:true|||100.1.2.3  my-node  US  San Jose, CA  selected"
 * // Output:
 * // {
 * //   isOnline: true,
 * //   tsOutput: "100.1.2.3  my-node  US  San Jose, CA  selected",
 * //   isTsRunning: true
 * // }
 */
function parseOutput(output) {
  if (!output) return undefined;

  const [onlinePart, tailscalePart] = output.split('|||');
  const tsOutput = tailscalePart ? tailscalePart.trim() : '';

  return {
    isOnline: parseOnlineStatus(onlinePart),
    tsOutput,
    isTsRunning: checkIsTailscaleRunning(tsOutput)
  };
}
