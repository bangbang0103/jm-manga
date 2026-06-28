// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'JM Manga';

  @override
  String get navHome => '首页';

  @override
  String get navRankings => '排行榜';

  @override
  String get navLibrary => '书架';

  @override
  String get navSettings => '设置';

  @override
  String get actionViewAll => '查看全部';

  @override
  String get actionCancel => '取消';

  @override
  String get actionCopy => '复制';

  @override
  String get actionAdd => '添加';

  @override
  String get actionRetry => '重试';

  @override
  String get actionSearch => '搜索';

  @override
  String get imageDownload => '下载图片';

  @override
  String get imageDownloadStarted => '正在下载图片…';

  @override
  String get imageLoading => '加载中…';

  @override
  String get imageLoadFailed => '加载失败';

  @override
  String get actionLogin => '登录';

  @override
  String get actionLoginLoading => '登录中…';

  @override
  String get actionDelete => '删除';

  @override
  String get searchHint => '搜索漫画…';

  @override
  String get searchPrompt => '输入关键词开始搜索';

  @override
  String get searchNoResults => '无结果';

  @override
  String get searchHistoryTitle => '搜索历史';

  @override
  String get emptySearchHistory => '暂无搜索历史';

  @override
  String get clearAll => '清空全部';

  @override
  String get confirmClearSearchHistoryTitle => '清空搜索历史';

  @override
  String get confirmClearSearchHistoryBody => '确定要清空所有搜索历史吗？';

  @override
  String get searchHistoryCleared => '搜索历史已清空';

  @override
  String get searchHistoryDeleted => '已删除该搜索记录';

  @override
  String get emptyNoItems => '暂无内容';

  @override
  String get sectionRecentRead => '最近阅读';

  @override
  String get libraryTitle => '书架';

  @override
  String get tabFavorite => '收藏';

  @override
  String get tabRecentRead => '最近阅读';

  @override
  String get favoriteSearchHint => '搜索收藏';

  @override
  String get favoriteSyncSuccess => '收藏已同步';

  @override
  String favoriteSyncPartialFailure(Object count) {
    return '部分同步失败：$count 项未同步';
  }

  @override
  String get favoriteSyncing => '同步中…';

  @override
  String get favoriteEmpty => '暂无收藏';

  @override
  String get favoriteSyncNow => '立即同步';

  @override
  String get recentEmpty => '暂无阅读记录';

  @override
  String get recentBrowseManga => '去逛逛';

  @override
  String get rankingsTitle => '排行榜';

  @override
  String get periodDay => '日榜';

  @override
  String get periodWeek => '周榜';

  @override
  String get periodMonth => '月榜';

  @override
  String get sortBy => '排序';

  @override
  String get sortTopView => '最多观看';

  @override
  String get sortTopFavorite => '最多收藏';

  @override
  String get sortTopRate => '最高评分';

  @override
  String get rankingsEmpty => '暂无排行数据';

  @override
  String get categoryTitle => '分类';

  @override
  String get categoryAll => '全部';

  @override
  String get categoryHanman => '韩漫';

  @override
  String get categoryHanmanSfw => '一般向韩漫';

  @override
  String get categorySingle => '单本';

  @override
  String get categoryAnother => '其他';

  @override
  String get categoryShort => '短篇';

  @override
  String get categoryDoujin => '同人';

  @override
  String get categoryMeiman => '美漫';

  @override
  String get orderMostRecent => '最新';

  @override
  String get orderMostViewed => '最多观看';

  @override
  String get orderTopRated => '最高评分';

  @override
  String get orderTopFavorite => '最多收藏';

  @override
  String authorLabel(Object name) {
    return '作者：$name';
  }

  @override
  String likesLabel(Object count) {
    return '点赞 $count';
  }

  @override
  String viewsLabel(Object count) {
    return '观看 $count';
  }

  @override
  String get synopsis => '简介';

  @override
  String chaptersTitle(Object count) {
    return '章节（$count）';
  }

  @override
  String get jumpToHint => '跳转至';

  @override
  String chapterTitle(Object number) {
    return '第 $number 话';
  }

  @override
  String get readNow => '立即阅读';

  @override
  String pageCounter(Object current, Object total) {
    return '第 $current / $total 页';
  }

  @override
  String get finishedBadge => '已读完';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionAccounts => 'JM 账号';

  @override
  String get sectionAppearance => '外观';

  @override
  String get sectionReader => '阅读器';

  @override
  String get accountAnonymous => '匿名 / 未登录';

  @override
  String get accountAddTooltip => '添加账号';

  @override
  String get accountRefreshTooltip => '刷新登录';

  @override
  String get themeTitle => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageTitle => '语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get calculatingLabel => '计算中…';

  @override
  String get preloadTitle => '预加载图片';

  @override
  String get preloadSubtitle => '阅读时提前预加载往后的图片数量';

  @override
  String get gridColumnsTitle => '每行封面数';

  @override
  String get gridColumnsSubtitle => '漫画封面每行显示的个数';

  @override
  String get settingsLogLevelTitle => '日志等级';

  @override
  String get settingsLogLevelSubtitle => '只记录所选等级及以上的日志';

  @override
  String get logLevelDebug => '调试';

  @override
  String get logLevelInfo => '信息';

  @override
  String get logLevelWarning => '警告';

  @override
  String get logLevelError => '错误';

  @override
  String get dialogAddAccountTitle => '添加 JM 账号';

  @override
  String get fieldUsername => '用户名';

  @override
  String get fieldPassword => '密码';

  @override
  String get fieldUsernameRequired => '请输入用户名';

  @override
  String get fieldPasswordRequired => '请输入密码';

  @override
  String get loginRefreshing => '正在刷新登录…';

  @override
  String get loginRefreshed => '登录已刷新';

  @override
  String get loginRefreshSyncTitle => '登录已刷新';

  @override
  String get loginRefreshSyncBody => '是否前往书架进行同步？';

  @override
  String get loginRefreshSyncLater => '稍后';

  @override
  String get loginRefreshSyncGo => '去同步';

  @override
  String get loginErrorUnauthorized => '用户名或密码错误';

  @override
  String get loginErrorNetwork => '无法连接到 JM，请检查网络连接';

  @override
  String get loginErrorServer => 'JM 服务异常，请稍后再试';

  @override
  String get loginAccountAdded => '账号已添加';

  @override
  String get loginMergeFavoritesHint => '登录后会将本地收藏与 JM 账号收藏合并。';

  @override
  String get favoriteAdded => '已添加到收藏';

  @override
  String get favoriteRemoved => '已取消收藏';

  @override
  String get badgeFinished => '已读完';

  @override
  String badgePage(Object page) {
    return '第$page页';
  }

  @override
  String badgePercent(Object percent) {
    return '$percent%';
  }

  @override
  String badgeChapterPercent(Object chapter, Object percent) {
    return '$chapter·$percent%';
  }

  @override
  String badgeChapterFinished(Object chapter) {
    return '$chapter-100%';
  }

  @override
  String get logsTitle => '日志';

  @override
  String get logsExport => '导出日志';

  @override
  String get logsClear => '清空日志';

  @override
  String get logsEmpty => '暂无日志';

  @override
  String get logsAllLevels => '全部';

  @override
  String get logsSearchHint => '搜索日志';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get errorNetworkUnavailable => '网络不可用，请检查网络或代理设置。';

  @override
  String get errorServerResponse => '数据源响应异常。';

  @override
  String get errorLoginExpired => '登录已失效，请重新登录。';

  @override
  String get errorLocalDataCorrupted => '本地数据损坏。';

  @override
  String get errorGeneric => '操作失败，请稍后重试。';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get aboutFeedback => '提交反馈';

  @override
  String get aboutCache => '缓存';

  @override
  String get aboutHelp => '常见问题';

  @override
  String get newVersionTitle => '新版本';

  @override
  String get releaseNotesLabel => '发布日志';

  @override
  String get noReleaseNotes => '暂无更新说明。';

  @override
  String get updateNow => '立即下载';

  @override
  String get alreadyUpToDate => '已是最新版本';

  @override
  String get advancedSettingsTitle => '高级选项';

  @override
  String get advancedSettingsSubtitle => '代理、日志和调试工具';

  @override
  String get advancedSettingsDescription => '以下设置主要面向网络受限或排查问题场景，日常阅读通常无需修改。';

  @override
  String get advancedNetworkGroup => '网络';

  @override
  String get advancedDiagnosticsGroup => '日志与诊断';

  @override
  String get advancedProxyTitle => '代理设置';

  @override
  String get advancedProxySubtitle => '配置 HTTP / SOCKS5 代理以绕过网络限制';

  @override
  String get advancedViewLogsTitle => '查看日志';

  @override
  String get advancedViewLogsSubtitle => '浏览或导出最近的应用日志';

  @override
  String get proxyTitle => '代理';

  @override
  String get proxySubtitle =>
      '用于 API 和图片请求的 HTTP 代理。HTTPS 流量需要代理支持 CONNECT 方法。';

  @override
  String get proxyHint => 'http://127.0.0.1:7890';

  @override
  String get proxyInvalid => '请输入有效的代理地址';

  @override
  String get proxySaved => '代理已保存';

  @override
  String get proxyCleared => '代理已清除';

  @override
  String get proxyTest => '测试连接';

  @override
  String get proxyReachable => '代理可连接';

  @override
  String get proxyUnreachable => '无法连接到代理，请检查地址并确认代理已运行';

  @override
  String get proxyProtocolHint => '请确认 HTTP 代理支持 CONNECT 方法以转发 HTTPS 流量。';

  @override
  String get actionSave => '保存';

  @override
  String get actionClear => '清除';

  @override
  String get cacheTitle => '缓存';

  @override
  String get cacheCoverCache => '封面缓存';

  @override
  String get cacheImageCache => '漫画图片缓存';

  @override
  String get cacheDatabase => '本地数据库';

  @override
  String get cacheClearCovers => '清空封面缓存';

  @override
  String get cacheClearImages => '清空图片缓存';

  @override
  String get cacheClearAll => '清空全部缓存';

  @override
  String get cacheCoverCacheZeroHint => '当前封面未做本地磁盘缓存';

  @override
  String get cacheImageCacheZeroHint => '当前没有本地漫画图片缓存';

  @override
  String get deviceIdLabel => '设备 ID';

  @override
  String get deviceIdCopied => '设备 ID 已复制';

  @override
  String get faqTitle => '常见问题';

  @override
  String get faqSearchHint => '搜索问题';

  @override
  String get faqEmpty => '没有找到相关问题';

  @override
  String get faqModesQuestion => '这个 App 使用什么连接模式？';

  @override
  String get faqModesAnswer =>
      '当前版本只支持直连模式：App 直接连接 JM 的 API 和图片 CDN。本版本不提供后端模式，也不支持 Web/PWA。';

  @override
  String get faqModesDiffQuestion => '以后会支持后端模式吗？';

  @override
  String get faqModesDiffAnswer =>
      '本版本不包含后端模式和 Web/PWA 支持，当前仅支持 iOS 与 Android 的 JM 直连。';

  @override
  String get faqNoAccountQuestion => '不登录 JM 账号可以使用吗？';

  @override
  String get faqNoAccountAnswer =>
      '可以。未登录时可以浏览、搜索、阅读和收藏到本地。但只有登录 JM 账号后，才能把你的本地收藏与 JM 官方收藏合并，并在多设备间同步。';

  @override
  String get faqFavoriteHowQuestion => '收藏是怎么工作的？';

  @override
  String get faqFavoriteHowAnswer =>
      '收藏采用“本地优先”设计：\n\n• 点击收藏/取消收藏会立即写入本地并更新界面。\n\n• 需要与 JM 官方同步时，去收藏页（书架）点击右上角“同步”按钮。\n\n• 同步是手动的，App 不会自动在后台频繁刷新。';

  @override
  String get faqFavoriteOrderQuestion => '同步后收藏顺序为什么变了？';

  @override
  String get faqFavoriteOrderAnswer =>
      'JM 官方的收藏列表默认就是“后收藏的放在前面”。同步后 App 会尽量保持与官方一致的顺序，因此你可能会发现顺序和本地最初添加时不同。';

  @override
  String get faqReaderSlowQuestion => '阅读页加载慢或黑屏怎么办？';

  @override
  String get faqReaderSlowAnswer =>
      '可以按以下顺序排查：\n\n1. 检查网络或代理是否连通。\n2. 尝试在设置里切换代理或重新登录刷新 Cookie。\n3. 图片 CDN 会自动在多个域名之间选路，你也可以在设置里调整日志等级为 DEBUG，查看具体是哪张图片失败。\n4. 如果长时间黑屏，去 设置 > 高级选项 > 查看日志 看是否有 401 或 HandshakeException。';

  @override
  String get faqCdnQuestion => '什么是图片 CDN 自动选路？';

  @override
  String get faqCdnAnswer =>
      'App 会针对封面、正文等不同类型的图片，并发测试多个 JM 图片域名，选择当前最快的一个作为“优选域名”。\n\n如果后续某张图片在优选域名上失败，App 会先尝试其他域名下载这张图；只有当所有域名都失败时，才会重新选路。';

  @override
  String get faqProxyQuestion => '代理应该怎么设置？';

  @override
  String get faqProxyAnswer =>
      '在 设置 > 高级选项 > 代理设置 中填写 HTTP 或 SOCKS5 代理地址，例如 http://127.0.0.1:7890 或 socks5://127.0.0.1:1080。\n\n注意：HTTP 代理需要支持 CONNECT 方法来转发 HTTPS 流量。';

  @override
  String get faqErrorsQuestion =>
      '遇到 401 / HandshakeException / Connection refused 怎么办？';

  @override
  String get faqErrorsAnswer =>
      '• 401：通常是 JM 登录状态过期，去 设置 > JM 账号 重新登录或刷新登录。\n\n• HandshakeException：代理无法正确转发 HTTPS，或代理本身证书/协议不支持，请检查代理设置。\n\n• Connection refused：代理地址填错或代理程序没有启动，请确认代理可访问。';

  @override
  String get faqLogLevelQuestion => '日志等级有什么用？';

  @override
  String get faqLogLevelAnswer =>
      '设置里的“日志等级”决定哪些日志会被记录：\n\n• DEBUG：记录最详细，包括请求 URL、返回值、图片选路等，适合排查问题。\n• INFO / WARN / ERROR：逐级减少，日常使用时可以设为 INFO 或 WARN 来降低日志噪音。\n\n调整后会立即生效。';

  @override
  String get faqCacheLogsQuestion => '如何清理缓存或导出日志？';

  @override
  String get faqCacheLogsAnswer =>
      '• 清理缓存：设置 > 缓存，可分别清空封面缓存和漫画图片缓存。\n\n• 导出日志：设置 > 高级选项 > 查看日志，点击右上角分享按钮即可导出完整日志文件。';

  @override
  String get faqLogHint => '仍有问题？前往 设置 > 高级选项 > 查看日志 排查请求详情。';
}
