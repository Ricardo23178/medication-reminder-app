/**
 * 全局常量。
 * 注意：模拟器里访问宿主机（你电脑）的后端，不能用 localhost，
 * 要用 10.0.2.2 这个模拟器专用地址。
 * 真机调试时改成电脑的局域网 IP，例如 http://192.168.x.x:8080
 */
export class Constants {
  static readonly BASE_URL: string = 'http://10.175.105.183:8080';
  /** token 在本地存储里的 key */
  static readonly KEY_TOKEN: string = 'token';
  /** 用户昵称在本地存储里的 key */
  static readonly KEY_NICKNAME: string = 'nickname';
  /** 用户 id 在本地存储里的 key */
  static readonly KEY_USER_ID: string = 'userId';
}
