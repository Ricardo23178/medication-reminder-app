import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { HttpUtil } from '../common/HttpUtil';
import { MedicineRequest } from '../model/Request';
import { parseSimpleResult } from '../model/RemindTask';

/**
 * 新增药品页。
 * 填名称/规格/剂量/单位/备注，保存时 POST /api/medicines。
 */
@Entry
@Component
struct MedicineAdd {
  @State name: string = '';
  @State specification: string = '';
  @State dosage: string = '';
  @State unit: string = '';
  @State remark: string = '';
  @State saving: boolean = false;

  /**
   * 保存药品。
   */
  async save() {
    if (this.name.trim() === '') {
      promptAction.showToast({ message: '请填写药品名称' });
      return;
    }

    this.saving = true;
    try {
      const req = new MedicineRequest();
      req.name = this.name.trim();
      req.specification = this.specification.trim();
      req.dosage = this.dosage.trim();
      req.unit = this.unit.trim();
      req.remark = this.remark.trim();
      req.enabled = 1;

      const respStr = await HttpUtil.post('/api/medicines', req);
      const result = parseSimpleResult(respStr);
      if (result.code === 200) {
        promptAction.showToast({ message: '保存成功' });
        router.back();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '保存失败，请重试' });
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
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('新增药品')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Blank()
        // 右侧占位，保持标题居中
        Text('    ')
          .fontSize(16)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })

      // 表单
      Column() {
        Text('药品名称 *')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 20, bottom: 8 })
        TextInput({ placeholder: '如：阿司匹林肠溶片', text: this.name })
          .onChange((v: string) => { this.name = v; })
          .height(48)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)

        Text('规格')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 16, bottom: 8 })
        TextInput({ placeholder: '如：100mg×30片', text: this.specification })
          .onChange((v: string) => { this.specification = v; })
          .height(48)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)

        Row() {
          Column() {
            Text('剂量')
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

        Text('备注')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 16, bottom: 8 })
        TextInput({ placeholder: '选填', text: this.remark })
          .onChange((v: string) => { this.remark = v; })
          .height(48)
          .backgroundColor('#f5f5f5')
          .borderRadius(8)

        Button(this.saving ? '保存中...' : '保存')
          .width('100%')
          .height(50)
          .margin({ top: 40 })
          .enabled(!this.saving)
          .onClick(() => {
            this.save();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}
