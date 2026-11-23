import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  addDaysYmd, buildReport, countOf, dayRows, isWeekdayYmd, Lookup, mondayOf, reportRange, resolveStatus,
  type AttRec, type DayCtx, type EmpRef, type LeaveSpan,
} from '../src/modules/team/engine';

// 2026-10-19 is a Monday.
const emp = (id: string, name: string, hireDate = '2020-01-01'): EmpRef =>
  ({ id, name, code: `EMP${id}`, position: 'Analyst', department: 'Sales', hireDate });
const sarah = emp('1', 'Sarah Kim'), david = emp('2', 'David Lee'), mike = emp('3', 'Michael Brown');
const ctx = (today: string, cutoffPassed = true): DayCtx => ({ today, cutoffPassed });
const att = (employeeId: string, date: string, status: AttRec['status']): AttRec => ({ employeeId, date, status, clockIn: null });

test('date helpers', () => {
  assert.equal(isWeekdayYmd('2026-10-19'), true);
  assert.equal(isWeekdayYmd('2026-10-17'), false);
  assert.equal(mondayOf('2026-10-23'), '2026-10-19');
  assert.equal(mondayOf('2026-10-25'), '2026-10-19'); // Sunday belongs to the week that started Monday
  assert.equal(addDaysYmd('2026-10-31', 1), '2026-11-01');
});

test('resolveStatus: record > leave > absent rules', () => {
  const c = ctx('2026-10-21');
  assert.equal(resolveStatus(sarah, '2026-10-20', att('1', '2026-10-20', 'late'), false, c), 'late');
  assert.equal(resolveStatus(sarah, '2026-10-20', undefined, true, c), 'leave');
  assert.equal(resolveStatus(sarah, '2026-10-20', undefined, false, c), 'absent');     // past weekday, no record
  assert.equal(resolveStatus(sarah, '2026-10-17', undefined, false, c), null);          // Saturday
  assert.equal(resolveStatus(sarah, '2026-10-22', undefined, false, c), null);          // future
  assert.equal(resolveStatus(sarah, '2026-10-21', undefined, false, ctx('2026-10-21', false)), null);   // today, before cutoff
  assert.equal(resolveStatus(sarah, '2026-10-21', undefined, false, ctx('2026-10-21', true)), 'absent'); // today, after cutoff
  assert.equal(resolveStatus(emp('9', 'New Hire', '2026-10-21'), '2026-10-20', undefined, false, c), null); // before hire date
});

test('countOf and rate', () => {
  const c = countOf(['present', 'present', 'late', 'absent', 'leave']);
  assert.deepEqual([c.present, c.late, c.absent, c.onLeave, c.total, c.rate], [2, 1, 1, 1, 5, 60]);
  assert.equal(countOf([]).rate, 0);
});

test('dayRows skips people with nothing to report', () => {
  const lookup = new Lookup([att('1', '2026-10-20', 'present')], []);
  const rows = dayRows([sarah, david], lookup, '2026-10-20', ctx('2026-10-21'));
  assert.deepEqual(rows.map((r) => [r.emp.name, r.status]), [['Sarah Kim', 'present'], ['David Lee', 'absent']]);
  assert.equal(dayRows([sarah], lookup, '2026-10-17', ctx('2026-10-21')).length, 0); // weekend
});

const leaves: LeaveSpan[] = [{ employeeId: '3', start: '2026-10-20', end: '2026-10-21' }];
const records: AttRec[] = [
  att('1', '2026-10-19', 'present'), att('2', '2026-10-19', 'late'), att('3', '2026-10-19', 'present'),
  att('1', '2026-10-20', 'present'), att('2', '2026-10-20', 'present'),
];

test('weekly report: per-day rows, week of Mon 19 Oct, today is Wed 21 Oct', () => {
  const c = ctx('2026-10-21');
  const r = buildReport({ type: 'Weekly Attendance', day: '2026-10-21', scope: 'Sales', emps: [sarah, david, mike], lookup: new Lookup(records, leaves), ctx: c, generatedAt: new Date() })!;
  assert.deepEqual(reportRange('Weekly Attendance', '2026-10-21', '2026-10-21'), { from: '2026-10-19', to: '2026-10-21' });
  assert.equal(r.rows.length, 3); // Mon, Tue, Wed (Thu/Fri are in the future)
  assert.deepEqual(r.columns, ['Date', 'Present', 'Late', 'Absent', 'On Leave', 'Rate']);
  assert.deepEqual(r.rows[0].slice(1), ['2', '1', '0', '0', '100%']);                // Mon: all attended
  assert.deepEqual(r.rows[1].slice(1), ['2', '0', '0', '1', '67%']);                 // Tue: Michael on leave (counts in the total)
  assert.deepEqual(r.rows[2].slice(1), ['0', '0', '2', '1', '0%']);                // Wed (today, after cutoff): 2 absent, Michael on leave
  assert.equal(r.highlights[1].value, '1'); // late arrivals
  assert.match(r.period, /19 Oct - .*23 Oct 2026/);
});

test('by-employee report counts each person across the month so far', () => {
  const r = buildReport({ type: 'Attendance by Employee', day: '2026-10-21', scope: 'Sales', emps: [sarah, david, mike], lookup: new Lookup(records, leaves), ctx: ctx('2026-10-21', false), generatedAt: new Date() })!;
  const byName = Object.fromEntries(r.rows.map((row) => [row[0], row]));
  // Oct 1-21 working days with data; Sarah present Mon+Tue, absent on the other past weekdays.
  assert.equal(byName['Sarah Kim'][2], '2');
  assert.equal(byName['David Lee'][3], '1');            // one late day
  assert.equal(byName['Michael Brown'][5], '2');        // two leave days
  assert.equal(r.highlights[0].value, '3');
});

test('summary report for one day', () => {
  const r = buildReport({ type: 'Present/Late/Absent Summary', day: '2026-10-19', scope: 'Sales', emps: [sarah, david, mike], lookup: new Lookup(records, leaves), ctx: ctx('2026-10-21'), generatedAt: new Date() })!;
  assert.deepEqual(r.rows.map((x) => x[1]), ['2', '1', '0', '0', '3']);
  assert.equal(r.highlights[0].value, '100%');
});

test('a period with no working days gives null', () => {
  // Month starting on a weekend, reported on that weekend day
  const r = buildReport({ type: 'Monthly Attendance', day: '2026-08-01', scope: 'x', emps: [sarah], lookup: new Lookup([], []), ctx: ctx('2026-08-01'), generatedAt: new Date() });
  assert.equal(r, null);
});
