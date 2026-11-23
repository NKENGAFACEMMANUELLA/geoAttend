import './_env';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { isWeekdayLocal, localHour, localMinutes, localToday, localYmd, ymd, zonedTime } from '../src/utils/time';

test('company time zone is UTC+1 (Cameroon)', () => {
  const at = new Date('2026-10-19T07:05:00Z'); // 08:05 local
  assert.equal(localMinutes(at), 8 * 60 + 5);
  assert.equal(localHour(at), 8);
});

test('local date rolls over at local midnight, not UTC midnight', () => {
  assert.equal(localYmd(new Date('2026-10-18T23:30:00Z')), '2026-10-19'); // 00:30 Monday locally
  assert.equal(isWeekdayLocal(new Date('2026-10-18T22:30:00Z')), false); // 23:30 Sunday locally
  assert.equal(isWeekdayLocal(new Date('2026-10-18T23:30:00Z')), true);
});

test('zonedTime builds the instant for a local clock time', () => {
  const day = localToday(new Date('2026-10-19T12:00:00Z'));
  assert.equal(ymd(day), '2026-10-19');
  assert.equal(zonedTime(day, 8, 0).toISOString(), '2026-10-19T07:00:00.000Z');
});
