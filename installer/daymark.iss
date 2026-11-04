#ifndef AppVersion
  #error "请使用 ISCC /DAppVersion=x.y.z 指定版本号"
#endif

[Setup]
AppId={{D4FA5C26-10BF-4F17-8A1C-C6E56CE33719}
AppName=Daymark
AppVersion={#AppVersion}
AppVerName=Daymark {#AppVersion}
AppPublisher=weepwood
AppPublisherURL=https://github.com/weepwood/Daymark
AppSupportURL=https://github.com/weepwood/Daymark/issues
AppUpdatesURL=https://github.com/weepwood/Daymark/releases
DefaultDirName={localappdata}\Programs\Daymark
DefaultGroupName=Daymark
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=Daymark-Setup-{#AppVersion}-windows-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes
UninstallDisplayIcon={app}\Daymark.exe
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加选项："; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Daymark"; Filename: "{app}\Daymark.exe"
Name: "{autodesktop}\Daymark"; Filename: "{app}\Daymark.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Daymark.exe"; Description: "启动 Daymark"; Flags: nowait postinstall skipifsilent
