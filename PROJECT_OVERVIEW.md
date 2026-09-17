# PROJECT_OVERVIEW

> 面向 AI 的项目知识库：把本项目"改起来"所需的上下文集中在这里，按"**是什么 → 怎么组织的 → 怎么改 → 依据什么规则**"展开。
> 与 README 的关系：README 面向用户（**怎么用**），本文档面向 AI / 维护者（**怎么改**）。

---

## 目录

- [1. 项目概览与目标](#1-项目概览与目标)
- [2. 架构总览](#2-架构总览)
- [3. 代码结构](#3-代码结构)
- [4. 关键类与接口约定](#4-关键类与接口约定)
- [5. 业务流程](#5-业务流程)
- [6. 特殊约定与经验教训](#6-特殊约定与经验教训)
- [7. 目录结构速览](#7-目录结构速览)
- [8. 开发记录与常见修改场景](#8-开发记录与常见修改场景)

---

## 1. 项目概览与目标

### 1.1 产品定位

**Pupon** 是一款基于 JUCE 与 Rubber Band 的**多轨实时变调效果插件**（VST3 / AU / Standalone），**版本 1.1.0**。
UI 由"五颗珍珠 + 两条射线 + 一条正态曲线 + 一条滤波器抛物线"构成：五颗珍珠即五条并行音高轨道，射线控制声场铺开范围，正态曲线控制音高能量分布，抛物线划定每条轨道的频段窗口。

**插件标识（跨版本固定，不可修改）**

| 项 | 值 |
|------|------|
| 产品名称 / Product Name | `Pupon` |
| 厂商代码 / Manufacturer Code | `Pupo` |
| 插件代码 / Plug-in Code | `Pupn` |
| 分类 / Category | `Fx / Pitch`（AU: `kAudioUnitType_Effect`） |
| Bundle ID | `cn.iisaacbeas.Pupon` |
| 仓库 / Repository | https://github.com/sweetorange1/pupon.git |
| 域名 / Website | https://iisaacbeats.cn |

> ⚠️ `COMPANY_NAME` / `BUNDLE_ID` 在 CMake 中写作 `iisaacbeas`（少一个 `t`），而安装器与官网用 `iisaacbeats`。这是既有历史拼写，**不要顺手改**：改 Bundle ID 会导致 macOS 上宿主识别为另一个插件。

### 1.2 功能一览

| 模块 | 描述 |
|------|------|
| 五颗珍珠 | 5 路并行变调，默认 −24 / −12 / 0 / +12 / +24 st。上下拖动 = 增益（正态曲线决定上限）；左右拖动 = 音高（−36 ~ +36 st） |
| 红蓝射线 | 两条左右对称射线决定声场范围：射线越平，外侧轨道声相越大；合拢向上则全部居中 |
| 正态曲线 | 拖动改变 σ（0.24 ~ 8.0）：σ 小 = 只留原音高附近，σ 大 = 五条轨道一起响 |
| 滤波器抛物线 | 拖动中轴平移频段中心（±36 st）；拖动抛物线与刻度的交点改变宽度（10 ~ 72 st） |
| 变调引擎 | Rubber Band `LiveShifter`（R3 实时低延迟引擎），3 档质量、共振峰 2 档 |
| 预设 | `.puponpreset` 存放在 `~/Documents/puponpresent`，支持 `<` `>` 快速切换与保存 |
| 宿主自动化 | 16 个 APVTS 参数，可作为自动化目标 |
| 延迟补偿 | 五路补齐到统一参考延迟后混音，并上报稳定延迟给宿主 |
| 更新检查（v1.1.0） | 启动后延迟 5s 异步检查一次，有新版本时弹 Pupon 风格弹窗 |
| 匿名遥测（v1.1.0） | 每日一次 `ui_opened` 事件，可用 `IISAAC_TELEMETRY_DISABLED=1` 关闭 |

### 1.3 技术栈

| 类型 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 语言 | C++ | C++17 | `CMAKE_CXX_STANDARD 17`，关闭扩展 |
| 框架 | JUCE | 8.0.12 | `FetchContent` 拉取，模块 `juce_audio_utils` / `juce_dsp` |
| 变调库 | Rubber Band Library | v4.0.0 | GPL；`single/RubberBandSingle.cpp` unity build，含本地重采样质量补丁 |
| 构建 | CMake | ≥ 3.22 | `juce_add_plugin` 生成 VST3 / AU / Standalone |
| 字体 | BinaryData | — | 仅打包 `PUPON` 标题所需的子集字体 OTF |
| 安装器 | Inno Setup 6 | — | Windows（`Pupon_installer.iss` + `build_installer.bat`） |
| 安装器 | pkgbuild + hdiutil | — | macOS（`build_macos_installer.sh`） |

**参数清单（APVTS，16 个已注册）**

| 参数 ID | 范围 | 默认 | 说明 |
|------|------|------|------|
| `redRayClockwiseAngle` | 0.0 ~ 180.0° | 60.0 | 射线顺时针角度，决定声场铺开 |
| `sigma` | 0.24 ~ 8.0 | 0.80 | 正态曲线标准差 |
| `filterCenterSt` | −36 ~ +36 | 0 | 滤波器中心偏移（半音） |
| `filterWidthSt` | 10 ~ 72 | 36 | 滤波器宽度（半音） |
| `rbPitchQuality` | 0 / 1 / 2 | 1 | Fastest / Mid / Best |
| `rbFormantMode` | 0 / 1 | 0 | Complex（跟随变调）/ Vocal（保留） |
| `dot0` … `dot4` | 0.0 ~ 1.0 | 1 / 0.9 / 0.8 / 0.7 / 0.6（1.0 制） | 五路增益（内部再乘正态权重） |
| `dot0Semitone` … `dot4Semitone` | −36 ~ +36 | −24 / −12 / 0 / +12 / +24 | 五路音高偏移 |

> `ParameterIDs::isVerticalRay` 已定义但**未注册进 `createParameterLayout`**，属于历史遗留常量，不要误用。

---

## 2. 架构总览

### 2.1 分层架构图

```
┌─────────────────────────────────────────────────────────────┐
│                   构建层 Build Layer                          │
│  CMakeLists.txt（juce_add_plugin + FetchContent）            │
│  cmake/patches/rubberband-v4.0.0-resampler-quality.patch    │
│  juce_add_binary_data（otf 子集字体）                         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Plugin 层（JUCE 标准）                       │
│  PuponvstAudioProcessor（APVTS + EditorState 镜像 + 状态序列化）│
│  PuponvstAudioProcessorEditor（Canvas 自绘 + 预设 + 遥测）     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              DSP 层（音频线程，纯算法无 UI 依赖）               │
│  PitchShiftEngine（LiveShifter×5×2 + 环形缓冲 + 对齐延迟       │
│                    + 36dB/oct 频段滤波 + 延迟上报）            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    网络层 Network                             │
│  pupon::network::CheckForUpdatesAsync（后台线程 + 主线程回调）   │
│  pupon::network::SemVer（版本号解析与比较）                     │
│  pupon::ui::UpdateDialog（Pupon 风格独立原生窗口）              │
│  iisaac::telemetry::Session（每日一次 ui_opened）               │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 目录功能矩阵

| 目录 / 文件 | 职责 | 输入 | 输出 |
|------|------|------|------|
| `CMakeLists.txt` | 依赖拉取 / 插件元数据 / 源清单 / 编译开关 | 仓库源码 | 构建系统 |
| `cmake/patches/` | Rubber Band 重采样质量补丁（必需） | v4.0.0 源码 | 打过补丁的源码树 |
| `PluginProcessor.cpp/.h` | 参数树、状态镜像与持久化、processBlock 分发 | APVTS / 宿主状态 | 处理后的音频 |
| `PitchShiftEngine.cpp/.h` | 5 路变调 DSP、滤波、延迟对齐 | 音频块 + 配置 | 5 路混音 |
| `PluginEditor.cpp/.h` | 自绘界面、鼠标交互、预设、遥测 Session | 用户输入 | 参数变更 |
| `source/network/` | 版本比较 + 更新检查 | 服务端 JSON | `UpdateInfo` |
| `source/ui/` | 更新弹窗（独立原生窗口） | `UpdateInfo` | 浏览器 / 关闭 |
| `shared/IisaacTelemetry.h` | 匿名遥测（header-only，与 CRTLoss 共用同一份实现） | 启动事件 | HTTP POST |
| `presents/` | 出厂预设（安装器会复制到 `文档\puponpresent`） | — | `.puponpreset` |
| `otf/` | 标题子集字体（BinaryData） | — | 嵌入二进制 |
| `dist/` | 安装器产物（gitignore） | — | `.exe` / `.pkg` / `.dmg` |

---

## 3. 代码结构

### 3.1 根目录文件

| 文件 | 位置 | 职责 |
|------|------|------|
| `CMakeLists.txt` | 根目录 | 依赖（JUCE / Rubber Band）、插件元数据、源清单、编译开关 |
| `cmake/patches/rubberband-v4.0.0-resampler-quality.patch` | `cmake/patches/` | 重采样质量补丁，缺失会 `FATAL_ERROR` |
| `PluginProcessor.cpp` / `.h` | 根目录 | APVTS、`EditorState` 镜像、状态序列化、`processBlock` |
| `PitchShiftEngine.cpp` / `.h` | 根目录 | 5 路变调 DSP、环形缓冲、延迟对齐、滤波 |
| `PluginEditor.cpp` / `.h` | 根目录 | 自绘界面、交互、预设、遥测 |
| `Pupon_installer.iss` | 根目录 | Inno Setup 安装脚本（VST3 + presets） |
| `build_installer.bat` | 根目录 | Windows 打包入口（自动探测 VST3 目录） |
| `build_macos_installer.sh` | 根目录 | macOS pkg/dmg 打包入口 |
| `README.md` | 根目录 | 用户向文档 |
| `PROJECT_OVERVIEW.md` | 根目录 | 本文档（AI / 维护者向） |
| `LICENSE` | 根目录 | AGPL-3.0 |

### 3.2 `source/network/` — 更新检查

| 文件 | 核心内容 |
|------|------|
| `Version.h` / `Version.cpp` | `SemVer{major,minor,patch,prerelease,build}`；`SemVer::Parse` / `ToString` / `CompareVersions` |
| `UpdateChecker.h` / `UpdateChecker.cpp` | `UpdateInfo{has_update, latest_version, download_url, changelog, force_update}`；`CheckForUpdatesAsync(product, version, platform, callback)`；`ShowUpdateDialog(info)` |

关键实现点：

- **端点**：`https://iisaacbeats.cn/api/update/check`，查询串 `?product=pupon&version=...&platform=...`
- **线程模型**：后台线程 `URL::createInputStream`（`withConnectionTimeoutMs(5000)`）→ `MessageManager::callAsync` 切回主线程回调
- **进程级去重**：`static std::atomic<bool> s_checked_this_session`，进程内只检查一次
- **本地兜底**：服务端 `has_update=true` 时再用 `CompareVersionStrings` 比对一次，避免异常数据误弹
- **后台线程登记器**：`BackgroundThreadRegistry` 在静态析构阶段 join 所有后台线程，避免进程退出时线程被强制终止

### 3.3 `source/ui/` — 更新弹窗

| 文件 | 核心内容 |
|------|------|
| `UpdateDialog.h` / `UpdateDialog.cpp` | `UpdateDialog::ShowInComponent(info, onClose)`，480×340 独立原生窗口，`setAlwaysOnTop(true)`，标题栏可拖拽，Download / Remind Me Later 两个按钮 |

- **视觉**：暗色渐变 `0xFF1C1C21 → 0xFF0E0E12`（与编辑器背景 `0xFF121214` 同源），外框 `accent` 18% 透明；强调色 `0xFFBFD4FF`（与界面高光一致）
- **force_update**：只显示 Download，不可跳过
- **生命周期**：`CloseDialog()` → `setVisible(false)` + 回调 → `MessageManager::callAsync` 中 `removeFromDesktop()` + `delete this`
- **回退**：`ShowUpdateDialog` 优先用自定义弹窗，不可用时回退 `NativeMessageBox::showAsync`

### 3.4 `shared/` — 遥测

| 文件 | 核心内容 |
|------|------|
| `IisaacTelemetry.h` | header-only；`Session`、`forPlugin(...)`、PID 锁、`.opt_out` 开关、每日仅在首次上报 |

- **端点**：`https://iisaacbeats.cn`，路径 `/api/telemetry/v1/set_client` 与 `/api/telemetry/v1/ui_opened`
- **上报内容**：client id（随机 UUID）、插件名、版本、平台、宿主包装类型
- **调用点**：`PluginEditor.cpp` 构造函数末尾 `telemetrySession = std::make_unique<iisaac::telemetry::Session>(...)`；析构先 `reset()`
- **禁用**：环境变量 `IISAAC_TELEMETRY_DISABLED=1`，或产品目录下 `.opt_out` 文件

---

## 4. 关键类与接口约定

### 4.1 `PuponvstAudioProcessor`（PluginProcessor.h）

| 成员 | 类型 | 说明 |
|------|------|------|
| `initializeParameters()` | private 方法 | 在 `createParameterLayout()` 中调用，向 layout 追加全部参数 |
| `syncEngineFromParameters()` | public 方法 | 从 APVTS 镜像 struct 同步至 `pitchEngine`；构造末尾与状态切换后调用 |
| `setEditorState(const EditorState&)` | public 方法 | 写入参数并同步引擎（UI 侧统一入口） |
| `getEditorState()` | public 方法 | 读取当前镜像状态（UI 侧统一入口） |
| `setDotGain/DotPan/DotSemitoneOffset/FilterCenterOffsetSemitones/FilterWidthSemitones/PitchQualityMode/FormantMode` | inline 转发 | 直接转发到 `pitchEngine` |
| `getOscilloscopeSnapshot(Array<float>&)` | public 方法 | 取 UI 侧示波器快照 |
| `getStateInformation` / `setStateInformation` | override | `ValueTree` → XML → `MemoryBlock`，Type `"PuponState"` |

- **状态树结构**：`ValueTree("PuponState")` + `version = "1.1.0"`；属性含 `RedRayAngle`、`Sigma`、`FilterCenterSemitone`、`FilterWidthSemitone`、`RbPitchQuality`、`RbFormantMode`、`Dot0…Dot4`、`Dot0…Dot4Semitone`
- **状态切换淡入淡出**：`handleStateSwitch(state, shouldReset)` 中淡出快（~12ms）、淡入慢（~60ms），用于消除预设 / 工程切换时的咔哒声

### 4.2 `struct EditorState`（PluginProcessor.h）

| 字段 | 类型 | 说明 |
|------|------|------|
| `redRayClockwiseAngle` | float | 射线顺时针角度（度），范围 0.0 ~ 180.0 |
| `sigma` | float | 正态曲线标准差（0.24 ~ 8.0） |
| `filterCenterSt` / `filterWidthSt` | float | 滤波器中心 / 宽度（半音） |
| `rbPitchQuality` / `rbFormantMode` | int | 变调质量 / 共振峰模式 |
| `dot0…dot4` | float | 五路增益（0.0 ~ 1.0） |
| `dot0Semitone…dot4Semitone` | float | 五路半音偏移（−36 ~ +36） |

### 4.3 `PitchShiftEngine`（PitchShiftEngine.h）

| 成员 | 类型 | 说明 |
|------|------|------|
| `prepare(double sampleRate, int maxBlockSize)` | 方法 | 创建/重建 5 路 × 2 声道 `LiveShifter`，重置缓冲 |
| `reset()` | 方法 | 清空缓冲并重置滤波器与延迟统计 |
| `setSamplesPerBlock(int)` | 方法 | 更新块大小，返回是否发生变化 |
| `processBlock(const float* const* inputs, float* const* outputs, int numSamples)` | 方法 | 5 路并行变调 → 延迟对齐 → 混音输出 |
| `getLatencySamples()` | 方法 | 返回稳定延迟（0 表示未初始化） |
| `setDotGain/SetDotPan/SetDotSemitoneOffset/...` | setter | 配置五路与滤波器 |

- **延迟策略**：以"最慢的一路"为参考，其余路补齐后再混音，保证相位一致
- **滤波**：3 个串联 HP + 3 个串联 LP，等效 36 dB/oct 陡峭频段窗口
- **编译隔离**：头文件**前向声明** Rubber Band 类型，仅在 `.cpp` 中 include，避免 GPL 头文件污染

### 4.4 `PuponvstAudioProcessorEditor`（PluginEditor.h）

| 成员 | 用途 |
|------|------|
| `presetCombo` / `presetPrevButton` / `presetNextButton` / `presetSaveButton` | 预设选择与保存（ComboBox 用自定义 LAF 隐藏原生控件） |
| `qualityCombo` / `formantCombo` | 变调质量 / 共振峰模式下拉 |
| `versionLabel` | 副标题 `v1.1.0`（右上角小号普通无衬线字体） |
| `telemetrySession` | 匿名遥测会话（构造末尾创建，析构优先 `reset()`） |

- **命中优先级（1 → 7）**：射线端点 → 射线整体 → 滤波器中轴 → 滤波器抛物线 → 正态曲线 σ → 珍珠 → 底栏预设 / 下拉
- **刷新节奏**：`startTimerHz(40)`，从 Processor 快照拉取状态后异步更新
- **预设目录**：`~/Documents/puponpresent`（Windows / macOS 同路径语义）

---

## 5. 业务流程

### 5.1 DSP 链路

```
输入 → dry 采集 → 5 路并行 LiveShifter（各自 pitch / pan）
      → 每路 36dB/oct 频段窗口（HP×3 + LP×3）
      → 按最慢一路补齐对齐延迟 → 乘以正态权重（σ）与 dotGain
      → 按声相写入 L/R → 硬限幅（防削波爆音）→ 输出
```

### 5.2 参数流（UI → 音频）

```
鼠标拖拽 → EditorState 更新 → setEditorState()
        → 写入 APVTS → syncEngineFromParameters() → pitchEngine
```

### 5.3 状态持久化

```
getStateInformation：构建 ValueTree → 写入 16 个参数 → toXmlString() → 追加 \0 → copyToMemoryBlock
setStateInformation：MemoryBlock → 字符串 → fromXml() → 读属性 → 写回参数树 → setStateInformation 完成切换
```

### 5.4 预设

```
读取 ~/Documents/puponpresent/*.puponpreset
  文件头 4 字节 "PPRE"，随后为版本 + 参数区（按偏移读取，不使用 sizeof 结构体）
保存：当前 EditorState → 写入同名目录（文件名即预设名）
切换：< / > 按钮在目录内按顺序切换，或 ComboBox 直接选择
```

### 5.5 更新检查与遥测（v1.1.0）

```
更新检查：Processor 构造末尾 → 静态 atomic 去重 → Timer 5s 后
          CheckForUpdatesAsync("pupon", JucePlugin_VersionString, <os>-<arch>)
          → 后台线程 GET（5s 超时）→ 主线程回调 → 本地 SemVer 兜底比较
          → has_update → ShowUpdateDialog（Pupon 风格弹窗）
          → 点 Download → 浏览器打开 download_url（为空则打开 iisaacbeats.cn）

遥测：     Editor 构造末尾 → telemetry::Session（每日仅首次 / 进程锁 / .opt_out 可关）
          → POST /api/telemetry/v1/set_client + /api/telemetry/v1/ui_opened
```

---

## 6. 特殊约定与经验教训

### 6.1 音频线程约束（必须遵守）

1. `processBlock` 内**禁止** `new` / `delete`、`DBG`、加锁、文件与网络 IO
2. 仅在 `prepareToPlay` 中分配内部缓冲
3. 所有跨线程可见的状态用原子或镜像 struct 传递
4. `numSamples` 可变，注意块大小变化时的缓冲重建

### 6.2 Rubber Band 编译隔离

- 只 include `rubberband/RubberBandLiveShifter.h` 于 `PitchShiftEngine.cpp`
- `single/RubberBandSingle.cpp` 单独设置 `NOMINMAX` / `_USE_MATH_DEFINES` / `_CRT_SECURE_NO_WARNINGS`
- Apple 需链接 `-framework Accelerate`（vDSP）
- `cmake/patches/` 下的补丁文件**缺失会 FATAL_ERROR**，不要删除

### 6.3 视觉与交互

- 背景 `0xFF121214`；强调色 `0xFFBFD4FF`（冷蓝白：高光、珍珠辉光、按钮）
- 标题 "PUPON" 用子集字体（BinaryData），鼠标靠近时做色散抖动
- 更新弹窗沿用同一套暗色玻璃 + 冷蓝白高光，保持产品一致

### 6.4 版本一致性（改动版本号必须同步以下 5 处）

1. `CMakeLists.txt` → `project(Puponvst VERSION X.Y.Z)`
2. `CMakeLists.txt` → `juce_add_plugin(... VERSION X.Y.Z)`
3. `PluginEditor.cpp` → `versionLabel.setText("vX.Y.Z")`
4. `Pupon_installer.iss` → `#define MyAppVersion "X.Y.Z"`
5. `build_installer.bat` → `set "APP_VERSION=X.Y.Z"`（同时影响输出文件名）

> `build_macos_installer.sh` 的用法注释里也写了示例版本号，一并同步。

### 6.5 构建目录与打包

- 构建目录固定为 `cmake-build-release` 或 `cmake-build-release-visual-studio`（gitignore 已忽略）
- Windows 安装器写入 `C:\Program Files\Common Files\VST3\iisaacbeats.cn`，并把 `presents\*.puponpreset` 复制到 `{userdocs}\puponpresent`
- 若用户在安装时改了目录，需在 DAW 中手动添加并重新扫描；README 已写明
- `build_installer.bat` 自动探测 VST3 顶层目录并以 `-DVST3_DIR=` 传给 ISCC；找不到产物时给出 Hint 而不是盲打包

### 6.6 遥测 / 更新的隐私口径

- 遥测只报"界面打开"，不含音频内容、工程名、路径或个人身份信息
- 每日一次 + 进程锁 + 随机 UUID，可在 README / 官网隐私说明中直接引用
- 更新检查失败静默，不影响插件启动；`force_update` 仅用于严重 bug，谨慎开启

### 6.7 已知小问题（保留现状）

- CMake 中 `iisaacbeas`（少一个 `t`）与安装器 / 官网的 `iisaacbeats` 不一致：改 Bundle ID 会让 macOS 宿主视为新插件，保持原样
- `ParameterIDs::isVerticalRay` 未注册进参数树，属历史遗留

---

## 7. 目录结构速览

```
Pupon/
├── CMakeLists.txt                  # 构建配置（JUCE + Rubber Band + 源清单）
├── cmake/
│   └── patches/
│       └── rubberband-v4.0.0-resampler-quality.patch
├── PluginProcessor.h / .cpp        # APVTS + EditorState 镜像 + 状态序列化
├── PitchShiftEngine.h / .cpp       # 5 路变调 DSP / 滤波 / 延迟对齐
├── PluginEditor.h / .cpp           # 自绘界面 / 交互 / 预设 / 遥测
├── shared/
│   └── IisaacTelemetry.h           # 匿名遥测（header-only）
├── source/
│   ├── network/
│   │   ├── Version.h / .cpp        # SemVer 解析与比较
│   │   └── UpdateChecker.h / .cpp  # 异步更新检查 + 弹窗入口
│   └── ui/
│       └── UpdateDialog.h / .cpp   # Pupon 风格更新弹窗
├── presents/                       # 出厂预设（.puponpreset × 10）
├── otf/                            # 标题子集字体（BinaryData）
├── Pupon_installer.iss             # Inno Setup 脚本
├── build_installer.bat             # Windows 打包入口
├── build_macos_installer.sh        # macOS 打包入口
├── README.md                       # 用户向文档
├── PROJECT_OVERVIEW.md             # 本文档
└── LICENSE                         # AGPL-3.0
```

---

## 8. 开发记录与常见修改场景

### 8.1 本轮（v1.1.0）

1. **遥测接入**：`shared/IisaacTelemetry.h` + Editor 构造末尾创建 `Session`（进程锁 / 每日一次 / `.opt_out` 可关）
2. **更新弹窗**：新增 `source/network/{Version,UpdateChecker}` 与 `source/ui/UpdateDialog`；`Processor` 构造末尾延迟 5s 触发，进程级去重
3. **CMake 适配**：`NEEDS_CURL TRUE` + `JUCE_USE_CURL=1` + 新源文件清单（Windows 下 https 依赖 CURL 后端，不加会静默失败）
4. **打包脚本**：`build_installer.bat` 自动探测 VST3 产物并以 `-DVST3_DIR` 传入；`.iss` 用 `{#VST3_DIR}` 取源，脚本不再硬编码构建目录
5. **文档**：新增 `README.md`（中英双语）与 `PROJECT_OVERVIEW.md`（本文档）
6. **版本号**：1.0.5 → 1.1.0（CMake ×2、Editor 水印、iss、bat 五处同步）

### 8.2 两个告警的修复（v1.1.0 后）

1. **CMake dev 警告：`FetchContent_Populate(rubberband) is deprecated`（CMP0169）**
   - 原因：单参数形式的 `FetchContent_Populate()` 自 CMake 3.30 起废弃。
   - 修复：改用 `FetchContent_MakeAvailable(rubberband)`。Rubber Band 顶层只有 `meson.build`
     没有 `CMakeLists.txt`，`MakeAvailable` 检测到没有顶层 `CMakeLists.txt` 时**不会**执行
     `add_subdirectory`（这不是错误，是 FetchContent 的既定行为），效果与旧的 `Populate` 一致。

2. **运行期报错：`R3LiveShifter::process: ERROR: insufficient space in inbuf (wanted, got): (512, 0)`**
   - 触发时机：插件刚打开（`prepare()`）与切换预设（选项变更 → `processBlock` 内触发 `prepare()`）。
   - 根因：R3 引擎在"首次 `shift()`"时会往输入环形缓冲预填充 `getWindowSourceSize() * pitchScale`
     个零，而该缓冲容量固定为 `getWindowSourceSize() * 4`；当 `pitchScale >= 4`（即 **≥ +24 半音**，
     默认第 5 颗珍珠正好是 +24 st）时，预填充刚好写满 `inbuf`，本次输入被丢弃并打印该错误。
   - 修复：`PitchShiftEngine.cpp` 新增 `warmUpShifter()` —— 构造 / `reset()` 之后**先在
     `pitchScale = 1.0` 下跑一个静音块**把首次 pre-pad 消耗掉，再设置目标 `pitchScale`；
     此后 `m_firstProcess` 为 false，不再 pre-pad。
   - 注意：`reset()` 会把 shifter 标回"首次处理"状态，因此 **`reset()` 之后必须重新预热并恢复
     ratio**（`prepare()` 探测后的 reset、`PitchShiftEngine::reset()` 都已处理）。

### 8.3 常见修改场景速查

| 需求 | 涉及文件 | 要点 |
|------|----------|------|
| 修改界面配色 | `PluginEditor.cpp`（paint） | 同步更新 `UpdateDialog.cpp` 的强调色 |
| 调整 DSP 算法 | `PitchShiftEngine.cpp` | 遵守音频线程约束，改完同步延迟上报 |
| 增加参数 | `PluginProcessor.cpp`（`initializeParameters`）、`EditorState`、`PluginProcessor.h` | 三处同步，否则 UI 与音频状态不同步 |
| 增加预设 | `presents/*.puponpreset` | 安装器会把整个目录复制到 `文档\puponpresent` |
| 调整交互 | `PluginEditor.cpp`（`mouseDown`） | 注意 7 级命中优先级顺序 |
| 修改安装路径 | `Pupon_installer.iss` | 同步 `build_macos_installer.sh` 与 README 说明 |
| 升版本号 | `CMakeLists.txt` ×2、`PluginEditor.cpp`、`Pupon_installer.iss`、`build_installer.bat` | 见 §6.4 |
| 增加遥测事件 | `shared/IisaacTelemetry.h` | 保持 header-only、禁用开关与失败静默 |

### 8.4 经验与教训

1. **CURL 是硬依赖**：Windows 上 `JUCE_USE_CURL=1` 未开启时 https 请求静默失败，本地自测"没弹窗"并不代表服务端正常
2. **后台线程必须登记**：静态析构阶段统一 join，否则调试期退出会偶发崩溃
3. **服务端结果本地再校验**：`has_update` 之外再用 SemVer 比一次，避免异常数据误弹
4. **打包脚本不要盲打包**：先探测产物目录，找不到就给出构建 Hint
5. **GPL 头文件隔离**：Rubber Band 只在 `.cpp` 里 include，防止污染整个工程的许可口径
