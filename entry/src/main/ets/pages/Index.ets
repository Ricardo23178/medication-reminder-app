import { router } from '@kit.ArkUI';

/**
 * 启动页：App 打开后立刻跳转到登录页。
 */
@Entry
@Component
struct Index {
  aboutToAppear() {
    // 短暂延时后跳登录页（给启动画面一点点停留时间）
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/Login' });
    }, 300);
  }

  build() {
    Column() {
      Text('用药提醒')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
