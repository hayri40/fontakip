import Holidays from 'date-holidays';

const ISTANBUL_TIME_ZONE = 'Europe/Istanbul';

function getIstanbulDateParts(date) {
  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: ISTANBUL_TIME_ZONE,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    weekday: 'short',
  });

  const parts = formatter.formatToParts(date);
  const values = {};

  for (const part of parts) {
    if (part.type !== 'literal') {
      values[part.type] = part.value;
    }
  }

  return values;
}

function toIstanbulMiddayDate({ year, month, day }) {
  return new Date(
    Date.UTC(
      Number(year),
      Number(month) - 1,
      Number(day),
      9,
      0,
      0,
      0,
    ),
  );
}

function isWeekend(weekday) {
  return weekday === 'Sat' || weekday === 'Sun';
}

export function createTurkeyMarketCalendar({ holidays = new Holidays('TR') } = {}) {
  return {
    isMarketOpen(date = new Date()) {
      const parts = getIstanbulDateParts(date);

      if (isWeekend(parts.weekday)) {
        return false;
      }

      const holiday = holidays.isHoliday(
        toIstanbulMiddayDate(parts),
      );

      return !holiday;
    },
  };
}
