import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { HttpUtil } from '../common/HttpUtil';
import { Constants } from '../common/Constants';
import { parseLoginResult } from '../model/UserInfo';
import { LoginRequest } from '../model/Request';

@Entry
@Component
struct Login {
  @State account: string = '';
  @State password: string = '';
  @State loading: boolean = false;

  /**
   * 登录：调后端 POST /api/auth/login
   */
  async doLogin() {
    if (this.account.trim() === '' || this.password === '') {
      promptAction.showToast({ message: '请输入账号和密码' });
      return;
    }

    this.loading = true;
    try {
      const req = new LoginRequest(this.account.trim(), this.password);
      const respStr = await HttpUtil.post('/api/auth/login', req, false);

      const resp = parseLoginResult(respStr);
      if (resp.code === 200) {
        // 存 token 和用户信息到本地
        await HttpUtil.saveToken(resp.data.token);
        const prefs = await preferences.getPreferences(getContext(), 'medication');
        await prefs.put(Constants.KEY_NICKNAME, resp.data.user.nickname);
        await prefs.put(Constants.KEY_USER_ID, resp.data.user.id);
        await prefs.flush();

        promptAction.showToast({ message: '登录成功' });
        router.replaceUrl({ url: 'pages/Main' });
      } else {
        promptAction.showToast({ message: resp.message });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络请求失败，请确认后端已启动' });
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      // 标题区
      Text('用药提醒')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 8 })

      Text('用药提醒与家属协同系统')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ bottom: 60 })

      // 账号输入
      TextInput({ placeholder: '请输入账号', text: this.account })
        .onChange((value: string) => {
          this.account = value;
        })
        .height(50)
        .margin({ left: 30, right: 30, bottom: 16 })

      // 密码输入
      TextInput({ placeholder: '请输入密码', text: this.password })
        .type(InputType.Password)
        .onChange((value: string) => {
          this.password = value;
        })
        .height(50)
        .margin({ left: 30, right: 30, bottom: 40 })

      // 登录按钮
      Button(this.loading ? '登录中...' : '登录')
        .width('80%')
        .height(50)
        .enabled(!this.loading)
        .onClick(() => {
          this.doLogin();
        })

      // 注册入口
      Text('还没有账号？去注册')
        .fontSize(14)
        .fontColor('#0a59f7')
        .margin({ top: 20 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/Register' });
        })
    }
    .width('100%')
    .height('100%')
  }
}
