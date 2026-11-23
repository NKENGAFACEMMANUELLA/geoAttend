/**
 * Attendance "engine": works out each person's status for a day, and builds the
 * four reports. Pure functions (no database, no environment) so they are testable.
 * Dates are plain "YYYY-MM-DD" strings in the company time zone.
 */
export type Status = 'present' | 'late' | 'absent' | 'leave';

export interface EmpRef {
  id: string;
  name: string;
  code: string;
  position: string;
  department: string;
  hireDate: string;
}
export interface AttRec {
  employeeId: string;
  date: string;
  status: Status;
  clockIn: Date | null;
}
export interface LeaveSpan {
  employeeId: string;
  start: string;
  end: string;
}
export interface DayCtx {
  today: string;
  /** True once the local time is past ABSENT_AFTER_HOUR. */
  cutoffPassed: boolean;
}

const MS_DAY = 86_400_000;
const toDate = (d: string) => new Date(`${d}T00:00:00Z`);
const toYmd = (d: Date) => d.toISOString().slice(0, 10);

export const addDaysYmd = (d: string, n: number) => toYmd(new Date(toDate(d).getTime() + n * MS_DAY));
export const isWeekdayYmd = (d: string) => {
  const w = toDate(d).getUTCDay();
  return w !== 0 && w !== 6;
};
/** Monday of the week containing [d]. */
export const mondayOf = (d: string) => addDaysYmd(d, -((toDate(d).getUTCDay() + 6) % 7));

/**
 * A recorded attendance wins; then approved leave; then a weekday with no record
 * counts as absent (today only after the cutoff hour). null = not a working day
 * for this person / nothing to report yet.
 */
export function resolveStatus(
  emp: EmpRef, day: string, rec: AttRec | undefined, onLeave: boolean, ctx: DayCtx,
): Status | null {
  if (rec) return rec.status;
  if (day < emp.hireDate) return null;
  if (onLeave) return 'leave';
  if (!isWeekdayYmd(day) || day > ctx.today) return null;
  if (day === ctx.today) return ctx.cutoffPassed ? 'absent' : null;
  return 'absent';
}

export class Lookup {
  private att = new Map<string, AttRec>();
  private leaves = new Map<string, LeaveSpan[]>();

  constructor(records: AttRec[], leaves: LeaveSpan[]) {
    for (const r of records) this.att.set(`${r.employeeId}|${r.date}`, r);
    for (const l of leaves) this.leaves.set(l.employeeId, [...(this.leaves.get(l.employeeId) ?? []), l]);
  }

  record(emp: EmpRef, day: string) {
    return this.att.get(`${emp.id}|${day}`);
  }

  status(emp: EmpRef, day: string, ctx: DayCtx): Status | null {
    const onLeave = (this.leaves.get(emp.id) ?? []).some((l) => l.start <= day && day <= l.end);
    return resolveStatus(emp, day, this.record(emp, day), onLeave, ctx);
  }
}

export interface DayRow {
  emp: EmpRef;
  status: Status;
  clockIn: Date | null;
}

export function dayRows(emps: EmpRef[], lookup: Lookup, day: string, ctx: DayCtx): DayRow[] {
  const rows: DayRow[] = [];
  for (const emp of emps) {
    const status = lookup.status(emp, day, ctx);
    if (status) rows.push({ emp, status, clockIn: lookup.record(emp, day)?.clockIn ?? null });
  }
  return rows;
}

export interface Counts {
  present: number;
  late: number;
  absent: number;
  onLeave: number;
  total: number;
  rate: number;
}

export function countOf(statuses: Status[]): Counts {
  const present = statuses.filter((s) => s === 'present').length;
  const late = statuses.filter((s) => s === 'late').length;
  const absent = statuses.filter((s) => s === 'absent').length;
  const onLeave = statuses.filter((s) => s === 'leave').length;
  const total = statuses.length;
  return { present, late, absent, onLeave, total, rate: total === 0 ? 0 : Math.round(((present + late) / total) * 100) };
}

// ---------------------------------------------------------------- reports

export const REPORT_TYPES = [
  'Weekly Attendance', 'Monthly Attendance', 'Attendance by Employee', 'Present/Late/Absent Summary',
] as const;
export type ReportType = (typeof REPORT_TYPES)[number];

export interface Report {
  title: string;
  period: string;
  scope: string;
  generatedAt: string;
  highlights: { label: string; value: string }[];
  columns: string[];
  rows: string[][];
}

const short = new Intl.DateTimeFormat('en-GB', { weekday: 'short', day: 'numeric', month: 'short', timeZone: 'UTC' });
const fmtShort = (d: string) => short.format(toDate(d)).replace(',', '');
const fmtLong = (d: string) =>
  new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC' }).format(toDate(d));
const fmtMonth = (d: string) =>
  new Intl.DateTimeFormat('en-GB', { month: 'long', year: 'numeric', timeZone: 'UTC' }).format(toDate(d));

/** The days of data a report needs, so the service can fetch them in one query. */
export function reportRange(type: ReportType, day: string, today: string): { from: string; to: string } {
  if (type === 'Present/Late/Absent Summary') return { from: day, to: day };
  if (type === 'Weekly Attendance') {
    const monday = mondayOf(day);
    const friday = addDaysYmd(monday, 4);
    return { from: monday, to: friday > today ? today : friday };
  }
  return { from: `${day.slice(0, 7)}-01`, to: day };
}

/** Returns null when the period has no working days. */
export function buildReport(p: {
  type: ReportType; day: string; scope: string; emps: EmpRef[]; lookup: Lookup; ctx: DayCtx; generatedAt: Date;
}): Report | null {
  const { type, day, scope, emps, lookup, ctx } = p;
  const base = { title: type, scope, generatedAt: p.generatedAt.toISOString() };
  const { from, to } = reportRange(type, day, ctx.today);

  if (type === 'Present/Late/Absent Summary') {
    const c = countOf(dayRows(emps, lookup, day, ctx).map((r) => r.status));
    const share = (n: number) => `${c.total === 0 ? 0 : Math.round((n / c.total) * 100)}%`;
    return {
      ...base, period: fmtLong(day),
      highlights: [
        { label: 'Attendance rate', value: `${c.rate}%` },
        { label: 'Present', value: `${c.present}` },
        { label: 'Absent', value: `${c.absent}` },
      ],
      columns: ['Status', 'Employees', 'Share'],
      rows: [
        ['Present', `${c.present}`, share(c.present)], ['Late', `${c.late}`, share(c.late)],
        ['Absent', `${c.absent}`, share(c.absent)], ['On Leave', `${c.onLeave}`, share(c.onLeave)],
        ['Total', `${c.total}`, '100%'],
      ],
    };
  }

  const days: string[] = [];
  for (let d = from; d <= to; d = addDaysYmd(d, 1)) if (isWeekdayYmd(d)) days.push(d);
  if (days.length === 0) return null;

  const period =
    type === 'Weekly Attendance'
      ? `${fmtShort(mondayOf(day))} - ${fmtShort(addDaysYmd(mondayOf(day), 4))} ${addDaysYmd(mondayOf(day), 4).slice(0, 4)}`
      : `${fmtMonth(day)} (to ${fmtShort(to)})`;

  if (type === 'Attendance by Employee') {
    let rateSum = 0;
    const rows = emps.map((emp) => {
      const statuses = days.map((d) => lookup.status(emp, d, ctx)).filter((s): s is Status => s !== null);
      const c = countOf(statuses);
      rateSum += c.rate;
      return [emp.name, emp.code, `${c.present}`, `${c.late}`, `${c.absent}`, `${c.onLeave}`, `${c.rate}%`];
    });
    return {
      ...base, period,
      highlights: [
        { label: 'Employees', value: `${emps.length}` },
        { label: 'Avg. attendance', value: emps.length ? `${Math.round(rateSum / emps.length)}%` : '0%' },
        { label: 'Days covered', value: `${days.length}` },
      ],
      columns: ['Employee', 'ID', 'Present', 'Late', 'Absent', 'On Leave', 'Rate'],
      rows,
    };
  }

  // Weekly / Monthly: one row per working day
  let rateSum = 0, lateTotal = 0, absentTotal = 0;
  const rows = days.map((d) => {
    const c = countOf(dayRows(emps, lookup, d, ctx).map((r) => r.status));
    rateSum += c.rate; lateTotal += c.late; absentTotal += c.absent;
    return [fmtShort(d), `${c.present}`, `${c.late}`, `${c.absent}`, `${c.onLeave}`, `${c.rate}%`];
  });
  return {
    ...base, period,
    highlights: [
      { label: 'Avg. attendance', value: `${Math.round(rateSum / days.length)}%` },
      { label: 'Late arrivals', value: `${lateTotal}` },
      { label: 'Absences', value: `${absentTotal}` },
    ],
    columns: ['Date', 'Present', 'Late', 'Absent', 'On Leave', 'Rate'],
    rows,
  };
}
