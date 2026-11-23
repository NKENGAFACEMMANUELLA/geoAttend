/** Pure attendance rules (no database), so they are easy to test. */
export interface ScheduleLike {
  startTime: string; // "08:00"
  gracePeriodMinutes: number;
}

export const DEFAULT_SCHEDULE: ScheduleLike = { startTime: '08:00', gracePeriodMinutes: 15 };

export const parseHm = (hm: string): number => {
  const [h, m] = hm.split(':').map(Number);
  return h * 60 + (m || 0);
};

/** Late only when the clock-in is after start time + grace period. */
export function statusForClockIn(localMinutes: number, schedule: ScheduleLike = DEFAULT_SCHEDULE): 'present' | 'late' {
  return localMinutes > parseHm(schedule.startTime) + schedule.gracePeriodMinutes ? 'late' : 'present';
}
