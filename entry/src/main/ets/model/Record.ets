/**
 * 服药记录模型。字段对齐后端 MedicationRecordVO。
 */

export class MedicationRecordVO {
  id: number = 0;
  taskId: number = 0;
  medicineName: string = '';
  /** TAKEN已服/DELAYED稍后/SKIPPED跳过/UNCONFIRMED超时未确认 */
  action: string = '';
  actionTime: string = '';
  delayMinutes: number = 0;
  skipReason: string = '';
}

/**
 * 记录列表接口返回结构，对应 { code, message, data: MedicationRecordVO[] }。
 */
export class RecordListResult {
  code: number = 0;
  message: string = '';
  data: MedicationRecordVO[] = [];
}

/**
 * 解析服药记录列表。
 */
export function parseRecordList(jsonStr: string): RecordListResult {
  return JSON.parse(jsonStr) as RecordListResult;
}
