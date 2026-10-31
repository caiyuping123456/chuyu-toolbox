# ChuYu 万能工具箱

模块化 Windows 桌面工具集（Flutter / Dart）。

## 已交付模块（9 个全部可用）

| 模块 | 分类 | 功能 |
|---|---|---|
| HTTP 请求测试 | 网络测试 | 7 方法、Params/Headers/Body、集合/历史 |
| WebSocket 测试 | 网络测试 | 连接/收发/日志、ws/wss |
| 端口连通检测 | 网络测试 | TCP 探测、并发/停止/统计 |
| JSON 格式化 | 编码转换 | 格式化/压缩/校验/排序/复制 |
| Base64 编解码 | 编码转换 | 文本 ↔ Base64，URL-Safe |
| 时间戳转换 | 编码转换 | 秒/毫秒 ↔ 日期，双向 |
| 正则测试 | 开发辅助 | 匹配/分组/替换预览 |
| 哈希计算 | 开发辅助 | MD5/SHA-1/256/512 |
| UUID 生成 | 开发辅助 | v4 批量，大写/无连字符 |

## 运行

```bash
cd chuyu_toolapp
flutter pub get
flutter run -d windows   # 需 VS Build Tools（C++ 桌面开发）
flutter test             # 54 项测试
```

## 增强功能

- **最近使用**：首页自动记录最近打开的 4 个模块
- **Ctrl K 全局搜索**：9 个工具即时过滤
- **持久化**：HTTP 集合/历史落盘 `%APPDATA%\chuyu-toolbox\`
- **窄窗口**：侧栏自动收成图标列

## 文档

- `SPEC/SPEC.md` — 规格说明书（最新版）
- `plans/` — 里程碑计划与路线图
- `ChuYu万能工具箱-界面原型.html` — 可交互视觉基准
