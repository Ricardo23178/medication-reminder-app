import { preferences } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import { Constants } from '../common/Constants';

/**
 * 「我的」Tab 页：显示昵称 + 退出登录。
 */
@Component
export struct MyPage {
  @State nickname: string = '用户';

  async aboutToAppear() {
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
   * 退出登录：清空本地 token/昵称/userId，回登录页。
   */
  async logout() {
    try {
      const prefs = await preferences.getPreferences(getContext(), 'medication');
      await prefs.delete(Constants.KEY_TOKEN);
      await prefs.delete(Constants.KEY_NICKNAME);
      await prefs.delete(Constants.KEY_USER_ID);
      await prefs.flush();
    } catch (e) {
      // 忽略，直接跳登录页
    }
    router.replaceUrl({ url: 'pages/Login' });
  }

  build() {
    Column() {
      // 头像占位：昵称首字
      Text(this.nickname.length > 0 ? this.nickname.substring(0, 1) : '用')
        .fontSize(30)
        .fontColor('#ffffff')
        .width(72)
        .height(72)
        .textAlign(TextAlign.Center)
        .borderRadius(36)
        .backgroundColor('#0a59f7')
        .margin({ top: 80 })

      Text(this.nickname)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16 })

      Text('普通用户')
        .fontSize(13)
        .fontColor('#999999')
        .margin({ top: 6 })

      Button('退出登录')
        .fontSize(16)
        .width('80%')
        .height(48)
        .margin({ top: 60 })
        .backgroundColor('#ff3b30')
        .onClick(() => {
          this.logout();
        })
    }
    .width('100%')
    .height('100%')
  }
}
