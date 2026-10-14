import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { CalendarStatVO, DayStat, parseCalendarStat } from '../model/Statistics';

/**
 * 用药日历统计页（P2）。
 * 展示最近 30 天的服药完成情况：顶部汇总 + 按天列表（完成率 + 已服/未确认）。
 * 入口：今日页右上角「统计」。
 */
@Entry
@Component
struct Statistics {
  @State stat: CalendarStatVO = new CalendarStatVO();
  @State loading: boolean = true;

  async aboutToAppear() {
    await this.loadStat();
  }

  /**
   * 拉取最近 30 天统计。
   */
  async loadStat() {
    try {
      const respStr = await HttpUtil.get('/api/statistics/calendar');
      const result = parseCalendarStat(respStr);
      if (result.code === 200) {
        this.stat = result.data;
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '加载统计失败，请检查网络' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 把 "2026-10-03" 截成 "10-03"。
   */
  formatDate(date: string): string {
    if (date.length >= 10) {
      return date.substring(5, 10);
    }
    return date;
  }

  /**
   * 完成率对应的颜色：>=80 绿，>=50 橙，否则红。
   */
  rateColor(rate: number): string {
    if (rate >= 80) return '#34c759';
    if (rate >= 50) return '#ff9500';
    return '#ff3b30';
  }

  build() {
    Column() {
      // 标题
      Text('用药统计')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 16 })

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
      } else {
        Scroll() {
          Column() {
            // 顶部汇总卡片
            Column() {
              Text('近30天完成率')
                .fontSize(14)
                .fontColor('#999999')
              Text(this.stat.summary.completionRate + '%')
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.rateColor(this.stat.summary.completionRate))
                .margin({ top: 8 })

              Row({ space: 20 }) {
                Column() {
                  Text(this.stat.summary.totalTaken.toString())
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#34c759')
                  Text('已服')
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }

                Column() {
                  Text(this.stat.summary.totalUnconfirmed.toString())
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#ff3b30')
                  Text('未确认')
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }

                Column() {
                  Text(this.stat.summary.totalShould.toString())
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#333333')
                  Text('应完成')
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceEvenly)
              .margin({ top: 20 })
            }
            .width('100%')
            .padding({ top: 24, bottom: 24 })
            .backgroundColor('#ffffff')
            .borderRadius(16)

            // 按天明细
            Text('每日明细')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .textAlign(TextAlign.Start)
              .margin({ top: 20, bottom: 12 })

            ForEach(this.stat.days, (d: DayStat) => {
              Column() {
                Row() {
                  // 日期
                  Text(this.formatDate(d.date))
                    .fontSize(15)
                    .fontColor('#333333')
                    .width(60)

                  // 完成率进度条
                  Column() {
                    Row() {
                      Text(d.completionRate + '%')
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.rateColor(d.completionRate))
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.End)

                    // 简单进度条：用一条填充的 Row 模拟
                    Row() {
                      Row()
                        .width(Math.min(100, Math.max(0, d.completionRate)).toString() + '%')
                        .height(6)
                        .backgroundColor(this.rateColor(d.completionRate))
                        .borderRadius(3)
                    }
                    .width('100%')
                    .height(6)
                    .backgroundColor('#f0f0f0')
                    .borderRadius(3)
                    .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                  .margin({ left: 12, right: 12 })

                  // 已服/应完成
                  Text(d.takenCount + '/' + d.shouldCount)
                    .fontSize(13)
                    .fontColor('#999999')
                    .width(50)
                    .textAlign(TextAlign.End)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .backgroundColor('#ffffff')
                .borderRadius(12)
              }
            }, (d: DayStat) => d.date)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
  }
}
