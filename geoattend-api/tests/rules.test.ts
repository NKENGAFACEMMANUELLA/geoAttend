import assert from 'node:assert/strict';
import { test } from 'node:test';
import { haversineMeters } from '../src/utils/geo';
import { DEFAULT_SCHEDULE, parseHm, statusForClockIn } from '../src/modules/attendance/attendance.rules';

test('haversine: same point is 0 m, ~0.0001 degrees of latitude is ~11 m', () => {
  assert.equal(haversineMeters(4.1527, 9.241, 4.1527, 9.241), 0);
  const d = haversineMeters(4.1527, 9.241, 4.1528, 9.241);
  assert.ok(d > 10.5 && d < 11.7, `got ${d}`);
});

test('haversine: Buea to Limbe is roughly 25-30 km', () => {
  const d = haversineMeters(4.1527, 9.241, 4.0186, 9.204);
  assert.ok(d > 14_000 && d < 20_000, `got ${d}`);
});

test('parseHm', () => {
  assert.equal(parseHm('08:00'), 480);
  assert.equal(parseHm('17:30'), 1050);
});

test('late only after start + grace (default 08:00 + 15)', () => {
  assert.equal(statusForClockIn(7 * 60 + 50), 'present');
  assert.equal(statusForClockIn(8 * 60 + 15), 'present');
  assert.equal(statusForClockIn(8 * 60 + 16), 'late');
});

test('custom schedule is respected', () => {
  const s = { startTime: '09:00', gracePeriodMinutes: 0 };
  assert.equal(statusForClockIn(9 * 60, s), 'present');
  assert.equal(statusForClockIn(9 * 60 + 1, s), 'late');
  assert.equal(DEFAULT_SCHEDULE.gracePeriodMinutes, 15);
});
