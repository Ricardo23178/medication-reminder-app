/**
 * 用药日历统计模型。字段对齐后端 CalendarStatVO。
 */

/**
 * 单日统计。
 */
export class DayStat {
  date: string = '';
  shouldCount: number = 0;
  takenCount: number = 0;
  delayedCount: number = 0;
  skippedCount: number = 0;
  unconfirmedCount: number = 0;
  completionRate: number = 0;
}

/**
 * 整体汇总。
 */
export class StatSummary {
  totalShould: number = 0;
  totalTaken: number = 0;
  totalDelayed: number = 0;
  totalSkipped: number = 0;
  totalUnconfirmed: number = 0;
  completionRate: number = 0;
}

/**
 * 日历统计返回体。
 */
export class CalendarStatVO {
  startDate: string = '';
  endDate: string = '';
  days: DayStat[] = [];
  summary: StatSummary = new StatSummary();
}

/**
 * 统计接口返回结构，对应 { code, message, data: CalendarStatVO }。
 */
export class CalendarStatResult {
  code: number = 0;
  message: string = '';
  data: CalendarStatVO = new CalendarStatVO();
}

/**
 * 解析日历统计。
 */
export function parseCalendarStat(jsonStr: string): CalendarStatResult {
  return JSON.parse(jsonStr) as CalendarStatResult;
}
