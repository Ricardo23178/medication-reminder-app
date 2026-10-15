import { router } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { CollaborationSync } from '../common/CollaborationSync';
import { NotificationVO, NotificationResult,
  NotificationRouteParams, notificationTime } from '../model/Notification';
import { parseSimpleResult } from '../model/RemindTask';

@Entry
@Component
struct NotificationDetail {
  @State message: NotificationVO | null = null;
  @State loading: boolean = false;
  @State error: string = '';
  private generation: number = 0;
  private visible: boolean = false;
  private messageId: number = 0;

  onPageShow() {
    this.visible = true;
    this.load();
  }

  onPageHide() {
    this.visible = false;
    this.generation++;
    this.loading = false;
    this.message = null;
  }

  aboutToDisappear() {
    this.onPageHide();
  }

  async load() {
    if (!this.visible || this.loading) return;
    const ticket = ++this.generation;
    this.message = null;
    this.error = '';
    if (this.messageId === 0) {
      const params = router.getParams() as NotificationRouteParams;
      if (params && params.id > 0) this.messageId = params.id;
    }
    if (this.messageId <= 0) {
      this.error = '消息不存在，请返回消息中心';
      return;
    }
    this.loading = true;
    try {
      await CollaborationSync.waitForPending();
      if (!this.visible || ticket !== this.generation) return;
      const result = JSON.parse(await HttpUtil.get('/api/notifications/' + this.messageId)) as NotificationResult;
      if (!this.visible || ticket !== this.generation) return;
      if (result.code !== 200) {
        this.error = result.message || '消息加载失败，请重试';
        return;
      }
      // 在标记已读时再次验证授权，两个请求都成功才显示正文。
      const readResult = parseSimpleResult(await CollaborationSync.post('/api/notifications/' + this.messageId + '/read'));
      if (!this.visible || ticket !== this.generation) return;
      if (readResult.code !== 200) {
        this.error = readResult.message || '标记已读失败，请重试';
        return;
      }
      this.message = result.data;
    } catch (e) {
      if (!this.visible || ticket !== this.generation) return;
      this.message = null;
      this.error = '消息加载失败，请检查网络后重试';
    } finally {
      if (ticket === this.generation) this.loading = false;
    }
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 16 }) {
        Button('返回').height(44).fontSize(15).onClick(() => { router.back(); })
        Text('消息详情').fontSize(26).fontWeight(FontWeight.Bold).layoutWeight(1)
      }.width('100%').margin({ top: 48 })
      if (this.loading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#0a59f7')
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.error !== '') {
        Column({ space: 16 }) {
          Text(this.error).fontSize(16).fontColor('#c32b25').textAlign(TextAlign.Center)
          Button('重试').height(48).onClick(() => { this.load(); })
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
      } else if (this.message !== null) {
        Scroll() {
          Column({ space: 16 }) {
            Text(this.message.title).fontSize(22).fontWeight(FontWeight.Bold).width('100%')
            Text(notificationTime(this.message.createTime)).fontSize(13).fontColor('#999999').width('100%')
            Text('已读').fontSize(13).fontColor('#0a59f7').width('100%')
            Text(this.message.content).fontSize(17).fontColor('#333333').lineHeight(28).width('100%')
              .copyOption(CopyOptions.InApp)
            if (this.message.familyEvent) {
              Button('查看家属异常').width('100%').height(48).backgroundColor('#0a59f7')
                .onClick(() => { router.pushUrl({ url: 'pages/FamilyAbnormal' }); })
            } else if (this.message.bizType === 'ABNORMAL_EVENT') {
              Button('查看服药记录').width('100%').height(48).backgroundColor('#0a59f7')
                .onClick(() => { router.pushUrl({ url: 'pages/RecordList' }); })
            }
          }.width('100%').alignItems(HorizontalAlign.Start).padding({ bottom: 24 })
        }.width('100%').layoutWeight(1).scrollBar(BarState.Auto)
      }
    }.width('100%').height('100%').padding({ left: 16, right: 16, bottom: 16 })
  }
}
