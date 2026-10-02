import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { PlanVO, parsePlanList } from '../model/Plan';
import { parseSimpleResult } from '../model/RemindTask';

@Entry
@Component
struct PlanList {
  @State planList: PlanVO[] = [];
  @State loading: boolean = true;
  // 刷新版本号：操作成功后 +1，让 ForEach 的 key 变化，强制重建列表
  @State refreshVersion: number = 0;

  onPageShow() {
    this.loadList();
  }

  /**
   * 拉取计划列表。
   */
  async loadList() {
    try {
      const respStr = await HttpUtil.get('/api/plans');
      const result = parsePlanList(respStr);
      if (result.code === 200) {
        this.planList = result.data.slice();
        this.refreshVersion++;
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '加载计划失败，请检查网络' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 状态转中文。
   */
  statusText(status: string): string {
    if (status === 'ACTIVE') return '进行中';
    if (status === 'PAUSED') return '已暂停';
    if (status === 'FINISHED') return '已结束';
    if (status === 'CANCELLED') return '已取消';
    return status;
  }

  /**
   * 状态对应的颜色。
   */
  statusColor(status: string): string {
    if (status === 'ACTIVE') return '#34c759';
    if (status === 'PAUSED') return '#ff9500';
    return '#999999';
  }

  /**
   * 把时间点数组拼成 "08:00 · 20:00"。
   */
  timesText(plan: PlanVO): string {
    const arr: string[] = [];
    for (let i = 0; i < plan.times.length; i++) {
      const t = plan.times[i].remindTime;
      if (t.length >= 5) {
        arr.push(t.substring(0, 5));
      }
    }
    return arr.join(' · ');
  }

  /**
   * 暂停计划。
   */
  async pausePlan(plan: PlanVO) {
    try {
      const respStr = await HttpUtil.post('/api/plans/' + plan.id + '/pause', undefined, true);
      const result = parseSimpleResult(respStr);
      if (result.code === 200) {
        promptAction.showToast({ message: '已暂停' });
        await this.loadList();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  /**
   * 恢复计划。
   */
  async resumePlan(plan: PlanVO) {
    try {
      const respStr = await HttpUtil.post('/api/plans/' + plan.id + '/resume', undefined, true);
      const result = parseSimpleResult(respStr);
      if (result.code === 200) {
        promptAction.showToast({ message: '已恢复' });
        await this.loadList();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  /**
   * 删除计划。
   */
  async deletePlan(plan: PlanVO) {
    try {
      const respStr = await HttpUtil.delete('/api/plans/' + plan.id);
      const result = parseSimpleResult(respStr);
      if (result.code === 200) {
        promptAction.showToast({ message: '已删除' });
        await this.loadList();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '删除失败，请重试' });
    }
  }


  build() {
    Column() {
      Text('我的计划')
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
      } else if (this.planList.length === 0) {
        Column() {
          Text('还没有用药计划')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.planList, (plan: PlanVO) => {
            ListItem() {
              Column() {
                // 上半部分：药品名 + 状态
                Row() {
                  Column() {
                    Text(plan.medicineName)
                      .fontSize(17)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                    Text('每天 ' + this.timesText(plan))
                      .fontSize(13)
                      .fontColor('#999999')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text(this.statusText(plan.status))
                    .fontSize(12)
                    .fontColor(this.statusColor(plan.status))
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor('#f0f0f0')
                    .borderRadius(10)
                }
                .width('100%')

                // 下半部分：操作按钮
                Row({ space: 10 }) {
                  if (plan.status === 'ACTIVE') {
                    Button('暂停')
                      .fontSize(13)
                      .height(32)
                      .backgroundColor('#ff9500')
                      .onClick(() => { this.pausePlan(plan); })
                  } else if (plan.status === 'PAUSED') {
                    Button('恢复')
                      .fontSize(13)
                      .height(32)
                      .backgroundColor('#34c759')
                      .onClick(() => { this.resumePlan(plan); })
                  }

                  Button('删除')
                    .fontSize(13)
                    .height(32)
                    .backgroundColor('#ff3b30')
                    .onClick(() => { this.deletePlan(plan); })
                }
                .width('100%')
                .justifyContent(FlexAlign.End)
                .margin({ top: 12 })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor('#ffffff')
              .borderRadius(12)
            }
          }, (plan: PlanVO) => plan.id.toString() + '_' + this.refreshVersion.toString())
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
