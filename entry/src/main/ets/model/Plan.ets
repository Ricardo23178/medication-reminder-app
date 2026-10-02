/**
 * 用药计划模型。字段对齐后端 PlanVO / PlanTime / PlanRequest。
 */

/**
 * 计划的时间点（对应后端 PlanTime 实体）。
 */
export class PlanTimeVO {
  id: number = 0;
  planId: number = 0;
  remindTime: string = '';
  sequenceNo: number = 0;
  enabled: number = 1;
}

/**
 * 单个计划（对应后端 PlanVO）。
 */
export class PlanVO {
  id: number = 0;
  medicineId: number = 0;
  medicineName: string = '';
  dosagePerTime: number = 0;
  dosageUnit: string = '';
  startDate: string = '';
  endDate: string = '';
  mealRelation: number = 0;
  status: string = '';
  remark: string = '';
  times: PlanTimeVO[] = [];
}

/**
 * 计划列表接口返回结构，对应 { code, message, data: PlanVO[] }。
 */
export class PlanListResult {
  code: number = 0;
  message: string = '';
  data: PlanVO[] = [];
}

/**
 * 解析计划列表。
 */
export function parsePlanList(jsonStr: string): PlanListResult {
  return JSON.parse(jsonStr) as PlanListResult;
}
