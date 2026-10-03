/**
 * 请求体模型。ArkTS 要求对象字面量必须有明确类型，
 * 所以每个接口的请求体都建一个 class。
 */

/**
 * 登录请求体。
 */
export class LoginRequest {
  account: string = '';
  password: string = '';

  constructor(account: string, password: string) {
    this.account = account;
    this.password = password;
  }
}

/**
 * 确认服药请求体。action: TAKEN已服 / DELAYED稍后 / SKIPPED跳过。
 * 先只做 TAKEN，其余字段留空即可。
 */
export class ConfirmRequest {
  action: string = '';

  constructor(action: string) {
    this.action = action;
  }
}

export class MedicineRequest{
  name:string='';
  specification:string='';
  dosage:string='';
  unit:string='';
  remark:string='';
  enabled:number=0;
}

/**
 * 建计划请求体。字段对齐后端 PlanRequest。
 */
export class PlanRequest {
  medicineId: number = 0;
  dosagePerTime: number = 0;
  dosageUnit: string = '';
  startDate: string = '';
  endDate: string = '';
  mealRelation: number = 0;
  remark: string = '';
  remindTimes: string[] = [];
}

/**
 * 发起家属绑定邀请请求体。字段对齐后端 InviteRequest。
 * relationType 称谓可选（父/母/子女/配偶），scope 授权范围可选。
 */
export class InviteRequest {
  relationType: string = '';
  scope: string = '';
}

/**
 * 接受家属绑定邀请请求体。字段对齐后端 AcceptInviteRequest。
 */
export class AcceptInviteRequest {
  inviteCode: string = '';

  constructor(inviteCode: string) {
    this.inviteCode = inviteCode;
  }
}

