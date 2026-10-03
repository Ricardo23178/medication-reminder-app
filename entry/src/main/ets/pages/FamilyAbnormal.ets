import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { AbnormalEventVO, parseAbnormalEventList } from '../model/Family';

/**
 * 家属异常页（家属协同第二步）。
 * 家属登录后，查看自己被授权的被照护方的异常事件（超时未确认等）。
 * 后端按「关系 ACTIVE」过滤，解绑后这里自然查不到，权限即时失效。
 */
@Entry
@Component
struct FamilyAbnormal {
  @State eventList: AbnormalEventVO[] = [];
  @State loading: boolean = true;
  @State refreshVersion: number = 0;

  onPageShow() {
    this.loadList();
  }

  /**
   * 拉取被照护方的异常事件。
   */
  async loadList() {
    try {
      const respStr = await HttpUtil.get('/api/family/abnormal-events');
      const result = parseAbnormalEventList(respStr);
      if (result.code === 200) {
        this.eventList = result.data.slice();
        this.refreshVersion++;
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '加载异常事件失败，请检查网络' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 异常类型转中文。
   */
  typeText(type: string): string {
    if (type === 'UNCONFIRMED_TIMEOUT') return '超时未确认服药';
    if (type === 'CONSECUTIVE_UNCONFIRMED') return '连续多次未确认';
    if (type === 'PLAN_ENDED_UNFINISHED') return '计划结束未完成';
    return type;
  }

  /**
   * 状态转中文。
   */
  statusText(status: string): string {
    if (status === 'OPEN') return '未处理';
    if (status === 'NOTIFIED') return '已通知';
    if (status === 'ACKNOWLEDGED') return '已知晓';
    if (status === 'CLOSED') return '已关闭';
    return status;
  }

  statusColor(status: string): string {
    if (status === 'OPEN') return '#ff3b30';
    if (status === 'NOTIFIED') return '#ff9500';
    if (status === 'ACKNOWLEDGED') return '#34c759';
    return '#999999';
  }

  /**
   * 把 "2026-10-03T10:00:00" 截成 "10-03 10:00"。
   */
  formatTime(s: string): string {
    if (s.length >= 16) {
      return s.substring(5, 16);
    }
    return s;
  }

  /**
   * 安全取药品名（后端可能返回 null）。
   */
  safeMedicine(e: AbnormalEventVO): string {
    return e.medicineName ? e.medicineName : '未知药品';
  }

  build() {
    Column() {
      Text('家属异常')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 8 })

      Text('被照护方最近未确认的用药异常')
        .fontSize(13)
        .fontColor('#999999')
        .margin({ bottom: 16 })

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
      } else if (this.eventList.length === 0) {
        Column() {
          Text('暂无异常')
            .fontSize(16)
            .fontColor('#999999')
          Text('被照护方按时服药，没有超时未确认的情况')
            .fontSize(13)
            .fontColor('#bbbbbb')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.eventList, (e: AbnormalEventVO) => {
            ListItem() {
              Column() {
                // 上半部分：被照护方昵称 + 状态标签
                Row() {
                  Text(e.userNickname ? e.userNickname : '被照护方')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                  Text(this.statusText(e.status))
                    .fontSize(12)
                    .fontColor(this.statusColor(e.status))
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor('#f0f0f0')
                    .borderRadius(10)
                    .margin({ left: 10 })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)

                // 药品 + 异常类型
                Text(this.safeMedicine(e) + ' · ' + this.typeText(e.type))
                  .fontSize(15)
                  .fontColor('#333333')
                  .margin({ top: 10 })
                  .width('100%')
                  .textAlign(TextAlign.Start)

                // 发生时间
                Text(this.formatTime(e.occurredAt))
                  .fontSize(13)
                  .fontColor('#999999')
                  .margin({ top: 6 })
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor('#ffffff')
              .borderRadius(12)
            }
          }, (e: AbnormalEventVO) => e.id.toString() + '_' + this.refreshVersion.toString())
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
