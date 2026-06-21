---
name: JM Manga
description: A warm, private manga reader that feels like a personal bookshelf.
colors:
  primary-orange: "#F5922F"
  primary-orange-light: "#FFB85C"
  primary-orange-dark: "#C25E00"
  on-primary-brown: "#3E1E00"
  secondary-coral: "#E66A55"
  secondary-coral-light: "#FF9E8C"
  secondary-coral-dark: "#8B3D2A"
  tertiary-gold: "#FFD166"
  tertiary-gold-light: "#FFE08A"
  tertiary-gold-dark: "#B8962E"
  cream: "#FFF8ED"
  cream-dark: "#1A1512"
  surface-container-low: "#FFF1DE"
  surface-container-low-dark: "#221C18"
  surface-container: "#FFE8D1"
  surface-container-dark: "#2C241F"
  surface-container-high: "#FFE0BF"
  surface-container-high-dark: "#3A2F28"
  surface-variant: "#F5E0C8"
  surface-variant-dark: "#4A3D35"
  ink: "#1A120B"
  ink-dark: "#F5E6D3"
  ink-light: "#5A3E2E"
  ink-light-dark: "#C9A88F"
  outline: "#9A7A60"
  outline-dark: "#8A7260"
  error: "#FFB4AB"
  error-on: "#690005"
typography:
  display:
    fontFamily: "MapleMonoNormalCN, monospace"
    fontSize: "40px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "normal"
  headline:
    fontFamily: "MapleMonoNormalCN, monospace"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
  title:
    fontFamily: "MapleMonoNormalCN, monospace"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.4
    letterSpacing: "normal"
  body:
    fontFamily: "MapleMonoNormalCN, monospace"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "MapleMonoNormalCN, monospace"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: "normal"
rounded:
  sm: "8px"
  md: "14px"
  lg: "16px"
  xl: "20px"
  2xl: "24px"
  3xl: "28px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary-orange}"
    textColor: "{colors.on-primary-brown}"
    rounded: "{rounded.lg}"
    padding: "16px 24px"
  button-primary-hover:
    backgroundColor: "{colors.primary-orange-light}"
    textColor: "{colors.on-primary-brown}"
  button-primary-dark:
    backgroundColor: "{colors.primary-orange-light}"
    textColor: "{colors.on-primary-brown}"
  button-outlined:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.primary-orange}"
    rounded: "{rounded.lg}"
    padding: "16px 24px"
  button-outlined-dark:
    backgroundColor: "{colors.surface-container-dark}"
    textColor: "{colors.primary-orange-light}"
  pill-selected:
    backgroundColor: "{colors.primary-orange}"
    textColor: "{colors.on-primary-brown}"
    rounded: "{rounded.2xl}"
    padding: "8px 16px"
  pill-selected-dark:
    backgroundColor: "{colors.primary-orange-light}"
    textColor: "{colors.on-primary-brown}"
  pill-unselected:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.2xl}"
    padding: "8px 16px"
  pill-unselected-dark:
    backgroundColor: "transparent"
    textColor: "{colors.ink-dark}"
  card:
    backgroundColor: "{colors.surface-container-low}"
    textColor: "{colors.ink}"
    rounded: "{rounded.xl}"
    padding: "12px"
  card-dark:
    backgroundColor: "{colors.surface-container-low-dark}"
    textColor: "{colors.ink-dark}"
  input:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "16px 12px"
  input-dark:
    backgroundColor: "transparent"
    textColor: "{colors.ink-dark}"
  chip:
    backgroundColor: "{colors.surface-container-high}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sm}"
    padding: "4px 8px"
  chip-dark:
    backgroundColor: "{colors.surface-container-high-dark}"
    textColor: "{colors.ink-dark}"
  toast:
    backgroundColor: "{colors.surface-container-high}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "12px 16px"
  toast-dark:
    backgroundColor: "{colors.surface-container-high-dark}"
    textColor: "{colors.ink-dark}"
---

# Design System: JM Manga

## 1. Overview

**Creative North Star: "The Private Bookshelf"**

JM Manga 的设计系统围绕“私人书架”展开：一个只属于自己的阅读角落，没有广告、没有社交压力、没有算法推送。视觉语言温暖而克制，像傍晚房间里的一盏台灯，照亮封面和标题，但不打扰阅读本身。

图标（`icon.png`）是整套调色板的来源：橘色猫咪的主体提供了主色，耳朵和肉垫的粉色提供了辅助色，星星的黄色提供了点缀色，背景的奶油色和半调网点则奠定了中性表面的基调。暗色模式不是简单反色，而是把这些暖色映射到更深的棕黑背景上，让深夜阅读时眼睛不会被冷灰刺伤。

界面以奶油色/暖棕色为底，橙色和珊瑚色作为点缀，只出现在需要引导注意力的位置（选中态、徽章、主按钮）。所有文字使用同一款等宽字体 MapleMonoNormalCN，在数字、章节号和进度显示上带来一种手账般的秩序感，同时保持现代移动应用的清晰度。

**Key Characteristics:**
- 温暖克制：暖色调建立情绪，但高饱和色只占总界面的小面积。
- 私人书架感：书架、收藏、进度是个人空间，界面应避免营销感和紧迫感。
- 圆角柔和：卡片、按钮、输入框使用 12–20px 圆角，营造亲切但不幼稚的触感。
- 等宽秩序：单一字体家族贯穿全部层级，靠字重和字号建立层级。
- 暗色暖调：深色模式使用棕黑而非冷灰，保持与图标一致的温暖气质。
- 诚实反馈：服务离线、同步失败、服务不可达时，界面要诚实反馈，不假装在线。

## 2. Colors

调色板从 `icon.png` 提取并整理为四个角色：主色来自猫咪的橘色，辅助色来自耳朵/肉垫的珊瑚粉色，点缀色来自星星的金色，中性色来自背景的奶油和半调网点。

### Primary
- **Warm Orange** (`#F5922F` light / `#FFB85C` dark): 主行动色。用于主按钮选中态、Pill 选中态、关键徽章。在暗色模式下使用更亮的 `#FFB85C`，保证在深色背景上有足够对比。
- **On Primary Brown** (`#3E1E00`): 主色上的文字和图标色，保证对比度。在深浅模式下均使用同一深色，因为主色在两种模式下都足够暖亮。

### Secondary
- **Coral** (`#E66A55` light / `#FF9E8C` dark): 辅助强调色，来自图标中的爱心和书脊。用于收藏心形、排行榜变化、删除/错误暗示。
- **Coral Dark** (`#8B3D2A`): 仅用于暗色模式下珊瑚色的容器背景或更重的水印场景。

### Tertiary
- **Gold** (`#FFD166` light / `#FFE08A` dark): 点缀色，来自图标中的星星和漫画书上的“最高！”徽章。用于排行榜金/银/铜徽章和特殊状态提示。
- **Gold Dark** (`#B8962E`): 暗色模式下需要深色容器时的金色变体。

### Neutral
- **Cream** (`#FFF8ED` light / `#1A1512` dark): 页面背景色。浅色模式像旧书页的米白色；暗色模式是深褐黑色，避免冷灰带来的刺眼感。
- **Surface Container Low** (`#FFF1DE` light / `#221C18` dark): 卡片和底部导航背景。
- **Surface Container** (`#FFE8D1` light / `#2C241F` dark): 按钮、输入框背景。
- **Surface Container High** (`#FFE0BF` light / `#3A2F28` dark): Chip、Toast、悬停状态背景。
- **Surface Variant** (`#F5E0C8` light / `#4A3D35` dark): 次要表面、占位背景、图标容器。
- **Ink** (`#1A120B` light / `#F5E6D3` dark): 主要文字色。
- **Ink Light** (`#5A3E2E` light / `#C9A88F` dark): 次要文字、说明文字、离线/次要状态。
- **Outline** (`#9A7A60` light / `#8A7260` dark): 边框、分隔线。

### Dark Mode Mapping Rules
- 浅色模式用“更浅的表面容器 = 更高层级”；深色模式用“更深的表面容器 = 更高层级”被反转：应使用“越接近前景越亮”。
- 主色/辅助色/点缀色在暗色模式下统一使用更亮的变体（Primary Light / Coral Light / Gold Light），避免深色背景上颜色发闷。
- 文字在暗色模式下使用奶油色家族（`#F5E6D3`），而不是纯白，保持温暖感。

### Named Rules
**The One Voice Rule.** 高饱和颜色（Primary Orange / Secondary Coral / Tertiary Gold）在同一屏幕上只应出现一次作为主导强调。如果主按钮已经使用了橙色，相邻卡片就不要再用珊瑚色徽章抢注意力。

**The Warm-Dark Rule.** 暗色模式的背景不是黑色或冷灰，而是深棕色（`#1A1512`）。深夜阅读时，暖调背景比冷灰更柔和。

## 3. Typography

**Display / Headline / Title / Body / Label:** MapleMonoNormalCN, monospace

**Character:** 等宽字体带来一种私人手账的秩序感，同时通过字重和字号差异建立清晰的现代层级。所有文字都使用同一字体家族，避免混搭造成的视觉噪音。

### Hierarchy
- **Display** (800, 40px / 1.1): 仅用于启动页/空状态的大标题。
- **Headline** (700, 28px / 1.2): 页面大标题，如设置页顶部、服务器列表标题区。
- **Headline Medium** (700, 22px / 1.2): 区段标题，如漫画详情页标题。
- **Title** (700, 18px / 1.4): 卡片标题、章节列表标题、底部导航标签。
- **Body** (400, 14px / 1.5): 正文、描述、状态信息。行宽控制在 65ch 以内。
- **Label** (600, 12px / 1.0): 徽章、按钮文字、小标签。

### Named Rules
**The Single Family Rule.** 全站只使用 MapleMonoNormalCN 一个字体家族。不要引入第二套字体做“装饰”，层级靠字重和字号解决。

## 4. Elevation

系统以 tonal layering 为主，阴影只用于从内容中“浮起”的反馈元素（Toast）。卡片和按钮默认没有投影，通过背景色深浅表达层级。

### Shadow Vocabulary
- **Toast Float** (`0 6px 16px rgba(0,0,0,0.12)`): 仅用于顶部 Toast，让它从页面内容中轻微浮起。在暗色模式下保持同一投影，利用深色背景自然增强对比。

### Named Rules
**The Flat-By-Default Rule.** 卡片、按钮、输入框默认不使用阴影。需要深度时，先调整 surface 容器层级；阴影是例外，不是默认。

## 5. Components

组件整体气质温暖且克制：圆角柔和、色块分区清晰，但不过度装饰。

### Buttons
- **Shape:** 16px 圆角，胶囊感不强的圆角矩形。
- **Primary (light):** 背景色 `#F5922F`，文字色 `#3E1E00`。
- **Primary (dark):** 背景色 `#FFB85C`，文字色 `#3E1E00`，确保深色背景上的亮度。
- **Outlined (light):** 背景色 `#FFE8D1`，文字/图标色 `#F5922F`。
- **Outlined (dark):** 背景色 `#2C241F`，文字/图标色 `#FFB85C`。
- **Hover / Focus:** Primary 悬停时背景变亮；Outlined 悬停时背景变深到下一个 surface 层级。

### Pill Selector
- **Container:** 28px 圆角，背景 `#F5E0C8`（浅色）/ `#4A3D35`（深色），内部 4px 内边距。
- **Selected Pill:** 24px 圆角，背景 Primary，文字 On Primary，字重加粗。
- **Unselected Pill:** 透明背景，文字 Ink，字重正常。
- **Motion:** 选中态切换使用 200ms 的 `AnimatedContainer` 过渡。

### Cards / Containers
- **Corner Style:** 20px 圆角（服务器卡片）或 16px 圆角（漫画封面卡片）。
- **Background:** `#FFF1DE`（浅色）/ `#221C18`（深色）。
- **Shadow Strategy:** 无阴影，靠背景色与页面背景区分。
- **Border:** 无边框。
- **Internal Padding:** 12px（服务器卡片）、内容区自适应（封面卡片）。

### Inputs / Fields
- **Style:** 透明背景，14px 圆角，1px 边框（默认 outline 色 `#9A7A60` 浅色 / `#8A7260` 深色）。
- **Focus:** 边框颜色切换到 Primary Orange，标签上浮。
- **Error / Disabled:** 错误状态使用 Error Container 背景 `#FFB4AB` 和 On Error 文字 `#690005`。

### Chips / Badges
- **Style:** 背景 `#FFE0BF`（浅色）/ `#3A2F28`（深色），文字 Ink，8px 圆角，水平 8px / 垂直 4px 内边距。
- **Use:** 漫画封面右上角的状态徽章、排行榜周期切换的备选形态。

### Navigation
- **Bottom Navigation:** 固定底部，背景 Surface Container Low，选中项使用 Primary，未选中项使用 Ink Light。
- **Icons:** Material Icons 描边风格（Outlined）为默认，选中后填充（Filled）。

### Toast
- **Style:** 顶部居中悬浮卡片，16px 圆角，背景 Surface Container High。
- **Shadow:** `0 6px 16px rgba(0,0,0,0.12)`，唯一被允许的投影。
- **Motion:** 从上方滑入（250ms easeOutBack），2 秒后淡出。

## 6. Do's and Don'ts

### Do:
- **Do** 使用 Cream (`#FFF8ED`) 作为浅色模式页面背景，让内容像放在一张暖色纸张上。
- **Do** 在暗色模式下使用 Cream Dark (`#1A1512`) 作为背景，保持温暖、不刺眼的深夜阅读体验。
- **Do** 让 Primary Orange 只出现在需要引导行动的元素上：主按钮、Pill 选中态、关键徽章。
- **Do** 使用 MapleMonoNormalCN 全站统一字体，靠字重（400/600/700/800）和字号建立层级。
- **Do** 用 Surface Container 层级（Low / Default / High / Highest）表达卡片、按钮、输入框的背景深度。
- **Do** 为离线/错误状态使用诚实反馈：红色状态点 + "Offline" 文字，不假装在线。

### Don't:
- **Don't** 在界面上使用盗版资源站的 cluttered 广告风：满屏弹窗、色块、低俗 banner、密集链接。（来自 PRODUCT.md 反参考）
- **Don't** 把高饱和颜色大面积铺到背景上，这会破坏“私人书架”的安静感。
- **Don't** 引入第二款字体做装饰，单一家族就是这个系统的身份。
- **Don't** 在卡片和按钮上默认加阴影，深度应通过 tonal layering 表达。
- **Don't** 使用 oversized 圆角（≥32px）让界面显得幼稚；卡片顶多为 20px。
- **Don't** 在暗色模式中使用冷灰色背景（`#121212` 风格），这会与图标的温暖气质冲突。
