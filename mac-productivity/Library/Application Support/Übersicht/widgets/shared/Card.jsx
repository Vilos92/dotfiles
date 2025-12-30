import {css} from 'uebersicht';

/*
 * Styles.
 */

export const cardStyle = (position = {}) => css`
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

export const headerStyle = css`
  font-weight: 600;
  margin-bottom: 8px;
  padding-bottom: 6px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  opacity: 0.8;
`;
