import { preferences } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { Constants } from '../common/Constants';
import { HttpUtil } from '../common/HttpUtil';
import { RemindTaskVO, parseRemindList, parseSimpleResult } from '../model/RemindTask';
import { ConfirmRequest } from '../model/Request';

/**
 * 单条提醒卡片。用 @ObjectLink 接收 RemindTaskVO，
 * 配合模型类的 @Observed，当 confirmed 等字段变化时能自动刷新这一项。
 */
@Component
struct RemindItem {
  @ObjectLink task: RemindTaskVO;
  onConfirm: () => void = () => {};

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

  build() {
    Row() {
      // 左侧：时间
      Column() {
        Text(this.formatTime(this.task.scheduledAt))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.task.confirmed ? '#999999' : '#333333')
        Text(this.mealText(this.task.mealRelation))
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width(70)
      .alignItems(HorizontalAlign.Start)

      // 中间：药品信息
      Column() {
        Text(this.task.medicineName)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.task.confirmed ? '#999999' : '#333333')
        Text('剂量 ' + this.task.dosagePerTime + ' ' + this.task.dosageUnit)
          .fontSize(13)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      // 右侧：确认按钮
      if (this.task.confirmed) {
        Text('已服用')
          .fontSize(14)
          .fontColor('#999999')
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      } else {
        Button('确认服药')
          .fontSize(14)
          .height(36)
          .backgroundColor('#0a59f7')
          .onClick(() => {
            this.onConfirm();
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(this.task.confirmed ? '#f5f5f5' : '#ffffff')
    .borderRadius(12)
  }
}

/**
 * 首页：今日服药提醒列表。
 */
@Entry
@Component
struct Home {
  @State nickname: string = '用户';
  @State remindList: RemindTaskVO[] = [];
  @State loading: boolean = true;
  @State refreshVersion: number = 0;   // 确认后自增，强制 ForEach 重建

  async aboutToAppear() {
    // 读昵称（只在首次进入读一次即可）
    try {
      const prefs = await preferences.getPreferences(getContext(), 'medication');
      const name = await prefs.get(Constants.KEY_NICKNAME, '用户') as string;
      if (name !== '') {
        this.nickname = name;
      }
    } catch (e) {
      this.nickname = '用户';
    }
  }

  /**
   * 每次页面显示都刷新提醒列表（含首次进入、从建计划/药品管理返回）。
   */
  onPageShow() {
    this.loadToday();
  }

  /**
   * 拉取今天提醒列表。
   */
  async loadToday() {
    try {
      const respStr = await HttpUtil.get('/api/reminders/today');
      const result = parseRemindList(respStr);
      if (result.code === 200) {
        // 用 slice() 包一层，生成全新数组引用
        this.remindList = result.data.slice();
        // 自增刷新版本，强制 ForEach 重建所有项
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
   * 确认服药。
   */
  async confirmTake(task: RemindTaskVO) {
    try {
      const req = new ConfirmRequest('TAKEN');
      const respStr = await HttpUtil.post('/api/reminders/' + task.id + '/confirm', req);
      const result = parseSimpleResult(respStr);
      if (result.code === 200) {
        promptAction.showToast({ message: '已确认服药' });
        // 确认成功后重新拉列表，拿后端最新 confirmed 状态
        await this.loadToday();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '确认失败，请重试' });
    }
  }

  build() {
    Column() {
      // 顶部标题 + 入口按钮
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

        Row({ space: 10 }) {
          Text('药品管理')
            .fontSize(15)
            .fontColor('#0a59f7')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#e8f1ff')
            .borderRadius(16)
            .onClick(() => {
              router.pushUrl({ url: 'pages/MedicineList' });
            })

          Text('建计划')
            .fontSize(15)
            .fontColor('#0a59f7')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#e8f1ff')
            .borderRadius(16)
            .onClick(() => {
              router.pushUrl({ url: 'pages/PlanAdd' });
            })
        }
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
            .fontSize(16)
            .fontColor('#999999')
          Text('先添加药品和用药计划吧')
            .fontSize(13)
            .fontColor('#bbbbbb')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 列表
        List({ space: 12 }) {
          ForEach(this.remindList, (task: RemindTaskVO) => {
            ListItem() {
              RemindItem({ task: task, onConfirm: () => { this.confirmTake(task); } })
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
