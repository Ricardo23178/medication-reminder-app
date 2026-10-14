/**
 * 全局常量。
 * 本地模拟器调试先执行 hdc rport tcp:8080 tcp:8080，
 * 将设备的127.0.0.1:8080转发到电脑后端，避免依赖变化的Wi-Fi地址。
 * 真机调试时改成电脑的局域网 IP，例如 http://192.168.x.x:8080
 */
export class Constants {
  static readonly BASE_URL: string = 'http://127.0.0.1:8080';
  /** token 在本地存储里的 key */
  static readonly KEY_TOKEN: string = 'token';
  /** 用户昵称在本地存储里的 key */
  static readonly KEY_NICKNAME: string = 'nickname';
  /** 用户 id 在本地存储里的 key */
  static readonly KEY_USER_ID: string = 'userId';
}
