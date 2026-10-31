# 打包步骤（M4）

## 前置
1. 安装 **VS 2022 Build Tools**（管理员）：
   ```powershell
   winget install --id Microsoft.VisualStudio.2022.BuildTools -e
   ```
   打开 Visual Studio Installer → 修改 → 勾选「使用 C++ 的桌面开发」+ Windows 11 SDK。
2. 安装 **Inno Setup 6**：
   ```powershell
   winget install --id JRSoftware.InnoSetup -e
   ```

## 构建
```powershell
cd E:\javaclass\posttest\chuyu_toolapp
flutter build windows --release --split-debug-info=build/symbols

# 生成安装包
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" E:\javaclass\posttest\installer\chuyu-toolbox.iss
```

## 产物
- `installer\dist\ChuYuToolbox-Setup-0.1.0.exe`（预计 < 25 MB）

## 验收（SPEC §9-M4）
1. 双击安装包 → 安装到 `C:\Program Files\ChuYuToolbox`；
2. 开始菜单 / 桌面快捷方式启动；
3. 9 个模块全部可用，HTTP 集合/历史落盘 `%APPDATA%\chuyu-toolbox\`；
4. 控制面板卸载 → 程序目录删除，用户数据保留；
5. 安装包 < 40 MB。
