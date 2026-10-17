#define MyAppName "Pupon"
#define MyAppVersion "1.1.1"
#define MyAppPublisher "iisaacbeats.cn"
#define MyPluginBundle "Pupon.vst3"

; VST3 顶层目录（即包含 Pupon.vst3 bundle 的父目录）。
; 默认指向 Visual Studio / CLion 的 Release 构建目录；
; build_installer.bat 会用 -DVST3_DIR 覆盖为实际探测到的路径。
#ifndef VST3_DIR
  #define VST3_DIR "cmake-build-release-visual-studio\Puponvst_artefacts\Release\VST3"
#endif

[Setup]
; 独立 AppId：旧版与 SpectrumTag 共用 0E3BF70B-...，会导致两个安装包互相升级/卸载。
; 改为独立 ID 后与 SpectrumTag 完全解耦；旧版用户需先手动卸载旧 pupon。
AppId={{7869796B-D55D-495F-BF5D-C8142F3D4A6D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={commoncf}\VST3\iisaacbeats.cn
DirExistsWarning=no
OutputDir=dist
OutputBaseFilename={#MyAppName}_Setup_{#MyAppVersion}_x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
SetupLogging=yes
UsePreviousAppDir=no
DisableProgramGroupPage=yes
DisableDirPage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#VST3_DIR}\{#MyPluginBundle}\*"; DestDir: "{app}\{#MyPluginBundle}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "presents\*"; DestDir: "{userdocs}\puponpresent"; Flags: ignoreversion recursesubdirs createallsubdirs

[Code]
var
  InstallDirWarningShown: Boolean;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  DefaultVst3Path: string;
begin
  Result := True;

  if CurPageID = wpSelectDir then
  begin
    DefaultVst3Path := ExpandConstant('{commoncf}\VST3\iisaacbeats.cn');

    if (CompareText(RemoveBackslashUnlessRoot(WizardDirValue), RemoveBackslashUnlessRoot(DefaultVst3Path)) <> 0) and (not InstallDirWarningShown) then
    begin
      MsgBox('你选择了非默认VST3目录。安装完成后，你可能需要在宿主软件(DAW)中手动添加该目录并重新扫描插件，才能正常识别并使用本插件。', mbInformation, MB_OK);
      InstallDirWarningShown := True;
    end;
  end;
end;
