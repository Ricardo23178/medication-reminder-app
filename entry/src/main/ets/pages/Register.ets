import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { HttpUtil } from '../common/HttpUtil';
import { Constants } from '../common/Constants';
import { parseLoginResult } from '../model/UserInfo';
import { RegisterRequest } from '../model/Request';

/**
 * 注册页。注册成功后自动登录（后端返回 token），直接进主框架。
 */
@Entry
@Component
struct Register {
  @State account: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickname: string = '';
  @State phone: string = '';
  @State loading: boolean = false;

  /**
   * 注册：调后端 POST /api/auth/register，成功即登录。
   */
  async doRegister() {
    if (this.account.trim() === '' || this.password === '' ||
      this.confirmPassword === '' || this.nickname.trim() === '') {
      promptAction.showToast({ message: '请填写账号、密码和昵称' });
      return;
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次输入的密码不一致' });
      return;
    }

    this.loading = true;
    try {
      const req = new RegisterRequest();
      req.account = this.account.trim();
      req.password = this.password;
      req.confirmPassword = this.confirmPassword;
      req.nickname = this.nickname.trim();
      req.phone = this.phone.trim();

      const respStr = await HttpUtil.post('/api/auth/register', req, false);
      const resp = parseLoginResult(respStr);
      if (resp.code === 200) {
        // 注册成功即登录：存 token 和用户信息
        await HttpUtil.saveToken(resp.data.token);
        const prefs = await preferences.getPreferences(getContext(), 'medication');
        await prefs.put(Constants.KEY_NICKNAME, resp.data.user.nickname);
        await prefs.put(Constants.KEY_USER_ID, resp.data.user.id);
        await prefs.flush();

        promptAction.showToast({ message: '注册成功' });
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
      Text('注册账号')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 8 })

      Text('用药提醒与家属协同系统')
        .fontSize(16)
        .fontColor('#999999')
        .margin({ bottom: 50 })

      TextInput({ placeholder: '账号（4-32位字母/数字/下划线）', text: this.account })
        .onChange((value: string) => { this.account = value; })
        .height(50)
        .margin({ left: 30, right: 30, bottom: 14 })

      TextInput({ placeholder: '昵称', text: this.nickname })
        .onChange((value: string) => { this.nickname = value; })
        .height(50)
        .margin({ left: 30, right: 30, bottom: 14 })

      TextInput({ placeholder: '密码（6-32位）', text: this.password })
        .type(InputType.Password)
        .onChange((value: string) => { this.password = value; })
        .height(50)
        .margin({ left: 30, right: 30, bottom: 14 })

      TextInput({ placeholder: '确认密码', text: this.confirmPassword })
        .type(InputType.Password)
        .onChange((value: string) => { this.confirmPassword = value; })
        .height(50)
        .margin({ left: 30, right: 30, bottom: 14 })

      TextInput({ placeholder: '手机号（选填）', text: this.phone })
        .onChange((value: string) => { this.phone = value; })
        .height(50)
        .margin({ left: 30, right: 30, bottom: 40 })

      Button(this.loading ? '注册中...' : '注册')
        .width('80%')
        .height(50)
        .enabled(!this.loading)
        .onClick(() => { this.doRegister(); })

      Text('已有账号？返回登录')
        .fontSize(14)
        .fontColor('#0a59f7')
        .margin({ top: 20 })
        .onClick(() => { router.back(); })
    }
    .width('100%')
    .height('100%')
  }
}
