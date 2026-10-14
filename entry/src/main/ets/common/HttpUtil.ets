import { http } from '@kit.NetworkKit';
import { preferences } from '@kit.ArkData';
import { Constants } from './Constants';
import { router } from '@kit.ArkUI';

/**
 * 请求头对象。用 class 声明、字段写死，规避 ArkTS 下标访问限制。
 */
class HttpHeader {
  'Content-Type': string = 'application/json';
  Authorization?: string;
}

/**
 * 网络请求封装。
 * 统一做三件事：
 * 1. 拼 baseUrl
 * 2. 自动带 Bearer token（从本地 preferences 读）
 * 3. 把响应 body 转成字符串返回（页面自己 JSON.parse）
 */
export class HttpUtil {
  private static redirectingToLogin: boolean = false;
  private static sessionVersion: number = 0;

  /**
   * 读本地存储的 token。
   * 首次调用会异步创建 preferences 实例。
   */
  static async getToken(): Promise<string> {
    try {
      const prefs = await preferences.getPreferences(getContext(), 'medication');
      return await prefs.get(Constants.KEY_TOKEN, '') as string;
    } catch (e) {
      return '';
    }
  }

  /**
   * 保存 token 到本地。
   */
  static async saveToken(token: string): Promise<void> {
    HttpUtil.sessionVersion++;
    const prefs = await preferences.getPreferences(getContext(), 'medication');
    await prefs.put(Constants.KEY_TOKEN, token);
    await prefs.flush();
    HttpUtil.redirectingToLogin = false;
  }

  /**
   * 通用请求。
   * @param method  GET / POST / PUT / DELETE
   * @param path    接口路径，如 /api/auth/login
   * @param body    请求体（可选），POST 时传对象，内部转 JSON
   * @param needAuth 是否要带 token（业务接口都要，登录注册不要）
   * @returns 后端返回的原始字符串
   */
  static async request(method: http.RequestMethod, path: string,
    body?: Object, needAuth: boolean = true): Promise<string> {
    const httpRequest = http.createHttp();
    const url = Constants.BASE_URL + path;

    // 先构造 header 对象（class 声明，字段写死，避免下标访问报错）
    let header = new HttpHeader();
    let requestToken: string = '';
    const requestSessionVersion = HttpUtil.sessionVersion;
    // 业务接口自动带 token
    if (needAuth) {
      const token = await HttpUtil.getToken();
      requestToken = token;
      if (token !== '') {
        header.Authorization = 'Bearer ' + token;
      }
    }

    let options: http.HttpRequestOptions = {
      method: method,
      header: header,
      connectTimeout: 10000,
      readTimeout: 10000
    };

    // POST/PUT 带请求体
    if (body !== undefined && body !== null) {
      options.extraData = JSON.stringify(body);
    }

    try {
      const resp = await httpRequest.request(url, options);
      if (needAuth && resp.responseCode === 401) {
        const currentToken = await HttpUtil.getToken();
        if (HttpUtil.redirectingToLogin || requestSessionVersion !== HttpUtil.sessionVersion
          || requestToken !== currentToken) {
          return resp.result as string;
        }
        HttpUtil.redirectingToLogin = true;
        const prefs = await preferences.getPreferences(getContext(), 'medication');
        await prefs.delete(Constants.KEY_TOKEN);
        await prefs.delete(Constants.KEY_NICKNAME);
        await prefs.delete(Constants.KEY_USER_ID);
        await prefs.flush();
        await router.replaceUrl({ url: 'pages/Login' });
        router.clear();
      }
      // resp.result 是后端返回的字符串
      return resp.result as string;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 快捷方法：GET
   */
  static get(path: string, needAuth: boolean = true): Promise<string> {
    return HttpUtil.request(http.RequestMethod.GET, path, undefined, needAuth);
  }

  /**
   * 快捷方法：POST
   */
  static post(path: string, body?: Object, needAuth: boolean = true): Promise<string> {
    return HttpUtil.request(http.RequestMethod.POST, path, body, needAuth);
  }

  /**
   * 快捷方法：DELETE
   */
  static delete(path: string, needAuth: boolean = true): Promise<string> {
    return HttpUtil.request(http.RequestMethod.DELETE, path, undefined, needAuth);
  }
}
