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
  String errorWithMessage(Object message) {
    return '错误：$message';
  }

  @override
  String get loading => '加载中…';

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
  String get actionAdd => '添加';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionLogin => '登录';

  @override
  String get actionLoginLoading => '登录中…';

  @override
  String get actionConnectLoading => '连接中…';

  @override
  String get actionScanLanLoading => '扫描中…';

  @override
  String get actionConnect => '连接';

  @override
  String get actionRefresh => '刷新';

  @override
  String get actionDelete => '删除';

  @override
  String get searchHint => '搜索漫画…';

  @override
  String get searchPrompt => '输入关键词开始搜索';

  @override
  String get searchNoResults => '无结果';

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
  String get favoriteSyncTooltip => '同步收藏';

  @override
  String get favoriteSyncSuccess => '收藏已同步';

  @override
  String favoriteSyncFailure(Object message) {
    return '同步失败：$message';
  }

  @override
  String get favoriteEmpty => '暂无收藏';

  @override
  String get favoriteSyncNow => '立即同步';

  @override
  String get recentEmpty => '暂无阅读记录';

  @override
  String get recentBrowseManga => '去逛逛';

  @override
  String get libraryNeedAccount => '请先在设置中添加 JM 账号';

  @override
  String get libraryAnonymousDenied => '匿名账号无法使用书架';

  @override
  String get libraryGoSettings => '前往设置';

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
  String get progressUnread => '未读';

  @override
  String get progressFinished => '已读完';

  @override
  String progressPage(Object page) {
    return '读到第 $page 页';
  }

  @override
  String get progressStarted => '已开始';

  @override
  String get tooltipToggleFavorite => '切换收藏';

  @override
  String pageCounter(Object current, Object total) {
    return '第 $current / $total 页';
  }

  @override
  String get finishedBadge => '已读完';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionService => '服务';

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
  String get coverCacheLabel => '封面缓存';

  @override
  String get mangaImageCacheLabel => '漫画图片缓存';

  @override
  String get dataUsageLabel => '数据占用';

  @override
  String get uptimeLabel => '在线时长';

  @override
  String get calculatingLabel => '计算中…';

  @override
  String get refreshLabel => '刷新';

  @override
  String get preloadTitle => '预加载图片';

  @override
  String get preloadSubtitle => '阅读时提前预加载往后的图片数量';

  @override
  String get gridColumnsTitle => '每行封面数';

  @override
  String get gridColumnsSubtitle => '漫画封面每行显示的个数';

  @override
  String get disconnectService => '断开服务';

  @override
  String appVersion(Object version) {
    return 'JM Manga $version';
  }

  @override
  String get dialogAddAccountTitle => '添加 JM 账号';

  @override
  String get dialogEditAccountTitle => '编辑 JM 账号';

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
  String loginRefreshFailed(Object message) {
    return '刷新失败：$message';
  }

  @override
  String get loginErrorUnauthorized => '用户名或密码错误';

  @override
  String get loginErrorNetwork => '无法连接到服务，请检查服务器连接';

  @override
  String get loginErrorServer => '服务器错误，请稍后再试';

  @override
  String get loginLoggingIn => '正在登录…';

  @override
  String loginFailed(Object message) {
    return '登录失败：$message';
  }

  @override
  String get loginAccountAdded => '账号已添加';

  @override
  String get serviceSubtitle => '选择已有服务、扫描局域网，或手动添加新服务开始。';

  @override
  String get actionManualAdd => '手动添加';

  @override
  String get actionScanLan => '扫描局域网';

  @override
  String get sectionYourServices => '您的服务';

  @override
  String get serviceEmptyTitle => '还没有服务';

  @override
  String get serviceEmptyHint => '您可以手动添加服务，或扫描局域网自动发现。';

  @override
  String get actionAddService => '添加服务';

  @override
  String get statusOnline => '在线';

  @override
  String get statusOffline => '离线';

  @override
  String get statusUnknown => '未知';

  @override
  String get dialogConnectTitle => '连接到服务';

  @override
  String get fieldTokenOptional => 'Token（可选）';

  @override
  String get tokenHint => '无需 Token 请留空';

  @override
  String get dialogManualTitle => '手动添加服务';

  @override
  String get fieldNameOptional => '名称（可选）';

  @override
  String get nameHint => '我的家庭服务';

  @override
  String get dialogDeleteServerTitle => '删除服务';

  @override
  String dialogDeleteServerContent(Object name) {
    return '从服务列表中删除 \"$name\"？';
  }

  @override
  String get fieldHost => '主机';

  @override
  String get hostHint => '192.168.1.100';

  @override
  String get fieldHostRequired => '请输入主机地址';

  @override
  String get fieldPort => '端口';

  @override
  String get portHint => '8000';

  @override
  String connectFailed(Object message) {
    return '连接失败：$message';
  }

  @override
  String get connectFailedHint => '请检查主机、端口和 Token 是否正确。';

  @override
  String get scanNoServicesFound => '局域网未找到服务，您可以尝试手动添加。';

  @override
  String get serverGateReconnectFailed => '无法重新连接到上次使用的服务，请选择或添加服务。';

  @override
  String get favoriteNeedAccount => '请先添加 JM 账号以使用收藏';

  @override
  String get favoriteAdded => '已添加到收藏';

  @override
  String get favoriteRemoved => '已取消收藏';

  @override
  String favoriteFailed(Object message) {
    return '收藏失败：$message';
  }

  @override
  String get urlValidationError => '请输入有效的服务器地址，例如 http://127.0.0.1:8000';

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
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get aboutFeedback => '提交反馈';

  @override
  String get aboutViewLogs => '查看日志';

  @override
  String get aboutHelp => '使用帮助';

  @override
  String get deviceIdLabel => '设备 ID';

  @override
  String get deviceIdCopied => '设备 ID 已复制';

  @override
  String get helpTitle => '使用帮助';

  @override
  String get helpIntro => 'JM Manga 是一款自托管漫画阅读工具。下面是主要功能的使用说明。';

  @override
  String get helpServerTitle => '连接服务';

  @override
  String get helpServerBody =>
      '首次打开应用时会尝试重新连接上次使用的服务。如果连接失败，您可以：\n\n• 手动输入主机、端口和可选 Token 添加服务。\n\n• 扫描局域网，自动发现通过 mDNS 广播的服务。\n\n• 点击已发现或已保存的服务进行连接。';

  @override
  String get helpBrowseTitle => '浏览与搜索';

  @override
  String get helpBrowseBody =>
      '首页展示推荐和最近更新的漫画；排行榜页可按日/周/月查看热门作品。点击搜索图标可按标题搜索，或在漫画详情页点击标签搜索同类漫画。';

  @override
  String get helpFavoriteTitle => '收藏';

  @override
  String get helpFavoriteBody =>
      '在封面或漫画详情页点击心形图标即可收藏。收藏与 JM 账号绑定，可在多设备间同步。使用收藏功能需要先在设置中添加 JM 账号。';

  @override
  String get helpReadTitle => '阅读';

  @override
  String get helpReadBody =>
      '在漫画详情页点击“立即阅读”或从章节列表选择章节即可开始阅读。阅读时点击屏幕可显示工具栏，查看进度、切换章节或切换收藏状态。阅读进度会自动同步。';

  @override
  String get helpAccountTitle => '账号';

  @override
  String get helpAccountBody =>
      '前往 设置 > JM 账号 添加或管理 JM 账号。应用支持多账号，点击即可切换。匿名模式可用，但无法使用收藏和书架功能。';

  @override
  String get helpLogTitle => '问题排查';

  @override
  String get helpLogBody =>
      '如果遇到问题，可前往 设置 > 关于 > 查看日志 查看最近的请求和错误。您可以按日志等级筛选、长按单条复制，或导出完整日志用于反馈。';
}
