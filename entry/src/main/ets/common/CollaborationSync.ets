import { HttpUtil } from './HttpUtil';

/** 跨页面实例等待协同写操作完成，仅保留在途请求，不缓存用户内容。 */
export class CollaborationSync {
  private static pending: Promise<string>[] = [];

  static post(path: string): Promise<string> {
    const request = HttpUtil.post(path);
    CollaborationSync.pending.push(request);
    request.then(() => { CollaborationSync.remove(request); },
      () => { CollaborationSync.remove(request); });
    return request;
  }

  private static remove(request: Promise<string>): void {
    const index = CollaborationSync.pending.indexOf(request);
    if (index >= 0) CollaborationSync.pending.splice(index, 1);
  }

  static async waitForPending(): Promise<void> {
    while (CollaborationSync.pending.length > 0) {
      const snapshot = CollaborationSync.pending.slice();
      await Promise.all(snapshot.map((request: Promise<string>): Promise<void> =>
        request.then(() => {}, () => {})));
    }
  }
}
