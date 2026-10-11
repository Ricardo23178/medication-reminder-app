import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { MedicationRecordVO, parseRecordList } from '../model/Record';

/**
 * 服药记录列表页。展示当前用户的服药操作明细（哪味药、什么操作、什么时间）。
 * 入口：我的页「服药记录」。
 */
@Entry
@Component
struct RecordList {
  @State recordList: MedicationRecordVO[] = [];
  @State loading: boolean = true;

  async aboutToAppear() {
    await this.loadList();
  }

  async loadList() {
    try {
      const respStr = await HttpUtil.get('/api/records');
      const result = parseRecordList(respStr);
      if (result.code === 200) {
        this.recordList = result.data.slice();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '加载记录失败，请检查网络' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 动作转中文。
   */
  actionText(action: string): string {
    if (action === 'TAKEN') return '已服用';
    if (action === 'DELAYED') return '稍后';
    if (action === 'SKIPPED') return '跳过';
    if (action === 'UNCONFIRMED') return '未确认';
    return action;
  }

  /**
   * 动作对应颜色。
   */
  actionColor(action: string): string {
    if (action === 'TAKEN') return '#34c759';
    if (action === 'DELAYED') return '#ff9500';
    if (action === 'SKIPPED') return '#8e8e93';
    return '#ff3b30';
  }

  /**
   * 把 "2026-10-03T08:00:00" 截成 "10-03 08:00"。
   */
  formatTime(s: string): string {
    if (s.length >= 16) {
      return s.substring(0, 10) + ' ' + s.substring(11, 16);
    }
    return s;
  }

  build() {
    Column() {
      Text('服药记录')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 20 })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#0a59f7')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.recordList.length === 0) {
        Column() {
          Text('还没有服药记录')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.recordList, (r: MedicationRecordVO) => {
            ListItem() {
              Row() {
                // 左侧：药品名 + 时间
                Column() {
                  Text(r.medicineName === '' ? '未知药品' : r.medicineName)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                  Text(this.formatTime(r.actionTime))
                    .fontSize(13)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 右侧：动作标签
                Text(this.actionText(r.action))
                  .fontSize(14)
                  .fontColor('#ffffff')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor(this.actionColor(r.action))
                  .borderRadius(14)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .backgroundColor('#ffffff')
              .borderRadius(12)
            }
          }, (r: MedicationRecordVO) => r.id.toString())
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
