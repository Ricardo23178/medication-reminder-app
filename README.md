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
static readonly BASE_URL: string = 'http://192.168.1.14:8080';
```

> 模拟器访问宿主机后端，用局域网 IP（如 `192.168.x.x`）或 `10.0.2.2`；真机用电脑局域网 IP。

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
