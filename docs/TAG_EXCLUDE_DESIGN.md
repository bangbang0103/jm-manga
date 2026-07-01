# 排除 Tag 功能方案与 Flutter 交互设计

> 状态：已通过 `grill-me` 逐项确认，可作为实现依据。

## 1. 决策总览

| 决策点 | 结论 |
| --- | --- |
| 全局黑名单作用域 | 搜索；**不作用于排行、分类、收藏/书架/阅读历史** |
| 搜索过滤方式 | 完全交给搜索接口：客户端只构造 `+tag` / `-tag` 查询，不再二次过滤 |
| 搜索框与条件关系 | 搜索框只保留“关键词主体”，`+tag`/`-tag` 提交后拆成 chip |
| 临时排除入口 | 搜索页 AppBar `tune` 图标 → Modal Bottom Sheet |
| 过滤面板内容 | 本次排除（可增删）+ 全局黑名单（只读 + 本次放行开关） |
| 面板确认方式 | 无“应用”按钮，添加/删除/切换即时生效 |
| 结果顶部 chip 行 | 普通关键词 / 包含（+）/ 排除（-）三类可删除 chip |
| 排行/分类过滤 | 暂不接入黑名单过滤，保持原有列表展示与分页 |
| 解析规则 | 仅空格分隔，不支持 tag 内部空格，不转小写/半角，空格压缩，后出现的条件优先 |
| 冲突覆盖 | 用户显式 `+tag` 覆盖全局黑名单的 `-tag` |

## 2. 数据模型与状态流

### 2.1 配置层

- `AppConfig` 新增字段：`List<String> excludedTags`，默认空列表。
- `ConfigNotifier` 新增：
  - `_excludedTagsKey` 持久化键；
  - `setExcludedTags(List<String>)`；
  - 复用现有 `_encodeStringList` / `_decodeStringList`。

### 2.2 查询模型

用一个不可变对象描述一次搜索请求：

```dart
@immutable
class SearchRequest {
  final String keywords;          // 搜索框里的普通关键词
  final List<String> includes;    // 用户显式 +tag
  final List<String> excludes;    // 用户显式 -tag（来自搜索框或面板）
  final List<String> globalExcludes;   // 配置里的全局黑名单
  final List<String> allowedGlobal;    // 本次临时放行的全局 tag
}
```

effective query 构造规则：

```
keywords + 空格 + (+includes) + 空格 + (-excludes) + 空格 + (-globalExcludes 中不在 allowedGlobal 里的)
```

**历史记录保存的查询字符串**（不含全局黑名单）：

```
keywords + 空格 + (+includes) + 空格 + (-excludes) + 空格 + (+allowedGlobal)
```

- 历史记录只保存用户显式输入的条件：关键词、本次包含/排除、本次放行的全局 tag。
- 不保存自动追加的全局黑名单 `-tag`，避免历史记录在不同配置下行为不一致。

### 2.3 过滤边界

- 客户端不再对 `AlbumItem` 做本地过滤。
- 搜索页只负责构造发送给搜索接口的 query：
  - 用户显式包含：`+tag`；
  - 用户显式排除：`-tag`；
  - 全局黑名单：自动追加为 `-tag`；
  - 本次放行：从自动追加的全局黑名单里移除，并作为 `+tag` 保留在 query / 历史里。

### 2.4 Notifier 改动

- `SearchNotifier`
  - 按 `SearchRequest` 作为 family key。
  - 请求直接使用 `effectiveQuery`，不做客户端二次过滤。
  - `hasMore` 仍按原始返回条数 `>= 20` 判断。
- `RankingsNotifier` / `CategoryNotifier`
  - 暂不读取黑名单配置。
  - 不做补拉、不做客户端过滤、不取详情校验 tag。
  - 保持原有一页一页滚动分页。

## 3. 解析规则

```dart
SearchRequest parseSearchInput(String raw)
```

- 按空格拆分，连续空格压缩。
- token 规则：
  - 以单个 `+` 开头 → include tag；
  - 以单个 `-` 开头 → exclude tag；
  - 其他 → keyword。
- 多个 `+` / `-`（如 `++abc`）按普通 keyword 处理。
- 同一 tag 多次出现时，后出现的覆盖先出现的。
- 全局黑名单追加前，若发现该 tag 已在 `includes` 或 `allowedGlobal` 中，则跳过（显式包含 / 本次放行优先）。

## 4. Flutter 交互设计

### 4.1 设置页入口

在 `SettingsScreen` 的“浏览”或“通用”分区内新增一项：

- 标题：`排除标签`；
- 副标题：显示当前数量，例如 `已排除 3 个标签`；
- 点击进入 `ExcludedTagsSettingsScreen`。

### 4.2 黑名单管理页 `ExcludedTagsSettingsScreen`

- 顶部固定 `TextField`：
  - hint：`输入要排除的 tag`；
  - 一次只输入一个 tag；
  - 右侧 `IconButton(Icons.add)`，点击后加入到全局黑名单；
  - 加入后立即清空输入框，弹出轻量 Toast：`已排除“xxx”`。
- 下方 `SingleChildScrollView` + `Wrap` 展示已排除 tag：
  - 使用 `InputChip`；
  - 右侧 `×` 图标直接删除；
  - 空状态文案：`还没有排除任何标签`。
- 视觉：chip 背景用 `surface-container-high`，文字 `ink`（参考 `DESIGN.md` 的 chip token）。

### 4.3 搜索页 `SearchScreen`

#### AppBar

- 标题 `TextField` 只输入关键词；提交后：
  - 普通关键词保留在框内；
  - `+tag`/`-tag` 从框内移除，转成结果顶部的 chip。
- 右侧保留“搜索”`FilledButton`。
- 在搜索按钮左侧增加 `IconButton(Icons.tune)`，点击打开过滤面板。
- **搜索历史**：保存用户视角的查询字符串（关键词 + 本次 `+/-` tag + 本次放行的全局 tag），不保存自动追加的全局黑名单。历史 chip 点击后按该字符串恢复搜索。

#### 过滤面板 `SearchFilterSheet`

- Modal Bottom Sheet，打开高度约屏幕 75%，内容可滚动。
- 标题栏：`过滤`，右侧关闭图标。
- **本次排除** 区域：
  - 顶部输入框 + 添加按钮（同管理页）。
  - 已添加 tag 用 `InputChip` 展示，点击删除立即生效。
  - 空状态：`本次没有临时排除标签`。
- **全局黑名单** 区域：
  - 只读展示全局 tag 列表。
  - 每个 tag 右侧带 `Switch` 或 `Checkbox`，标签：`本次放行`。
  - 打开放行后，本次搜索不再排除该 tag（effective query 里追加 `+tag`）。
  - 底部提供一个入口：`管理全局黑名单`，跳转设置页。
- 视觉：面板背景用 `surface-container-low`，分区标题用 `title` 样式，分组用 `Card` 或 16dp 间距。

#### 结果顶部 chip 行 `FilterChipBar`

- 位置：搜索结果列表顶部，紧贴 AppBar 下方。
- 展示当前 effective query 的显式部分：
  - 普通关键词 chip；
  - 包含 chip：`+` 前缀图标，文字用主色强调；
  - 排除 chip：`-` 前缀图标，文字用珊瑚色暗示排除。
- 每个 chip 右侧带删除图标，点击后：
  - 从 effective query 移除该条件；
  - 若移除的是关键词，搜索框同步更新；
  - 自动重新搜索。
- 全局黑名单 tag 不在 chip 行展示（它是隐式过滤），只有被放行的全局 tag 会以 `+tag` chip 出现。

### 4.4 排行/分类页

- 暂不接入黑名单过滤。
- 不新增常驻 UI。
- 不自动补拉多页，不显示手动“加载更多”按钮。
- 黑名单变更不触发排行/分类列表重建。

## 5. 需要修改/新增的文件

| 文件 | 动作 | 说明 |
| --- | --- | --- |
| `app/lib/providers/config_provider.dart` | 修改 | 新增 `excludedTags` 字段与持久化 |
| `app/lib/utils/tag_query_parser.dart` | 新增 | 查询字符串解析与 effective query 构造 |
| `app/lib/providers/album_providers.dart` | 修改 | `SearchNotifier` 使用 `SearchRequest.effectiveQuery` 发起搜索 |
| `app/lib/screens/settings_screen.dart` | 修改 | 增加黑名单入口 |
| `app/lib/screens/excluded_tags_settings_screen.dart` | 新增 | 黑名单管理页 |
| `app/lib/screens/search_screen.dart` | 修改 | 过滤图标、chip 行、面板唤起 |
| `app/lib/widgets/search_filter_sheet.dart` | 新增 | 过滤 Bottom Sheet |
| `app/lib/widgets/filter_chip_bar.dart` | 新增 | 结果顶部 chip 行 |
| `app/lib/l10n/app_en.arb` | 修改 | 新增文案 |
| `app/lib/l10n/app_zh.arb` | 修改 | 新增文案 |
| `app/test/utils/tag_query_parser_test.dart` | 新增 | 解析规则单测 |
| `app/test/providers/config_provider_test.dart` | 修改 | 验证黑名单持久化 |

## 6. 边界情况

- 用户搜索框输入 `+全彩` 且全局黑名单包含 `全彩`：effective query 只保留 `+全彩`，不放 `-全彩`。
- 用户同时输入 `-全彩` 和 `+全彩`：后出现优先；若 `-` 在后，effective query 保留 `-全彩`。
- 黑名单管理页输入重复 tag：去重后加入，不报错。
- 全局黑名单为空时：不自动追加 `-tag`。
- 服务端返回 0 条：直接展示现有空状态。

## 7. 国际化文案（Key 草案）

```json
{
  "excludedTagsTitle": "排除标签",
  "excludedTagsCount": "已排除 {count} 个标签",
  "excludedTagsEmpty": "还没有排除任何标签",
  "excludedTagsHint": "输入要排除的 tag",
  "excludedTagsAdded": "已排除“{tag}”",
  "excludedTagsRemoved": "已移除“{tag}”",
  "searchFilterTitle": "过滤",
  "searchFilterCurrentExcludes": "本次排除",
  "searchFilterGlobalExcludes": "全局黑名单",
  "searchFilterAllowThisTime": "本次放行",
  "searchFilterManageGlobal": "管理全局黑名单",
  "searchFilterNoCurrentExcludes": "本次没有临时排除标签",
  "loadMore": "加载更多",
  "filteredEmptyMessage": "暂无符合当前过滤条件的内容"
}
```

## 8. 实现顺序建议

1. 配置层：`AppConfig` + `ConfigNotifier` + 持久化 + 测试。
2. 工具函数：`tag_query_parser` + 单测。
3. 黑名单管理页 UI + 设置入口。
4. `SearchNotifier` 接入 effective query。
5. `SearchScreen` 改造：过滤图标、chip 行、Bottom Sheet。
6. 国际化文案补全。
7. 真机/模拟器走查：测试搜索黑名单、空结果、放行开关等场景。
