import { router } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { CollaborationSync } from '../common/CollaborationSync';
import { parseSimpleResult } from '../model/RemindTask';
import { NotificationVO, NotificationPageResult,
  notificationTime } from '../model/Notification';

@Entry
@Component
struct Notifications {
  @State items: NotificationVO[] = [];
  @State unreadOnly: boolean = false;
  @State unreadCount: number = 0;
  @State loading: boolean = false;
  @State readingAll: boolean = false;
  @State error: string = '';
  @State hasMore: boolean = false;
  private beforeId: number | null = null;
  private generation: number = 0;
  private visible: boolean = false;

  onPageShow() {
    this.visible = true;
    this.load(false);
  }

  onPageHide() {
    this.visible = false;
    this.generation++;
    this.loading = false;
    this.readingAll = false;
    this.items = [];
  }

  aboutToDisappear() {
    this.onPageHide();
  }

  selectFilter(unread: boolean) {
    if (this.unreadOnly === unread || this.readingAll) return;
    this.unreadOnly = unread;
    this.generation++;
    this.loading = false;
    this.load(false);
  }

  clearData() {
    this.items = [];
    this.unreadCount = 0;
    this.hasMore = false;
    this.beforeId = null;
  }

  async load(more: boolean) {
    if (!this.visible || this.loading || this.readingAll) return;
    if (more && (!this.hasMore || this.beforeId === null)) return;
    const ticket = ++this.generation;
    this.loading = true;
    this.error = '';
    const cursor = this.beforeId;
    if (!more) this.clearData();
    let path = '/api/notifications?unreadOnly=' + this.unreadOnly + '&limit=20';
    if (more && cursor !== null) path += '&beforeId=' + cursor;
    try {
      await CollaborationSync.waitForPending();
      if (!this.visible || ticket !== this.generation) return;
      const result = JSON.parse(await HttpUtil.get(path)) as NotificationPageResult;
      if (!this.visible || ticket !== this.generation) return;
      if (result.code !== 200) {
        this.clearData();
        this.error = result.message || '消息加载失败，请重试';
        return;
      }
      this.items = more ? this.items.concat(result.data.items) : result.data.items.slice();
      this.unreadCount = result.data.unreadCount;
      this.beforeId = result.data.nextBeforeId;
      this.hasMore = result.data.hasMore;
    } catch (e) {
      if (!this.visible || ticket !== this.generation) return;
      this.clearData();
      this.error = '消息加载失败，请检查网络后重试';
    } finally {
      if (ticket === this.generation) this.loading = false;
    }
  }

  async readAll() {
    if (!this.visible || this.loading || this.readingAll || this.unreadCount === 0) return;
    const ticket = ++this.generation;
    this.readingAll = true;
    this.error = '';
    try {
      const result = parseSimpleResult(await CollaborationSync.post('/api/notifications/read-all'));
      if (!this.visible || ticket !== this.generation) return;
      if (result.code !== 200) {
        this.clearData();
        this.error = result.message || '全部已读失败，请重试';
        return;
      }
      this.readingAll = false;
      await this.load(false);
    } catch (e) {
      if (!this.visible || ticket !== this.generation) return;
      this.clearData();
      this.error = '全部已读失败，请检查网络后重试';
    } finally {
      if (ticket === this.generation) this.readingAll = false;
    }
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Button('返回').height(44).fontSize(15).onClick(() => { router.back(); })
        Text('消息中心').fontSize(26).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('刷新').height(44).fontSize(15).enabled(!this.loading && !this.readingAll)
          .onClick(() => { this.load(false); })
      }.width('100%').margin({ top: 48 })

      Row({ space: 10 }) {
        Button('全部').layoutWeight(1).height(44)
          .backgroundColor(this.unreadOnly ? '#e8f1ff' : '#0a59f7')
          .fontColor(this.unreadOnly ? '#0a59f7' : '#ffffff')
          .enabled(!this.readingAll).onClick(() => { this.selectFilter(false); })
        Button('未读').layoutWeight(1).height(44)
          .backgroundColor(this.unreadOnly ? '#0a59f7' : '#e8f1ff')
          .fontColor(this.unreadOnly ? '#ffffff' : '#0a59f7')
          .enabled(!this.readingAll).onClick(() => { this.selectFilter(true); })
      }.width('100%')

      Row({ space: 10 }) {
        Text(this.error !== '' ? '未读数暂不可用' :
          (this.loading && this.items.length === 0 ? '正在更新未读数…' : '未读 ' + this.unreadCount + ' 条'))
          .fontSize(14).fontColor('#666666').layoutWeight(1)
        Button(this.readingAll ? '正在标记…' : '全部已读').height(44).fontSize(14)
          .enabled(!this.loading && !this.readingAll && this.unreadCount > 0)
          .onClick(() => { this.readAll(); })
      }.width('100%')

      if (this.error !== '') {
        Column({ space: 16 }) {
          Text(this.error).fontSize(16).fontColor('#c32b25').textAlign(TextAlign.Center)
          Button('重新加载').height(48).onClick(() => { this.load(false); })
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.items.length === 0 && (this.loading || this.readingAll)) {
        Column() {
          LoadingProgress().width(40).height(40).color('#0a59f7')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.items.length === 0) {
        Text(this.unreadOnly ? '暂无未读消息' : '暂无消息')
          .fontSize(16).fontColor('#999999').layoutWeight(1).textAlign(TextAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.items, (item: NotificationVO) => {
            ListItem() {
              Button({ type: ButtonType.Normal }) {
                Column({ space: 8 }) {
                  Text((item.readFlag === 0 ? '未读 · ' : '') + item.title)
                    .fontSize(17).fontWeight(FontWeight.Medium).fontColor('#333333')
                    .width('100%').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.content).fontSize(14).fontColor('#666666').width('100%')
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(notificationTime(item.createTime)).fontSize(12).fontColor('#999999').width('100%')
                }.width('100%').alignItems(HorizontalAlign.Start).padding(16)
              }.width('100%').backgroundColor('#f5f7fa').borderRadius(12)
                .enabled(!this.readingAll && !this.loading)
                .onClick(() => { router.pushUrl({ url: 'pages/NotificationDetail', params: { id: item.id } }); })
            }
          }, (item: NotificationVO) => item.id.toString())
          if (this.hasMore) {
            ListItem() {
              Button(this.loading ? '正在加载…' : '加载更多').width('100%').height(48)
                .enabled(!this.loading && !this.readingAll).onClick(() => { this.load(true); })
            }
          }
        }.width('100%').layoutWeight(1).scrollBar(BarState.Auto)
      }
    }.width('100%').height('100%').padding({ left: 16, right: 16, bottom: 16 })
  }
}
