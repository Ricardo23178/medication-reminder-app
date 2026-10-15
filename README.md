# 用药提醒与家属协同系统 — HarmonyOS 客户端

> 《基于 HarmonyOS 与 Spring Boot 的用药提醒与家属协同系统设计与实现》移动端，本科毕业设计项目。

## 项目简介

基于 HarmonyOS（ArkTS / ArkUI，Stage 模型）的用药提醒客户端，帮助用户管理药品、制定用药计划、按时提醒服药，并通过家属协同让家人实时了解服药情况。

## 技术栈

| 技术 | 说明 |
|------|------|
| HarmonyOS | Stage 模型 |
| ArkTS / ArkUI | 声明式 UI 开发 |
| @kit.NetworkKit | HTTP 网络请求 |
| @kit.ArkData (preferences) | 本地 token 存储 |

## 功能清单

- [x] 登录 / 注册 / 退出登录
- [x] 今日服药提醒 + 确认服药
- [x] 药品管理（新增 / 列表）
- [x] 用药计划管理（建计划 / 暂停 / 恢复 / 删除）
- [x] 家属协同（发起绑定 / 接受邀请 / 解绑 / 异常事件）
- [x] 消息中心（全部 / 未读 / 分页 / 详情 / 全部已读）
- [x] 家属异常处理（知晓 / 关闭确认 / 关闭历史）
- [x] 日历统计（近 30 天服药完成率）
- [x] 底部 Tab 导航框架
- [ ] 界面美化（规划中）

## 页面结构

```
pages/
├── Index.ets          # 启动页
├── Login.ets          # 登录页
├── Register.ets       # 注册页
├── Main.ets           # 主框架（底部 5 Tab）
├── Home.ets           # 今日提醒（Tab）
├── MedicineList.ets   # 药品列表（Tab）
├── MedicineAdd.ets    # 新增药品
├── PlanList.ets       # 计划列表（Tab）
├── PlanAdd.ets        # 建计划
├── FamilyList.ets     # 家属协同（Tab）
├── FamilyAbnormal.ets # 家属异常事件
├── My.ets             # 我的（Tab）
└── Statistics.ets     # 日历统计
```

底部 Tab：**今日 / 药品 / 计划 / 家属 / 我的**。

## 如何运行

### 前置条件

- DevEco Studio 6.1+
- HarmonyOS SDK（API 24，兼容 API 12）
- 后端服务已启动（`http://localhost:8080`）

### 1. 配置后端地址

`entry/src/main/ets/common/Constants.ets`：

```typescript
static readonly BASE_URL: string = 'http://127.0.0.1:8080';
```

模拟器启动后，在 PowerShell 执行端口转发，将设备的 8080 端口连接到电脑后端：

```powershell
& "C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe" rport tcp:8080 tcp:8080
```

模拟器重启或转发被清除后需重新执行。真机通过局域网调试时，将 `BASE_URL` 改为电脑当前的局域网 IP，并确保设备与电脑网络互通。

### 2. 运行

用 DevEco Studio 打开工程，选择模拟器（如 Pura 90 / Pura 100），直接运行即可。

## 目录结构

```
entry/src/main/ets/
├── common/     # Constants、HttpUtil（网络封装）
├── model/      # 数据模型（对齐后端 VO/DTO）
├── pages/      # 页面
└── entryability/  # EntryAbility
```

## 技术要点

- **HttpUtil 封装**：统一拼 URL、自动带 Bearer token、返回字符串由页面自行 `JSON.parse`
- **@State 状态管理**：数据变化自动刷新 UI
- **ForEach 强制刷新**：用「版本号拼 key」的方式，解决列表项内部字段变化不重渲染的问题
- **Tab 刷新机制**：`currentTab + refreshTick` 两个状态驱动，切 Tab 或从二级页返回时自动刷新

## 当前阶段优化

- 取消或超时的提醒显示明确状态，不能继续确认。
- 提交期间禁用确认按钮，避免重复点击；“稍后”默认15分钟，仍可继续确认已服/跳过。
- 401 登录失效时清理会话并返回登录页；旧会话的迟到响应不会清除重新登录的凭证。
- 统计进度条按容器百分比显示，避免窄屏越界。

本次使用 DevEco 自带 Hvigor 完成未签名 HAP 编译，并已安装、启动到模拟器，验证模拟器到后端的网络连通；完整交互和真机流程尚未验收。当前 DevEco 不接受中文工程路径，可复制至英文路径后编译。API 弃用警告尚存，真机签名需在 DevEco 中配置。

## 2026-10-15 家属协同与消息中心

从“我的 → 消息中心”查看站内消息和未读数量，支持全部/未读筛选、分页、详情和全部已读。家属异常消息可进入异常页，确认知晓后关闭协同，并在历史中查看处理时间。关闭协同不代表已服药。

消息详情每次显示时重新验证权限；解绑后消息列表、未读数和详情同步受限。已在 Pura 90 模拟器联调登录、未读角标、详情已读、家属知晓/关闭、历史和解绑失效，并修复从子页返回详情时路由参数丢失的问题。真机与平板仍待后续验证，当前消息为站内消息。

切页后再次进入时，会先等待在途已读/知晓/关闭请求完成，再查询最新状态。异步行为检查使用实际页面方法，覆盖跨实例返回、失败释放等待、隐藏页面与403正文保护，共7项；在工程根目录可用DevEco自带Node运行：

```powershell
& "C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" scripts/verify-inbox-lifecycle.cjs
```

脚本默认使用同一安装目录下的SDK TypeScript工具；SDK位于其他位置时设置 `DEVECO_SDK_HOME`。该检查不渲染ArkUI，构建和模拟器验收另行执行。
