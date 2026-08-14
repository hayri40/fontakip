import test from 'node:test';
import assert from 'node:assert/strict';

import { createTurkeyMarketCalendar } from '../src/marketCalendar.js';

test('createTurkeyMarketCalendar skips weekends', () => {
  const calendar = createTurkeyMarketCalendar({
    holidays: {
      isHoliday() {
        return false;
      },
    },
  });

  assert.equal(
    calendar.isMarketOpen(new Date('2026-08-15T09:00:00Z')),
    false,
  );
  assert.equal(
    calendar.isMarketOpen(new Date('2026-08-17T09:00:00Z')),
    true,
  );
});

test('createTurkeyMarketCalendar skips Turkish public holidays', () => {
  const calendar = createTurkeyMarketCalendar();

  assert.equal(
    calendar.isMarketOpen(new Date('2026-01-01T09:00:00Z')),
    false,
  );
});
