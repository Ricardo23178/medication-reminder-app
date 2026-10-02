/**
 * 单条提醒任务。
 * @Observed：让列表项内部字段（如 confirmed）变化时，@ObjectLink 子组件能感知并刷新。
 */
@Observed
export class RemindTaskVO{
  id:number=0;
  medicineName:string='';
  dosagePerTime:number=0;
  dosageUnit:string='';
  mealRelation:number=0;
  scheduledAt:string='';
  status:string='';
  confirmed:boolean=false;
  action:string='';
}

export class RemindListResult {
  code: number = 0;
  message: string = '';
  data: RemindTaskVO[] = [];
}

export function parseRemindList(jsonStr: string):RemindListResult{
  return JSON.parse(jsonStr) as RemindListResult;
}

/**
 * 通用返回结构（仅 code/message，不含 data），
 * 用于「确认服药」这类只需判断是否成功的接口。
 * 后端统一返回 { code, message }。
 */
export class SimpleResult {
  code: number = 0;
  message: string = '';
}

export function parseSimpleResult(jsonStr: string): SimpleResult {
  return JSON.parse(jsonStr) as SimpleResult;
}