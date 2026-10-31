# ChuYu 万能工具箱 规格说明书 v0.4

> 状态：**草案，等待最终确认（M0）**
> 目录：`E:\javaclass\posttest`
> 日期：2026-10-24
> 变更记录：v0.2 万能工具箱+模块化 → v0.3 名称/布局/白色主题定稿 → **v0.4 技术栈定稿 Dart + Flutter（用户决策，替换 Rust/Tauri）**
> 说明：本文档是唯一需求基准，开发严格按此推进；范围变动先改文档再改代码。

---

## 1. 项目概述

**ChuYu 万能工具箱**：用 **Dart + Flutter** 编写、可打包**安装到 Windows 电脑**的万能工具箱桌面应用。

- 本体（壳）只负责：窗口、**左侧导航（功能的唯一入口）**、**首页（介绍这个 App 是干嘛的）**、模块注册与加载、全局设置、本地存储；
- 一切具体能力都是**模块**：本期交付第一个模块 **「HTTP 请求测试」**（轻量版 Postman）；
- 后期持续扩展模块（WebSocket、端口检测、JSON 格式化、时间戳、正则、哈希……），**新增模块不改核心**；
- 界面风格：**白色简约**（白色面板 + 浅灰背景 + 细边框 + 单一强调色），中文。

### 1.1 设计原则

1. **模块化至上**：壳零业务逻辑；新能力 = 新模块目录。
2. **轻量（按 Flutter 桌面的真实水平设定）**：安装包 < 40 MB；内存 < 250 MB；冷启动 < 2 s。
3. **数据本地化、纯文本**：JSON 存储，可读可备份可 git。
4. **离线无账号**：除被测目标外不联网、无遥测。

---

## 2. 环境现状（2026-10-24 实测）

| 项 | 状态 | 说明 |
|---|---|---|
| `E:\javaclass\posttest` | ✅ 空目录 | 全新项目 |
| Flutter / Dart | ❌ 未安装 | M1 第一步：安装 Flutter SDK（stable，自带 Dart） |
| VS Build Tools（C++ 工作负载） | ❌ 未找到 | **Flutter 构建 Windows 桌面版必需**，M1 一并安装 |
| Node v22.14.0 | ✅ 已装 | 切换 Flutter 后不再需要（可留作它用） |
| WebView2 | 不再依赖 | Flutter 自绘引擎渲染，无需系统 WebView |

---

## 3. 技术选型（定稿 Dart + Flutter）

### 3.1 Flutter 做这类工具的优势（定稿理由）

1. **单一代码库多平台**：Windows / macOS / Linux 三桌面一套代码，未来想出移动端也直接复用；
2. **自绘引擎，渲染一致**：不依赖系统 WebView，KV 表格、JSON 语法高亮、可拖拽分栏等工具型 UI 用 Widget 组合即可实现，各系统观感完全一致；
3. **热重载（Hot Reload）**：工具 UI 需要反复打磨，改完界面秒级看到效果，开发效率高；
4. **AOT 编译为原生机器码**：发布版无解释器、性能好、启动快；
5. **生态齐全**：`dio`（HTTP 客户端，拦截器/超时/重定向/表单与流式 Body 全支持）、`path_provider`（系统目录）、`provider`（轻量状态管理）、`msix`/Inno Setup（打包安装）；
6. **Dart 语言简单**：强类型 + 空安全，模块接口清晰，适合长期扩展。

### 3.2 代价（诚实记录）

- 安装包比 WebView 方案大（空项目约 20 MB+），已按 < 40 MB 设定目标；
- 原型图是 HTML 的，仅作**视觉基准**，界面需用 Flutter Widget 按样式实现（样式规范见 §7，颜色/布局均已量化）。

### 3.3 依赖（pubspec，尽量少）

`dio ^5`、`path_provider ^2`、`provider ^6`；其余需求（JSON 高亮、KV 表格、分栏）用 Flutter 自带 Widget 自绘，不引第三方。

---

## 4. 产品结构（v0.3 定稿，不变）

### 4.1 整体框架

- 窗口默认 **960×640**，可缩放；
- **左侧导航 = 功能唯一入口**：首页 → 按分类分组的模块清单（已启用可点，二期置灰标「二期」）→ 底部模块管理 / 设置；窄窗口时收缩为图标列；
- 首页、模块页、模块管理、设置共享该导航。

### 4.2 首页（纯介绍，无功能区）

1. **介绍区**：这个 App 是干嘛（一句话定位：把常用开发小工具装进一个本地 App，本期内置 HTTP 请求测试）+ 特性标签；
2. **怎么用**：三步说明（左侧导航选工具 → 在工具页操作 → 保存与复用）；
3. **核心模块**（本期交付）：HTTP 测试展示卡（功能要点 + 进入按钮）；
4. **全部模块总览**：按分类网格展示（二期置灰，仅作介绍）；
5. **首页不放任何可操作功能区**（快速请求等交互一律在模块页内）。

### 4.3 模块页（双层侧栏，以 HTTP 测试为例）

外层 = 全局导航（固定）；内层 = **模块侧栏**（HTTP 模块为「集合 / 历史」页签）。主区：模块头（模块名 + 版本 + 说明 + 帮助/设置）→ 请求构造 → 响应查看。

### 4.4 模块管理页

模块清单（图标/名称/描述/分类/版本/启用开关）；「导入本地模块 / 模块市场」二期占位；说明「模块 = 独立目录」的扩展方式。

---

## 5. 架构与目录结构（Flutter 单体，无 IPC 层）

与 WebView 方案不同，Flutter 是单体应用：模块功能就是普通 Dart 类，**直接方法调用，没有前后端桥接**。

```
lib/
├─ main.dart                     入口（ runApp + Provider 装配 ）
├─ shell/                        壳
│  ├─ app.dart                   MaterialApp + 路由
│  ├─ nav_sidebar.dart           左侧导航（读注册表渲染）
│  ├─ home_page.dart             首页（介绍/怎么用/核心模块/全部模块）
│  ├─ module_manager_page.dart   模块管理
│  └─ settings_page.dart         设置
├─ core/
│  ├─ module_registry.dart       ★模块注册表（核心扩展点）
│  └─ storage.dart               JSON 持久化（path_provider）
└─ modules/
   ├─ toolbox_module.dart        模块抽象接口
   └─ http_test/                 ★本期唯一模块
      ├─ http_test_module.dart   实现 ToolboxModule
      ├─ http_client.dart        dio 封装（超时/重定向/Body 类型）
      ├─ models.dart             请求/响应模型
      ├─ store.dart              集合/历史存取
      └─ ui/                     模块页（模块头+模块侧栏+请求/响应）
```

### 5.1 模块接口

```dart
abstract class ToolboxModule {
  String get id;        // "http_test"
  String get name;      // "HTTP 测试"
  String get category;  // "网络测试"
  String get version;   // "1.0.0"
  bool get enabled;     // 二期模块为 false（导航/首页自动置灰）
  IconData get icon;
  Widget buildPage(BuildContext context);
}
```

**新增模块 = 建 `modules/<id>/` 目录 + 注册表加一行**；导航、首页总览、模块管理页全部由注册表自动驱动。

### 5.2 模块间约束

模块之间禁止互相 import，只允许依赖 `core/`；保证未来可拆可删。

### 5.3 二期模块候选（本期不做）

WebSocket 测试、端口连通检测、JSON 格式化、Base64 编解码、时间戳转换、正则测试、哈希计算、UUID 生成、接口批量断言、模块市场 / 本地插件加载、深色主题、Ctrl+K 快速启动、CLI 模式。

---

## 6. 首个模块：HTTP 请求测试（本期 MVP，基于 dio）

### 6.1 请求构造

| 项 | 要求 |
|---|---|
| 方法 | GET / POST / PUT / PATCH / DELETE / HEAD / OPTIONS |
| URL | 单行输入；与 Params 表双向同步 |
| Query 参数表 | 启用勾选 + KEY + VALUE + 备注，行增删 |
| 请求头表 | 同上 |
| Body | `none` / `form-data` / `x-www-form-urlencoded` / `raw`（JSON·text·XML·HTML） |
| 其它 | 超时（默认 30 s）；跟随重定向开关（默认开） |

### 6.2 响应展示

- 状态码+短语（2xx 绿/3xx 黄/4xx 橙/5xx 红）、耗时 ms、体积；
- Body：Pretty（JSON 格式化+着色 / XML 缩进）/ Raw；预览（二期）；
- 响应头表；一键复制响应体。

### 6.3 保存与复用

- 集合：新建/重命名/删除；请求存入集合、一键载入重放；
- 历史：自动记录最近 200 次，点击回填，可清空。

### 6.4 明确不做（二期）

环境变量 `{{var}}`、脚本断言、Cookie/Session、导入 Postman 集合、cURL 导入导出、代理设置、自动更新。

---

## 7. UI 规范（白色简约，原型图即视觉基准）

- 底色：内容区浅灰 `#F6F7F9`，面板纯白 `#FFFFFF`；边框细线 `#E7E9EE`；
- 强调色：**单一蓝色 `#2F6BFF`**（导航选中、发送按钮、开关、激活选项卡下划线）；
- 文字：主 `#21242B`，次要 `#838B98`；方法徽标：GET 绿 / POST 橙 / PUT 蓝 / DELETE 红 / PATCH 紫；
- 无渐变、无多余装饰；圆角 6–10 px；中文界面；
- 佐证原型：对话中「ChuYu 万能工具箱 原型（屏幕① 首页 / 屏幕② HTTP 测试）」，Flutter 按此实现。

---

## 8. 数据存储

位置：`path_provider` 的 `%APPDATA%\chuyu-toolbox\`，按模块分目录：

```
%APPDATA%\chuyu-toolbox\
├─ settings.json          ← 全局设置
└─ modules\
   └─ http_test\
      ├─ collections.json ← 集合与请求条目
      └─ history.json     ← 历史（上限 200）
```

请求条目格式：

```json
{ "id":"req_a1b2","name":"用户登录","method":"POST","url":"https://api.example.com/auth/login",
  "params":[{"enabled":true,"key":"from","value":"web","note":""}],
  "headers":[{"enabled":true,"key":"Content-Type","value":"application/json","note":""}],
  "body":{"kind":"raw","rawType":"json","content":"{ ... }"},"timeoutMs":30000 }
```

---

## 9. 里程碑与验收

| 里程碑 | 内容 | 验收 |
|---|---|---|
| **M0（当前）** | SPEC v0.4 + 双屏原型 | 用户确认 |
| M1 | 工具链 + 壳骨架 | 安装 Flutter SDK + VS Build Tools；`flutter run -d windows` 打开 960×640 窗口；左侧导航 + 首页（介绍/怎么用/核心模块/全部模块）由模块注册表驱动渲染，二期置灰 |
| M2 | HTTP 收发贯通 | 7 方法全通；Params/Headers/Body 全类型；响应状态/耗时/大小/Pretty 高亮 |
| M3 | 持久化 | 集合增删改+载入重放；历史自动记录+回填；重启数据完好 |
| M4 | 打包安装 | `flutter build windows --release` + Inno Setup（或 msix）产出安装包；实测 安装→使用→卸载 |
| M5 | 二期启动 | 按用户优先级排 |

---

## 10. 风险与对策

| 风险 | 对策 |
|---|---|
| Flutter/VS 工具链未装、下载量大 | M1 专门处理，一次性成本 |
| 安装包偏大 | 目标 < 40 MB；release 用 `--split-debug-info` 等瘦身 |
| 工具型复杂 UI 工作量 | 原型即规格，颜色布局量化（§7）；能自绘不引包 |
| 超大响应卡顿 | Pretty 上限 2 MB，超出提示切 Raw |
| 单体无隔离 | 模块禁止互相 import（§5.2），保留拆分可能 |

---

## 11. 待确认

原型（屏幕① 首页 = 介绍 / 屏幕② 侧边点「HTTP 测试」= 测试界面）与技术栈（Dart + Flutter）如无异议，回复「**开工**」即启动 M1。
