/**
 * 家属协同模型。字段对齐后端 FamilyRelationVO / AbnormalEventVO。
 *
 * 方向约定（重要，读错会全盘错）：
 *   ownerUserId  = 被照护方（吃药的人，发起邀请）
 *   familyUserId = 家属（关心的人，凭邀请码接受绑定）
 */

/**
 * 一条家属关系。字段对齐后端 FamilyRelationVO。
 */
export class FamilyRelationVO {
  id: number = 0;
  /** 被照护方 */
  ownerUserId: number = 0;
  ownerNickname: string = '';
  /** 家属 */
  familyUserId: number = 0;
  familyNickname: string = '';
  /** 关系称谓（父/母/子女/配偶） */
  relationType: string = '';
  /** PENDING/ACTIVE/REJECTED/REVOKED */
  relationStatus: string = '';
  /** 授权范围 */
  scope: string = '';
  /** 邀请码（仅 PENDING 期间有值） */
  inviteCode: string = '';
  inviteExpireAt: string = '';
  bindTime: string = '';
  unbindTime: string = '';
  createTime: string = '';
}

/**
 * 关系列表接口返回结构，对应 { code, message, data: FamilyRelationVO[] }。
 */
export class FamilyRelationListResult {
  code: number = 0;
  message: string = '';
  data: FamilyRelationVO[] = [];
}

/**
 * 解析家属关系列表。
 */
export function parseFamilyRelationList(jsonStr: string): FamilyRelationListResult {
  return JSON.parse(jsonStr) as FamilyRelationListResult;
}

/**
 * 单个关系返回结构（发起邀请/接受邀请时返回 data 是单个 FamilyRelationVO）。
 */
export class FamilyRelationResult {
  code: number = 0;
  message: string = '';
  data: FamilyRelationVO = new FamilyRelationVO();
}

/**
 * 解析单个家属关系。
 */
export function parseFamilyRelation(jsonStr: string): FamilyRelationResult {
  return JSON.parse(jsonStr) as FamilyRelationResult;
}

/**
 * 一条异常事件。字段对齐后端 AbnormalEventVO（第二步「家属异常」页用）。
 */
export class AbnormalEventVO {
  id: number = 0;
  userId: number = 0;
  userNickname: string = '';
  taskId: number = 0;
  /** UNCONFIRMED_TIMEOUT/CONSECUTIVE_UNCONFIRMED/PLAN_ENDED_UNFINISHED */
  type: string = '';
  /** OPEN/NOTIFIED/ACKNOWLEDGED/CLOSED */
  status: string = '';
  occurredAt: string = '';
  medicineName: string = '';
  scheduledAt: string = '';
  acknowledgedAt: string = '';
  createTime: string = '';
}

/**
 * 异常事件列表接口返回结构。
 */
export class AbnormalEventListResult {
  code: number = 0;
  message: string = '';
  data: AbnormalEventVO[] = [];
}

/**
 * 解析异常事件列表。
 */
export function parseAbnormalEventList(jsonStr: string): AbnormalEventListResult {
  return JSON.parse(jsonStr) as AbnormalEventListResult;
}
