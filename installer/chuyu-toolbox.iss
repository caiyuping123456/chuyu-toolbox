; ChuYu 万能工具箱 安装包脚本（Inno Setup 6）
; 构建步骤见同目录 BUILD.md

#define AppName "ChuYu 万能工具箱"
#define AppVersion "0.1.0"
#define AppPublisher "ChuYu"
#define AppExe "chuyu_toolapp.exe"

[Setup]
AppId={{8A2C4E9F-1B7D-4C3A-9E5F-CHUYU20261031}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\ChuYuToolbox
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=ChuYuToolbox-Setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExe}

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; flutter build windows --release 产物整目录打包
Source: "..\chuyu_toolapp\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; 卸载时清理本地缓存（保留 %APPDATA%\chuyu-toolbox 用户数据）
Type: filesandordirs; Name: "{app}\data"
