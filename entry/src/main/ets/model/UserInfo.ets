/**
 * 登录/注册返回的用户信息模型。
 * 对应后端 data.user 字段。
 */
export class UserInfo {
  id: number = 0;
  account: string = '';
  nickname: string = '';
  role: string = '';
}

/**
 * 登录接口 data 部分。
 * 对应后端 { token, tokenType, expiresIn, user }。
 */
export class LoginData {
  token: string = '';
  tokenType: string = '';
  expiresIn: number = 0;
  user: UserInfo = new UserInfo();
}

/**
 * 登录接口返回的完整结构。
 * 对应后端 { code, message, data }。
 */
export class LoginResult {
  code: number = 0;
  message: string = '';
  data: LoginData = new LoginData();
}

/**
 * 把后端返回的 JSON 字符串解析成 LoginResult。
 */
export function parseLoginResult(jsonStr: string): LoginResult {
  return JSON.parse(jsonStr) as LoginResult;
}
