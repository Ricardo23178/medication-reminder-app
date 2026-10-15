import { preferences } from '@kit.ArkData';
import { router } from '@kit.ArkUI';
import { Constants } from '../common/Constants';
import { HttpUtil } from '../common/HttpUtil';
import { CollaborationSync } from '../common/CollaborationSync';
import { UnreadCountResult } from '../model/Notification';

/**
 * 「我的」Tab 页：消息中心、服药记录及账号操作。
 */
@Component
export struct MyPage {
  @Prop @Watch('onRefresh') currentTab: number = 4;
  @Prop @Watch('onRefresh') refreshTick: number = 0;
  @Prop @Watch('onRefresh') pageVisible: boolean = true;
  @State nickname: string = '用户';
  @State unreadCount: number = 0;
  @State countLoading: boolean = false;
  @State countError: boolean = false;
  private countGeneration: number = 0;
  private active: boolean = true;

  async aboutToAppear() {
    this.active = true;
    try {
      const prefs = await preferences.getPreferences(getContext(), 'medication');
      const name = await prefs.get(Constants.KEY_NICKNAME, '用户') as string;
      if (name !== '') {
        this.nickname = name;
      }
    } catch (e) {
      this.nickname = '用户';
    }
    if (this.active && this.pageVisible && this.currentTab === 4) this.loadUnreadCount();
  }

  aboutToDisappear() {
    this.active = false;
    this.countGeneration++;
  }

  onRefresh() {
    if (this.pageVisible && this.currentTab === 4) {
      this.loadUnreadCount();
    } else {
      this.countGeneration++;
      this.countLoading = false;
      this.unreadCount = 0;
    }
  }

  async loadUnreadCount() {
    if (!this.active || !this.pageVisible || this.currentTab !== 4 || this.countLoading) return;
    const ticket = ++this.countGeneration;
    this.countLoading = true;
    this.countError = false;
    this.unreadCount = 0;
    try {
      await CollaborationSync.waitForPending();
      if (!this.active || !this.pageVisible || this.currentTab !== 4 || ticket !== this.countGeneration) return;
      const result = JSON.parse(await HttpUtil.get('/api/notifications/unread-count')) as UnreadCountResult;
      if (!this.active || !this.pageVisible || this.currentTab !== 4 || ticket !== this.countGeneration) return;
      if (result.code === 200) this.unreadCount = result.data;
      else this.countError = true;
    } catch (e) {
      if (!this.active || !this.pageVisible || this.currentTab !== 4 || ticket !== this.countGeneration) return;
      this.countError = true;
    } finally {
      if (ticket === this.countGeneration) this.countLoading = false;
    }
  }

  /**
   * 退出登录：清空本地 token/昵称/userId，回登录页。
   */
  async logout() {
    this.countGeneration++;
    this.active = false;
    try {
      const prefs = await preferences.getPreferences(getContext(), 'medication');
      await prefs.delete(Constants.KEY_TOKEN);
      await prefs.delete(Constants.KEY_NICKNAME);
      await prefs.delete(Constants.KEY_USER_ID);
      await prefs.flush();
    } catch (e) {
      // 忽略，直接跳登录页
    }
    router.replaceUrl({ url: 'pages/Login' });
  }

  build() {
    Scroll() {
      Column() {
      // 头像占位：昵称首字
      Text(this.nickname.length > 0 ? this.nickname.substring(0, 1) : '用')
        .fontSize(30)
        .fontColor('#ffffff')
        .width(72)
        .height(72)
        .textAlign(TextAlign.Center)
        .borderRadius(36)
        .backgroundColor('#0a59f7')
        .margin({ top: 60 })

      Text(this.nickname)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16 })

      Text('普通用户')
        .fontSize(13)
        .fontColor('#999999')
        .margin({ top: 6 })

      Button({ type: ButtonType.Normal }) {
        Row({ space: 12 }) {
          Text('消息中心').fontSize(16).fontColor('#333333').layoutWeight(1)
          if (this.countLoading) {
            Text('查询中…').fontSize(13).fontColor('#999999')
          } else if (this.countError) {
            Text('未读数暂不可用').fontSize(13).fontColor('#999999')
          } else if (this.unreadCount > 0) {
            Text(this.unreadCount > 99 ? '99+' : this.unreadCount.toString())
              .fontSize(13).fontColor('#ffffff').padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#ff3b30').borderRadius(12)
          }
          Text('›').fontSize(20).fontColor('#999999')
        }.width('100%').padding(16)
      }.width('80%').backgroundColor('#f5f7fa').borderRadius(12).margin({ top: 32 })
        .onClick(() => { router.pushUrl({ url: 'pages/Notifications' }); })
      if (this.countError) {
        Button('重试未读数').height(44).fontSize(14).backgroundColor('#e8f1ff').fontColor('#0a59f7')
          .margin({ top: 8 }).onClick(() => { this.loadUnreadCount(); })
      }

      // 服药记录入口
      Button({ type: ButtonType.Normal }) {
        Row() {
        Text('服药记录')
          .fontSize(16)
          .fontColor('#333333')
          .layoutWeight(1)
        Text('›')
          .fontSize(20)
          .fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      }.width('80%')
      .margin({ top: 12 })
      .backgroundColor('#f5f7fa')
      .borderRadius(12)
      .onClick(() => {
        router.pushUrl({ url: 'pages/RecordList' });
      })

      Button('退出登录')
        .fontSize(16)
        .width('80%')
        .height(48)
        .margin({ top: 24 })
        .backgroundColor('#ff3b30')
        .onClick(() => {
          this.logout();
        })
      }.width('100%').padding({ bottom: 32 })
    }.width('100%').height('100%').scrollBar(BarState.Auto)
  }
}
