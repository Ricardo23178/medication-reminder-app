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
 * 注册请求体。字段对齐后端 RegisterRequest。
 * account: 4-32 位字母/数字/下划线；password: 6-32 位；phone 可选。
 */
export class RegisterRequest {
  account: string = '';
  password: string = '';
  confirmPassword: string = '';
  nickname: string = '';
  phone: string = '';
}

/**
 * 确认服药请求体。action: TAKEN已服 / DELAYED稍后 / SKIPPED跳过。
 * 稍后默认15分钟；clientRequestId用于同一次请求重试时去重。
 */
export class ConfirmRequest {
  action: string = '';
  delayMinutes?: number;
  clientRequestId: string = '';

  constructor(action: string) {
    this.action = action;
    this.clientRequestId = Date.now().toString() + '_' + action;
    if (action === 'DELAYED') {
      this.delayMinutes = 15;
    }
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

