import { preferences } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { Constants } from '../common/Constants';
import { HttpUtil } from '../common/HttpUtil';
import { RemindTaskVO, parseRemindList, parseSimpleResult } from '../model/RemindTask';
import { ConfirmRequest } from '../model/Request';

/**
 * 单条提醒卡片（内部子组件，不导出）。
 * 适老化设计：时间、药名大字号，确认按钮做大（高 56、字 18），
 * 三个动作「已服用 / 稍后 / 跳过」直接平铺，减少操作步骤。
 */
@Component
struct RemindItem {
  @ObjectLink task: RemindTaskVO;
  onAction: (action: string) => void = () => {};

  /**
   * 把 "2026-10-02T08:00:00" 截成 "08:00"。
   */
  formatTime(scheduledAt: string): string {
    if (scheduledAt.length >= 16) {
      return scheduledAt.substring(11, 16);
    }
    return scheduledAt;
  }

  /**
   * 把 mealRelation 数字转成中文。
   */
  mealText(mealRelation: number): string {
    if (mealRelation === 1) return '餐前';
    if (mealRelation === 2) return '餐后';
    if (mealRelation === 3) return '晨起空腹';
    if (mealRelation === 4) return '睡前';
    return '';
  }

  /**
   * 已确认后的动作转中文。
   */
  actionText(action: string): string {
    if (action === 'TAKEN') return '已服用';
    if (action === 'DELAYED') return '已稍后';
    if (action === 'SKIPPED') return '已跳过';
    return '已确认';
  }

  build() {
    Column() {
      // 上部分：时间 + 药品信息
      Row() {
        // 左侧：时间
        Column() {
          Text(this.formatTime(this.task.scheduledAt))
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.task.confirmed ? '#999999' : '#333333')
          Text(this.mealText(this.task.mealRelation))
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width(80)
        .alignItems(HorizontalAlign.Start)

        // 中间：药品信息
        Column() {
          Text(this.task.medicineName)
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.task.confirmed ? '#999999' : '#333333')
          Text('剂量 ' + this.task.dosagePerTime + ' ' + this.task.dosageUnit)
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')

      // 下部分：三个大按钮 或 已确认状态
      if (this.task.confirmed) {
        Row() {
          Text(this.actionText(this.task.action))
            .fontSize(18)
            .fontColor('#999999')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 14 })
      } else {
        Row({ space: 12 }) {
          Button('已服用')
            .fontSize(18)
            .height(56)
            .layoutWeight(1)
            .backgroundColor('#34c759')
            .onClick(() => {
              this.onAction('TAKEN');
            })

          Button('稍后')
            .fontSize(18)
            .height(56)
            .layoutWeight(1)
            .backgroundColor('#ff9500')
            .onClick(() => {
              this.onAction('DELAYED');
            })

          Button('跳过')
            .fontSize(18)
            .height(56)
            .layoutWeight(1)
            .backgroundColor('#8e8e93')
            .onClick(() => {
              this.onAction('SKIPPED');
            })
        }
        .width('100%')
        .margin({ top: 14 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    .backgroundColor(this.task.confirmed ? '#f5f5f5' : '#ffffff')
    .borderRadius(12)
  }
}

/**
 * 「今日」Tab 页：今日服药提醒列表。
 * 已改成 @Component（不再 @Entry），由 Main 的 Tabs 承载。
 * currentTab / refreshTick 由 Main 传入：切到本 Tab 或从二级页返回时自动刷新。
 */
@Component
export struct HomePage {
  @Prop currentTab: number = 0;
  @Prop @Watch('onRefresh') refreshTick: number = 0;
  @State nickname: string = '用户';
  @State remindList: RemindTaskVO[] = [];
  @State loading: boolean = true;
  @State refreshVersion: number = 0;   // 确认后自增，强制 ForEach 重建

  async aboutToAppear() {
    // 读昵称（只在首次读一次）
    try {
      const prefs = await preferences.getPreferences(getContext(), 'medication');
      const name = await prefs.get(Constants.KEY_NICKNAME, '用户') as string;
      if (name !== '') {
        this.nickname = name;
      }
    } catch (e) {
      this.nickname = '用户';
    }
    // 首次加载
    await this.loadToday();
  }

  /**
   * refreshTick 变化（切到本 Tab 或从二级页返回）时刷新。
   */
  onRefresh() {
    if (this.currentTab === 0) {
      this.loadToday();
    }
  }

  /**
   * 拉取今天提醒列表。
   */
  async loadToday() {
    try {
      const respStr = await HttpUtil.get('/api/reminders/today');
      const result = parseRemindList(respStr);
      if (result.code === 200) {
        this.remindList = result.data.slice();
        this.refreshVersion++;
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '加载提醒失败，请检查网络' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 确认服药（已服/稍后/跳过）。
   * @param action TAKEN / DELAYED / SKIPPED
   */
  async confirmTake(task: RemindTaskVO, action: string) {
    try {
      const req = new ConfirmRequest(action);
      const respStr = await HttpUtil.post('/api/reminders/' + task.id + '/confirm', req);
      const result = parseSimpleResult(respStr);
      if (result.code === 200) {
        if (action === 'TAKEN') {
          promptAction.showToast({ message: '已确认服药' });
        } else if (action === 'DELAYED') {
          promptAction.showToast({ message: '已设为稍后' });
        } else if (action === 'SKIPPED') {
          promptAction.showToast({ message: '已跳过' });
        }
        await this.loadToday();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  build() {
    Column() {
      // 标题区
      Row() {
        Column() {
          Text('今日提醒')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
          Text('你好，' + this.nickname)
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('统计')
          .fontSize(14)
          .fontColor('#0a59f7')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#e8f1ff')
          .borderRadius(16)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Statistics' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ top: 60, bottom: 20 })

      if (this.loading) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#0a59f7')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.remindList.length === 0) {
        // 空态
        Column() {
          Text('今天没有服药提醒')
            .fontSize(18)
            .fontColor('#999999')
          Text('去「药品」和「计划」页添加吧')
            .fontSize(14)
            .fontColor('#bbbbbb')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 列表
        List({ space: 14 }) {
          ForEach(this.remindList, (task: RemindTaskVO) => {
            ListItem() {
              RemindItem({ task: task, onAction: (action: string) => { this.confirmTake(task, action); } })
            }
          }, (task: RemindTaskVO) => task.id.toString() + '_' + this.refreshVersion.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
  }
}
