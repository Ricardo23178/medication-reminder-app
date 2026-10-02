import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { Medicine, parseMedicineListResult } from '../model/Medicine';
import { PlanRequest } from '../model/Request';
import { parseSimpleResult } from '../model/RemindTask';

/**
 * 建计划页。
 * 选药品 + 填剂量/日期 + 选餐前餐后 + 添加服药时间点，保存调 POST /api/plans。
 */
@Entry
@Component
struct PlanAdd {
  @State medicineList: Medicine[] = [];
  @State selectedMedicineId: number = -1;   // -1 表示还没选
  @State selectedMedicineName: string = '';
  @State dosage: string = '';
  @State unit: string = '';
  @State startDate: string = '2026-10-02';
  @State mealRelation: number = 0;
  @State timeInput: string = '';            // 正在输入的时间点
  @State timeList: string[] = [];           // 已添加的时间点列表
  @State saving: boolean = false;

  async aboutToAppear() {
    await this.loadMedicines();
  }

  /**
   * 拉药品列表，供选择。
   */
  async loadMedicines() {
    try {
      const respStr = await HttpUtil.get('/api/medicines');
      const result = parseMedicineListResult(respStr);
      if (result.code === 200) {
        this.medicineList = result.data.slice();
      }
    } catch (e) {
      promptAction.showToast({ message: '加载药品失败' });
    }
  }

  /**
   * 选择药品。
   */
  selectMedicine(m: Medicine) {
    this.selectedMedicineId = m.id;
    this.selectedMedicineName = m.name;
    // 选了药，自动带出它的默认单位
    if (m.unit !== '') {
      this.unit = m.unit;
    }
  }

  /**
   * 选择餐前餐后。
   */
  selectMeal(relation: number) {
    this.mealRelation = relation;
  }

  /**
   * 添加一个时间点。
   */
  addTime() {
    const t = this.timeInput.trim();
    if (t === '') {
      promptAction.showToast({ message: '请输入时间，如 08:00' });
      return;
    }
    this.timeList = this.timeList.concat([t]);
    this.timeInput = '';
  }

  /**
   * 删除某个时间点。
   */
  removeTime(index: number) {
    const arr = this.timeList.slice();
    arr.splice(index, 1);
    this.timeList = arr;
  }

  /**
   * 保存计划。
   */
  async save() {
    if (this.selectedMedicineId < 0) {
      promptAction.showToast({ message: '请选择药品' });
      return;
    }
    if (this.timeList.length === 0) {
      promptAction.showToast({ message: '请至少添加一个服药时间点' });
      return;
    }

    this.saving = true;
    try {
      const req = new PlanRequest();
      req.medicineId = this.selectedMedicineId;
      req.dosagePerTime = this.dosage === '' ? 0 : Number(this.dosage);
      req.dosageUnit = this.unit;
      req.startDate = this.startDate;
      req.mealRelation = this.mealRelation;
      req.remindTimes = this.timeList;

      const respStr = await HttpUtil.post('/api/plans', req);
      const result = parseSimpleResult(respStr);
      if (result.code === 200) {
        // 建完计划，立刻触发一次「生成今日提醒」，让首页马上能看到新计划的时间点
        try {
          await HttpUtil.post('/api/reminders/generate-today', undefined, true);
        } catch (e) {
          // 生成失败不影响「计划已创建」的结果，忽略即可
        }
        promptAction.showToast({ message: '计划创建成功' });
        router.back();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '创建失败，请重试' });
    } finally {
      this.saving = false;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('← 返回')
          .fontSize(16)
          .fontColor('#0a59f7')
          .onClick(() => { router.back(); })
        Blank()
        Text('新建用药计划')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('    ')
          .fontSize(16)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      Scroll() {
        Column() {
          // 选药品
          Text('选择药品 *')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 16, bottom: 8 })
          if (this.selectedMedicineId < 0) {
            Text('点击下方选择一个药品')
              .fontSize(14)
              .fontColor('#999999')
              .width('100%')
              .height(48)
              .textAlign(TextAlign.Start)
              .backgroundColor('#f5f5f5')
              .borderRadius(8)
              .padding({ left: 12 })
          } else {
            Text('已选择：' + this.selectedMedicineName)
              .fontSize(14)
              .fontColor('#0a59f7')
              .width('100%')
              .height(48)
              .textAlign(TextAlign.Start)
              .backgroundColor('#e8f1ff')
              .borderRadius(8)
              .padding({ left: 12 })
          }

          // 药品选择列表（横向滚动胶囊）
          Scroll() {
            Row({ space: 10 }) {
              ForEach(this.medicineList, (m: Medicine) => {
                Text(m.name)
                  .fontSize(14)
                  .fontColor(this.selectedMedicineId === m.id ? '#ffffff' : '#333333')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .backgroundColor(this.selectedMedicineId === m.id ? '#0a59f7' : '#f0f0f0')
                  .borderRadius(18)
                  .onClick(() => { this.selectMedicine(m); })
              }, (m: Medicine) => m.id.toString())
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .margin({ top: 8 })

          // 剂量 + 单位
          Row() {
            Column() {
              Text('单次剂量')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              TextInput({ placeholder: '如：1', text: this.dosage })
                .onChange((v: string) => { this.dosage = v; })
                .height(48)
                .backgroundColor('#f5f5f5')
                .borderRadius(8)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column() {
              Text('单位')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              TextInput({ placeholder: '如：片', text: this.unit })
                .onChange((v: string) => { this.unit = v; })
                .height(48)
                .backgroundColor('#f5f5f5')
                .borderRadius(8)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
          }
          .width('100%')
          .margin({ top: 16 })

          // 开始日期
          Text('开始日期 *')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 16, bottom: 8 })
          TextInput({ placeholder: '格式 2026-10-02', text: this.startDate })
            .onChange((v: string) => { this.startDate = v; })
            .height(48)
            .backgroundColor('#f5f5f5')
            .borderRadius(8)

          // 餐前餐后
          Text('服用时机')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 16, bottom: 8 })
          Row({ space: 10 }) {
            this.mealButton(0, '不限')
            this.mealButton(1, '餐前')
            this.mealButton(2, '餐后')
            this.mealButton(3, '空腹')
            this.mealButton(4, '睡前')
          }
          .width('100%')

          // 服药时间点
          Text('服药时间点 *')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 16, bottom: 8 })

          // 已添加的时间点
          if (this.timeList.length > 0) {
            Column({ space: 8 }) {
              ForEach(this.timeList, (t: string, index: number) => {
                Row() {
                  Text(t)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .layoutWeight(1)
                  Text('删除')
                    .fontSize(13)
                    .fontColor('#ff3b30')
                    .onClick(() => { this.removeTime(index); })
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                .backgroundColor('#f5f5f5')
                .borderRadius(8)
              }, (t: string, index: number) => t + '_' + index.toString())
            }
            .width('100%')
            .margin({ bottom: 8 })
          }

          // 添加时间点
          Row({ space: 10 }) {
            TextInput({ placeholder: '输入时间 如 08:00', text: this.timeInput })
              .onChange((v: string) => { this.timeInput = v; })
              .height(48)
              .backgroundColor('#f5f5f5')
              .borderRadius(8)
              .layoutWeight(1)
            Button('添加')
              .fontSize(14)
              .height(48)
              .backgroundColor('#0a59f7')
              .onClick(() => { this.addTime(); })
          }
          .width('100%')

          // 保存按钮
          Button(this.saving ? '保存中...' : '保存计划')
            .width('100%')
            .height(50)
            .margin({ top: 40, bottom: 30 })
            .enabled(!this.saving)
            .onClick(() => { this.save(); })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 餐前餐后按钮（复用）。
   */
  @Builder
  mealButton(relation: number, label: string) {
    Text(label)
      .fontSize(14)
      .fontColor(this.mealRelation === relation ? '#ffffff' : '#333333')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(this.mealRelation === relation ? '#0a59f7' : '#f0f0f0')
      .borderRadius(18)
      .onClick(() => { this.selectMeal(relation); })
  }
}
