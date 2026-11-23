import { env } from '../config/env';

function parts(d: Date) {
  const f = new Intl.DateTimeFormat('en-CA', {
    timeZone: env.TIMEZONE,
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', hour12: false, weekday: 'short',
  });
  const out: Record<string, string> = {};
  for (const p of f.formatToParts(d)) out[p.type] = p.value;
  return out;
}

/** Today's calendar date in the company time zone, as UTC midnight (matches @db.Date columns). */
export function localToday(now = new Date()): Date {
  const p = parts(now);
  return new Date(Date.UTC(Number(p.year), Number(p.month) - 1, Number(p.day)));
}

export const localHour = (now = new Date()) => Number(parts(now).hour) % 24;

export function isWeekdayLocal(now = new Date()): boolean {
  const w = parts(now).weekday;
  return w !== 'Sat' && w !== 'Sun';
}

/** "2026-10-19" for a UTC-midnight date value. */
export const ymd = (d: Date) => d.toISOString().slice(0, 10);

/** Minutes since local midnight in the company time zone. */
export const localMinutes = (d: Date) => (Number(parts(d).hour) % 24) * 60 + Number(parts(d).minute);

/** The company-time-zone calendar date of an instant, as "YYYY-MM-DD". */
export const localYmd = (d: Date) => ymd(localToday(d));

function tzOffsetMinutes(utc: Date): number {
  const p = parts(utc);
  const asUtc = Date.UTC(Number(p.year), Number(p.month) - 1, Number(p.day), Number(p.hour) % 24, Number(p.minute));
  return Math.round((asUtc - utc.getTime()) / 60000);
}

/** The instant when it is [hour]:[minute] on the given local calendar date (UTC-midnight value). */
export function zonedTime(localDate: Date, hour: number, minute: number): Date {
  const naive = Date.UTC(localDate.getUTCFullYear(), localDate.getUTCMonth(), localDate.getUTCDate(), hour, minute);
  return new Date(naive - tzOffsetMinutes(new Date(naive)) * 60000);
}
