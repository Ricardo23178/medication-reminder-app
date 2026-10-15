/** 站内消息；仅包含用户可见的已发布内容。 */
export class NotificationVO {
  id: number = 0;
  type: string = '';
  title: string = '';
  content: string = '';
  bizType: string = '';
  bizId: number = 0;
  readFlag: number = 0;
  createTime: string = '';
  familyEvent: boolean = false;
}

export class NotificationPageVO {
  items: NotificationVO[] = [];
  unreadCount: number = 0;
  nextBeforeId: number | null = null;
  hasMore: boolean = false;
}

export class NotificationPageResult {
  code: number = 0;
  message: string = '';
  data: NotificationPageVO = new NotificationPageVO();
}

export class NotificationResult {
  code: number = 0;
  message: string = '';
  data: NotificationVO = new NotificationVO();
}

export class UnreadCountResult {
  code: number = 0;
  message: string = '';
  data: number = 0;
}

export class NotificationRouteParams {
  id: number = 0;
}

export function notificationTime(value: string): string {
  return value ? value.replace('T', ' ') : '';
}
