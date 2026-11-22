// Date keys (yyyy-MM-dd) and the "is this day open yet" rules. A day is open as
// soon as it has started somewhere on earth (UTC+14), so no time zone is locked out.

const HOUR = 3600 * 1000;
const DAY = 24 * HOUR;
const DATE = /^\d{4}-\d{2}-\d{2}$/;

/** The yyyy-MM-dd key of a unix-ms moment, in UTC */
export const dateKey = (ms) => new Date(ms).toISOString().slice(0, 10);

/** Unix ms of midnight UTC of a valid key, or null */
export function parseDate(key) {
  if (typeof key !== "string" || !DATE.test(key)) return null;
  const ms = Date.parse(key + "T00:00:00Z");
  return Number.isNaN(ms) || dateKey(ms) !== key ? null : ms;
}

export const addDays = (key, days) => dateKey(parseDate(key) + days * DAY);

/** Monday is 1 ... Sunday 7 */
export const isMonday = (key) => new Date(parseDate(key)).getUTCDay() === 1;

/** The newest date that has started somewhere (UTC+14) */
export const latestOpenDate = (now) => dateKey(now + 14 * HOUR);

/** True when `key` is today or earlier in at least one time zone */
export const isOpen = (key, now) => key <= latestOpenDate(now);

/**
 * Dates a score may be sent for: today or yesterday for the player. Today runs
 * from UTC-12 to UTC+14, so: from the day before "today in UTC-12" up to
 * "today in UTC+14".
 */
export function isScoreDate(key, now) {
  const earliest = addDays(dateKey(now - 12 * HOUR), -1);
  return key >= earliest && key <= latestOpenDate(now);
}
