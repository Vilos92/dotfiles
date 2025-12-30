import {css, run} from 'uebersicht';

/*
 * Constants.
 */

export const refreshFrequency = 5000;

const webUiUrl = 'http://greg-zone:9004';

/*
 * Styles.
 */

const cardStyle = (position = {}) => css`
  ${position.top !== undefined ? `top: ${position.top};` : ''}
  ${position.bottom !== undefined ? `bottom: ${position.bottom};` : ''}
  ${position.left !== undefined ? `left: ${position.left};` : ''}
  ${position.right !== undefined ? `right: ${position.right};` : ''}
  position: absolute;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  font-size: 13px;
  line-height: 1.4;
  color: #fff;
  background-color: rgba(0, 0, 0, 0.4);
  backdrop-filter: blur(10px);
  padding: 12px 16px;
  border-radius: 10px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  ${position.alignItems ? `align-items: ${position.alignItems};` : ''}
  ${position.minWidth ? `min-width: ${position.minWidth};` : ''}
  ${position.maxWidth ? `max-width: ${position.maxWidth};` : ''}
`;

export const className = cardStyle({bottom: '20px', right: '240px', maxWidth: '400px'});

const headerStyle = css`
  font-weight: 600;
  margin-bottom: 8px;
  padding-bottom: 6px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  opacity: 0.8;
`;

const rowStyle = isClickable => css`
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 4px 6px;
  border-radius: 4px;
  font-size: 11px;
  cursor: ${isClickable ? 'pointer' : 'default'};
  transition: background-color 0.2s;
  ${isClickable ? `&:hover { background-color: rgba(255,255,255,0.1); }` : ''}
`;

const statusDot = color => css`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: ${color};
  box-shadow: 0 0 4px ${color};
  flex-shrink: 0;
`;

const nameStyle = css`
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 500;
`;

const metaStyle = css`
  opacity: 0.6;
  margin-left: 8px;
  font-family: monospace;
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

export const command = `
  DOCKER="/usr/local/bin/docker"
  CONTAINER="transmission"

  # 1. Check if container is running
  if ! $DOCKER ps --format '{{.Names}}' | grep -q "^$CONTAINER$"; then
    echo "CONTAINER_STOPPED"
    exit 0
  fi

  # 2. Run remote list command inside container
  # We use sh -c to let the container expand its own internal env vars ($USER/$PASS)
  OUTPUT=$($DOCKER exec $CONTAINER sh -c 'transmission-remote -n "$USER:$PASS" -l' 2>&1)

  if [ $? -ne 0 ]; then
    echo "AUTH_ERROR"
  else
    echo "$OUTPUT"
  fi
`;

/*
 * Component.
 */

export const render = ({output, error}) => {
  if (error)
    return (
      <div>
        <div className={headerStyle}>Transmission</div>
        <div className={emptyStateStyle}>{String(error)}</div>
      </div>
    );

  const data = parseOutput(output);

  if (data.status === 'STOPPED') {
    return (
      <div>
        <div className={headerStyle}>Transmission</div>
        <div className={rowStyle(false)}>
          <div className={statusDot('#ff1744')} />
          <span>Container Stopped</span>
        </div>
      </div>
    );
  }

  if (data.status === 'AUTH_ERROR') {
    return (
      <div>
        <div className={headerStyle}>Transmission</div>
        <div className={emptyStateStyle}>Auth Failed (Check User/Pass)</div>
      </div>
    );
  }

  if (data.torrents.length === 0) {
    return (
      <div>
        <div className={headerStyle}>Transmission</div>
        <div className={emptyStateStyle}>Idle</div>
      </div>
    );
  }

  return (
    <div>
      <div className={headerStyle}>Transmission</div>
      {data.torrents.map(t => {
        const isActive = isTorrentActive(t.status);
        return (
          <div
            key={t.id}
            className={rowStyle(true)}
            onClick={() => run(`open ${webUiUrl}`)}
            title={`[${t.status}] ${t.name}`}
          >
            <div className={statusDot(getTorrentColor(t.status))} />
            <div className={nameStyle}>{t.name}</div>
            {isActive ? (
              <div className={metaStyle}>
                {t.down && t.down !== '0.0' && t.down !== '0' ? `↓ ${t.down} kB/s` : ''}
                {t.down && t.down !== '0.0' && t.down !== '0' && t.up && t.up !== '0.0' && t.up !== '0' ? ' ' : ''}
                {t.up && t.up !== '0.0' && t.up !== '0' ? `↑ ${t.up} kB/s` : ''}
              </div>
            ) : (
              <div className={metaStyle}>{t.percent}%</div>
            )}
          </div>
        );
      })}
      {/* Summary Footer */}
      <div
        style={{
          marginTop: '6px',
          borderTop: '1px solid rgba(255,255,255,0.1)',
          paddingTop: '4px',
          fontSize: '10px',
          opacity: 0.5,
          textAlign: 'right'
        }}
      >
        {data.torrents.filter(t => isTorrentActive(t.status)).length} active
      </div>
    </div>
  );
};

/*
 * Helpers.
 */

/**
 * Determine if a torrent is actively transferring data.
 * @param {string} status - The text status from `transmission-remote`
 * @returns {boolean} True if torrent is actively uploading or downloading
 */
function isTorrentActive(status) {
  const s = status.toLowerCase();
  return s.includes('seeding') || s.includes('download') || s.includes('up & down');
}

/**
 * Determine color based on torrent status.
 * @param {string} status - The text status from `transmission-remote`
 * @returns {string} Hex color code
 */
function getTorrentColor(status) {
  const s = status.toLowerCase();
  if (s.includes('seeding')) return '#00e676'; // Green
  if (s.includes('download')) return '#2196f3'; // Blue
  if (s.includes('stopped')) return '#9e9e9e'; // Gray
  if (s.includes('check') || s.includes('meta')) return '#ff9100'; // Orange
  return '#ffea00'; // Yellow (Catch all)
}

/**
 * Parse the raw table output from `transmission-remote`.
 * * The output from `transmission-remote -l` typically looks like this:
 * * ID   Done   Have  ETA  Up    Down  Ratio  Status       Name
 * 1    100%   2.1 GB Done 0.0   0.0   0.00   Seeding      Ubuntu 20.04 ISO
 * 2    45%    1.0 GB 1hr  50.0  2000  0.50   Downloading  Debian Netinst
 * Sum:        3.1 GB      50.0  2000
 * * @param {string} output - Raw command output
 * @returns {Object} { status: 'OK'|'STOPPED'|'AUTH_ERROR', torrents: Array }
 */
function parseOutput(output) {
  const clean = output ? output.trim() : '';

  if (clean === 'CONTAINER_STOPPED') return {status: 'STOPPED', torrents: []};
  if (clean === 'AUTH_ERROR') return {status: 'AUTH_ERROR', torrents: []};
  if (!clean) return {status: 'OK', torrents: []};

  const lines = clean.split('\n');

  // Filter out the Header row (starts with ID) and Footer row (starts with Sum:)
  const dataLines = lines.filter(l => !l.trim().startsWith('ID') && !l.trim().startsWith('Sum:'));

  const torrents = dataLines
    .map(line => {
      // Parse by splitting on multiple spaces (more reliable than regex for variable-width columns)
      const parts = line.trim().split(/\s{2,}/);
      // Column layout: ID, Done, Have, ETA, Up, Down, Ratio, Status, Name
      if (parts.length >= 9) {
        return {
          id: parts[0],
          percent: parts[1].replace('%', ''),
          up: parts[4] || '0.0',
          down: parts[5] || '0.0',
          status: parts[7],
          name: parts.slice(8).join(' ') // Name may contain spaces, join remaining parts
        };
      }

      // Fallback regex parsing if split method fails
      const match = line.match(
        /^\s*(\d+)\s+(\d+)%\s+[\d.]+\s+\w+\s+([\d.]+)\s+([\d.]+)\s+[\d.]+\s+(Seeding|Downloading|Stopped|Finished|Idle|Up & Down|Verifying|Queued)\s+(.+)$/i
      );

      if (match) {
        return {
          id: match[1],
          percent: match[2],
          up: match[3] || '0.0',
          down: match[4] || '0.0',
          status: match[5],
          name: match[6]
        };
      }

      return null;
    })
    .filter(Boolean)
    .sort((a, b) => {
      // Sort priority: Downloading > Seeding > Inactive
      const aStatus = (a.status || '').toLowerCase();
      const bStatus = (b.status || '').toLowerCase();
      
      const aIsDownloading = aStatus.includes('download');
      const bIsDownloading = bStatus.includes('download');
      const aIsSeeding = aStatus.includes('seeding');
      const bIsSeeding = bStatus.includes('seeding');
      
      // Downloads first
      if (aIsDownloading && !bIsDownloading) return -1;
      if (!aIsDownloading && bIsDownloading) return 1;
      
      // Then seeds
      if (aIsSeeding && !bIsSeeding) return -1;
      if (!aIsSeeding && bIsSeeding) return 1;
      
      // Inactive at bottom (maintain original order for same priority)
      return 0;
    });

  return {status: 'OK', torrents};
}
