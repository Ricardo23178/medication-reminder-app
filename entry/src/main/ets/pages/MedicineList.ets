import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { Medicine, parseMedicineListResult } from '../model/Medicine';

/**
 * 「药品」Tab 页：药品列表 + 添加入口。
 * 已改成 @Component（不再 @Entry），由 Main 的 Tabs 承载。
 */
@Component
export struct MedicineListPage {
  @Prop currentTab: number = 1;
  @Prop @Watch('onRefresh') refreshTick: number = 0;
  @State medicineList: Medicine[] = [];
  @State loading: boolean = true;

  async aboutToAppear() {
    await this.loadList();
  }

  /**
   * refreshTick 变化（切到本 Tab 或从新增页返回）时刷新。
   */
  onRefresh() {
    if (this.currentTab === 1) {
      this.loadList();
    }
  }

  /**
   * 拉取药品列表。
   */
  async loadList() {
    try {
      const respStr = await HttpUtil.get('/api/medicines');
      const result = parseMedicineListResult(respStr);
      if (result.code === 200) {
        this.medicineList = result.data.slice();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '加载药品失败，请检查网络' });
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      Text('药品管理')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 60, bottom: 20 })

      if (this.loading) {
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
      } else if (this.medicineList.length === 0) {
        Column() {
          Text('还没有药品')
            .fontSize(16)
            .fontColor('#999999')
          Text('点击下方按钮添加')
            .fontSize(13)
            .fontColor('#bbbbbb')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 12 }) {
          ForEach(this.medicineList, (m: Medicine) => {
            ListItem() {
              Row() {
                Column() {
                  Text(m.name)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                  Text(m.specification === '' ? '无规格' : m.specification)
                    .fontSize(13)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(m.dosage === '' ? '' : m.dosage + ' ' + m.unit)
                  .fontSize(14)
                  .fontColor('#0a59f7')
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor('#ffffff')
              .borderRadius(12)
            }
          }, (m: Medicine) => m.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Off)
      }

      // 底部「添加药品」按钮
      Button('+ 添加药品')
        .width('90%')
        .height(50)
        .margin({ bottom: 20 })
        .backgroundColor('#0a59f7')
        .onClick(() => {
          router.pushUrl({ url: 'pages/MedicineAdd' });
        })
    }
    .width('100%')
    .height('100%')
  }
}
