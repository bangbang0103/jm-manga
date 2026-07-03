// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JM Manga';

  @override
  String get navHome => 'Home';

  @override
  String get navRankings => 'Rankings';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionViewAll => 'View all';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSearch => 'Search';

  @override
  String get imageDownload => 'Download image';

  @override
  String get imageDownloadStarted => 'Downloading image…';

  @override
  String get imageLoading => 'Loading…';

  @override
  String get imageLoadFailed => 'Load failed';

  @override
  String get imageLoadRetryHint => 'Tap to retry';

  @override
  String get actionLogin => 'Login';

  @override
  String get actionLoginLoading => 'Logging in...';

  @override
  String get actionDelete => 'Delete';

  @override
  String get searchHint => 'Search manga...';

  @override
  String get searchPrompt => 'Enter a keyword to search';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchHistoryTitle => 'Search history';

  @override
  String get emptySearchHistory => 'No search history yet';

  @override
  String get clearAll => 'Clear all';

  @override
  String get confirmClearSearchHistoryTitle => 'Clear search history?';

  @override
  String get confirmClearSearchHistoryBody =>
      'This will remove all search history.';

  @override
  String get searchHistoryCleared => 'Search history cleared';

  @override
  String get searchHistoryDeleted => 'Search history deleted';

  @override
  String get emptyNoItems => 'No items';

  @override
  String get sectionRecentRead => 'Recent Read';

  @override
  String get libraryTitle => 'Library';

  @override
  String get tabFavorite => 'Favorite';

  @override
  String get tabRecentRead => 'RecentRead';

  @override
  String get favoriteSearchHint => 'Search favorites';

  @override
  String get favoriteSyncSuccess => 'Favorites synced';

  @override
  String favoriteSyncPartialFailure(Object count) {
    return 'Partial sync: $count items failed';
  }

  @override
  String get favoriteSyncing => 'Syncing…';

  @override
  String get favoriteEmpty => 'No favorites yet';

  @override
  String get favoriteSyncNow => 'Sync now';

  @override
  String get recentEmpty => 'No reading history yet';

  @override
  String get recentBrowseManga => 'Browse manga';

  @override
  String get recentSearchHint => 'Search reading history';

  @override
  String get recentEdit => 'Edit';

  @override
  String get recentDone => 'Done';

  @override
  String get recentSelectAll => 'Select All';

  @override
  String get recentDeselectAll => 'Deselect All';

  @override
  String recentDelete(int count) {
    return 'Delete ($count)';
  }

  @override
  String recentDeleted(int count) {
    return 'Deleted reading history for $count manga';
  }

  @override
  String get recentUndo => 'Undo';

  @override
  String recentSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get recentSearchEmpty => 'No matching reading history';

  @override
  String get rankingsTitle => 'Rankings';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get sortBy => 'SortBy';

  @override
  String get sortTopView => 'TopView';

  @override
  String get sortTopFavorite => 'TopFavorite';

  @override
  String get sortTopRate => 'TopRate';

  @override
  String get rankingsEmpty => 'No rankings yet';

  @override
  String get categoryTitle => 'Category';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryHanman => 'Hanman';

  @override
  String get categoryHanmanSfw => 'General Hanman';

  @override
  String get categorySingle => 'Single';

  @override
  String get categoryAnother => 'Another';

  @override
  String get categoryShort => 'Short';

  @override
  String get categoryDoujin => 'Doujin';

  @override
  String get categoryMeiman => 'Meiman';

  @override
  String get orderMostRecent => 'Most Recent';

  @override
  String get orderMostViewed => 'Most Viewed';

  @override
  String get orderTopRated => 'Top Rated';

  @override
  String get orderTopFavorite => 'Top Favorite';

  @override
  String authorLabel(Object name) {
    return 'Author: $name';
  }

  @override
  String likesLabel(Object count) {
    return 'Likes $count';
  }

  @override
  String viewsLabel(Object count) {
    return 'Views $count';
  }

  @override
  String get synopsis => 'Synopsis';

  @override
  String chaptersTitle(Object count) {
    return 'Chapters ($count)';
  }

  @override
  String get jumpToHint => 'Jump to';

  @override
  String chapterTitle(Object number) {
    return 'Chapter $number';
  }

  @override
  String get readNow => 'Read Now';

  @override
  String pageCounter(Object current, Object total) {
    return 'Page $current / $total';
  }

  @override
  String get finishedBadge => 'Finished';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAccounts => 'JM Comic Accounts';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionReader => 'Reader & Filter';

  @override
  String get accountAnonymous => 'Anonymous / No account';

  @override
  String get accountAddTooltip => 'Add account';

  @override
  String get accountRefreshTooltip => 'Refresh login';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get calculatingLabel => 'Calculating…';

  @override
  String get preloadTitle => 'Preload Images';

  @override
  String get preloadSubtitle =>
      'Number of images to preload ahead while reading';

  @override
  String get gridColumnsTitle => 'Grid Columns';

  @override
  String get gridColumnsSubtitle => 'Number of manga covers per row';

  @override
  String get settingsLogLevelTitle => 'Log Level';

  @override
  String get settingsLogLevelSubtitle =>
      'Only record logs at or above the selected level';

  @override
  String get logLevelDebug => 'Debug';

  @override
  String get logLevelInfo => 'Info';

  @override
  String get logLevelWarning => 'Warning';

  @override
  String get logLevelError => 'Error';

  @override
  String get dialogAddAccountTitle => 'Add JM Account';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldUsernameRequired => 'Please enter a username';

  @override
  String get fieldPasswordRequired => 'Please enter a password';

  @override
  String get loginRefreshing => 'Refreshing login...';

  @override
  String get loginRefreshed => 'Login refreshed';

  @override
  String get loginRefreshSyncTitle => 'Login refreshed';

  @override
  String get loginRefreshSyncBody => 'Go to Library to sync?';

  @override
  String get loginRefreshSyncLater => 'Later';

  @override
  String get loginRefreshSyncGo => 'Go Sync';

  @override
  String get loginErrorUnauthorized => 'Incorrect username or password';

  @override
  String get loginErrorNetwork =>
      'Cannot reach JM. Please check your network connection.';

  @override
  String get loginErrorServer => 'JM service error. Please try again later.';

  @override
  String get loginAccountAdded => 'Account added';

  @override
  String get loginMergeFavoritesHint =>
      'Logging in will merge your local favorites with your JM account favorites.';

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get favoriteRemoved => 'Removed from favorites';

  @override
  String get badgeFinished => 'Finished';

  @override
  String badgePage(Object page) {
    return 'P$page';
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
  String get chapterUnread => 'Unread';

  @override
  String get logsTitle => 'Logs';

  @override
  String get logsExport => 'Export logs';

  @override
  String get logsClear => 'Clear logs';

  @override
  String get logsEmpty => 'No logs yet';

  @override
  String get logsAllLevels => 'All';

  @override
  String get logsSearchHint => 'Search logs';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get errorNetworkUnavailable =>
      'Network unavailable. Please check your connection or proxy settings.';

  @override
  String get errorServerResponse =>
      'Data source returned an unexpected response.';

  @override
  String get errorLoginExpired => 'Session expired. Please log in again.';

  @override
  String get errorLocalDataCorrupted => 'Local data is corrupted.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again later.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get aboutFeedback => 'Submit Feedback';

  @override
  String get aboutCache => 'Cache';

  @override
  String get aboutHelp => 'FAQ';

  @override
  String get newVersionTitle => 'New Version';

  @override
  String get releaseNotesLabel => 'Release Notes';

  @override
  String get noReleaseNotes => 'No release notes.';

  @override
  String get updateNow => 'Download now';

  @override
  String get alreadyUpToDate => 'Already up to date';

  @override
  String get advancedSettingsTitle => 'Advanced';

  @override
  String get advancedSettingsSubtitle => 'Proxy, logs, and debugging tools';

  @override
  String get advancedSettingsDescription =>
      'These settings are mainly for network-restricted environments or troubleshooting. You usually don\'t need to change them for normal reading.';

  @override
  String get advancedNetworkGroup => 'Network';

  @override
  String get advancedDiagnosticsGroup => 'Logs & Diagnostics';

  @override
  String get advancedProxyTitle => 'Proxy Settings';

  @override
  String get advancedProxySubtitle =>
      'Configure an HTTP / SOCKS5 proxy to bypass network restrictions';

  @override
  String get advancedViewLogsTitle => 'View Logs';

  @override
  String get advancedViewLogsSubtitle => 'Browse or export recent app logs';

  @override
  String get proxyTitle => 'Proxy';

  @override
  String get proxySubtitle =>
      'HTTP proxy for API and image requests. HTTPS traffic needs CONNECT support.';

  @override
  String get proxyHint => 'http://127.0.0.1:7890';

  @override
  String get proxyInvalid => 'Please enter a valid proxy address';

  @override
  String get proxySaved => 'Proxy saved';

  @override
  String get proxyCleared => 'Proxy cleared';

  @override
  String get proxyTest => 'Test connection';

  @override
  String get proxyReachable => 'Proxy reachable';

  @override
  String get proxyUnreachable =>
      'Cannot connect to proxy. Check the address and make sure the proxy is running.';

  @override
  String get proxyProtocolHint =>
      'Make sure the HTTP proxy supports the CONNECT method for HTTPS traffic.';

  @override
  String get customDomainTitle => 'Custom Domain';

  @override
  String get customDomainSubtitle =>
      'Custom domains take priority. Leave blank to use the built-in domains.';

  @override
  String get customDomainApiLabel => 'API Domains';

  @override
  String get customDomainImageLabel => 'Image Domains';

  @override
  String get customDomainHint => 'example.com or https://192.168.1.2:8080';

  @override
  String get customDomainTest => 'Test all connections';

  @override
  String get customDomainTestSuccess => 'All connections successful';

  @override
  String get customDomainTestFailed => 'Some connections failed';

  @override
  String get customDomainNoDomainToTest => 'No domain to test';

  @override
  String get customDomainAddHint => 'Add domain';

  @override
  String get customDomainEmpty => 'No custom domains. Add one below.';

  @override
  String customDomainLatency(Object ms) {
    return '${ms}ms';
  }

  @override
  String get customDomainLatencyFailed => 'Failed';

  @override
  String get customDomainAdded => 'Added';

  @override
  String get customDomainMoveUp => 'Move up';

  @override
  String get customDomainMoveDown => 'Move down';

  @override
  String get customDomainDelete => 'Delete';

  @override
  String get customDomainSaved => 'Saved';

  @override
  String get customDomainCleared => 'Cleared';

  @override
  String get customDomainEnabled => 'Enabled';

  @override
  String get customDomainDisabled => 'Disabled';

  @override
  String get confirmDeleteDomainTitle => 'Delete domain';

  @override
  String get confirmDeleteDomainBody =>
      'Are you sure you want to delete this domain?';

  @override
  String get confirmClearDomainsTitle => 'Clear domains';

  @override
  String get confirmClearDomainsBody =>
      'Are you sure you want to clear all custom domains?';

  @override
  String get unsavedChangesHint => 'Unsaved changes';

  @override
  String get customDomainDragToReorder => 'Drag to reorder';

  @override
  String get saveBeforeLeavingTitle => 'Unsaved changes';

  @override
  String get saveBeforeLeavingBody =>
      'You have unsaved changes. Save before leaving?';

  @override
  String get discardChanges => 'Discard';

  @override
  String get actionSave => 'Save';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionExit => 'Exit';

  @override
  String get exitAppTitle => 'Exit app';

  @override
  String get exitAppBody => 'Are you sure you want to exit the app?';

  @override
  String get cacheTitle => 'Cache';

  @override
  String get cacheCoverCache => 'Cover cache';

  @override
  String get cacheImageCache => 'Manga image cache';

  @override
  String get cacheDatabase => 'Local database';

  @override
  String get cacheClearCovers => 'Clear cover cache';

  @override
  String get cacheClearImages => 'Clear image cache';

  @override
  String get cacheClearAll => 'Clear all cache';

  @override
  String get cacheCoverCacheZeroHint => 'Covers are not persisted to disk yet';

  @override
  String get cacheImageCacheZeroHint => 'No local manga image cache yet';

  @override
  String get deviceIdLabel => 'Device ID';

  @override
  String get deviceIdCopied => 'Device ID copied';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get faqSearchHint => 'Search questions';

  @override
  String get faqEmpty => 'No matching questions found';

  @override
  String get faqModesQuestion => 'What connection mode does the app use?';

  @override
  String get faqModesAnswer =>
      'The app only supports direct mode: it connects directly to JM\'s API and image CDN. There is no backend or Web/PWA support in this version.';

  @override
  String get faqModesDiffQuestion => 'Will backend mode be supported?';

  @override
  String get faqModesDiffAnswer =>
      'Backend mode and Web/PWA support are not included in this version. The current build only supports iOS and Android with direct JM connections.';

  @override
  String get faqNoAccountQuestion => 'Can I use the app without a JM account?';

  @override
  String get faqNoAccountAnswer =>
      'Yes. Without logging in you can browse, search, read and save favorites locally. Logging in is only required to merge your local favorites with your JM account and sync across devices.';

  @override
  String get faqFavoriteHowQuestion => 'How do favorites work?';

  @override
  String get faqFavoriteHowAnswer =>
      'Favorites are local-first:\n\n• Tapping favorite/unfavorite writes immediately to local storage and updates the UI.\n\n• To sync with JM, go to the Favorites tab and tap the \'Sync\' button in the top right.\n\n• Sync is manual; the app does not refresh automatically in the background.';

  @override
  String get faqFavoriteOrderQuestion =>
      'Why does the favorite order change after syncing?';

  @override
  String get faqFavoriteOrderAnswer =>
      'JM\'s official favorite list puts the most recently favorited items first. After syncing, the app keeps the same order as JM, so it may differ from the order in which you originally added them locally.';

  @override
  String get faqReaderSlowQuestion =>
      'What should I do if the reader loads slowly or shows a black screen?';

  @override
  String get faqReaderSlowAnswer =>
      'Try the following:\n\n1. Check your network or proxy connection.\n2. Try switching proxies or refreshing login in Settings to renew cookies.\n3. Image CDN auto-selection tests multiple domains; set the log level to DEBUG to see which image is failing.\n4. If it stays black, go to Settings > Advanced > View Logs and look for 401 or HandshakeException.';

  @override
  String get faqCdnQuestion => 'What is image CDN auto-selection?';

  @override
  String get faqCdnAnswer =>
      'The app races multiple JM image domains for each image type (covers, pages, etc.) and caches the fastest as the preferred domain.\n\nIf a single image later fails on that domain, the app tries other domains first; only when all domains fail does it re-select a preferred domain.';

  @override
  String get faqProxyQuestion => 'How should I configure a proxy?';

  @override
  String get faqProxyAnswer =>
      'Go to Settings > Advanced > Proxy Settings and enter an HTTP or SOCKS5 proxy, e.g. http://127.0.0.1:7890 or socks5://127.0.0.1:1080.\n\nNote: HTTP proxies must support the CONNECT method to forward HTTPS traffic.';

  @override
  String get faqErrorsQuestion =>
      'How do I fix 401 / HandshakeException / Connection refused?';

  @override
  String get faqErrorsAnswer =>
      '• 401: usually means the JM session expired. Go to Settings > JM Accounts to re-login or refresh login.\n\n• HandshakeException: the proxy cannot forward HTTPS correctly, or its certificate/protocol is unsupported. Check your proxy settings.\n\n• Connection refused: the proxy address is wrong or the proxy is not running. Make sure it is reachable.';

  @override
  String get faqLogLevelQuestion => 'How do log levels work?';

  @override
  String get faqLogLevelAnswer =>
      'The log level in Settings controls which logs are recorded:\n\n• DEBUG: records everything including request URLs, responses and CDN selection. Best for troubleshooting.\n• INFO / WARN / ERROR: progressively quieter. Use INFO or WARN for daily use to reduce noise.\n\nChanges take effect immediately.';

  @override
  String get faqCacheLogsQuestion => 'How do I clear cache or export logs?';

  @override
  String get faqCacheLogsAnswer =>
      '• Clear cache: Settings > Cache, where you can clear cover cache and manga image cache separately.\n\n• Export logs: Settings > Advanced > View Logs, then tap the share button in the top right to export the full log file.';

  @override
  String get faqLogHint =>
      'Still stuck? Go to Settings > Advanced > View Logs for request details.';

  @override
  String get excludedTagsTitle => 'Excluded tags';

  @override
  String excludedTagsCount(Object count) {
    return '$count excluded';
  }

  @override
  String get excludedTagsEmpty => 'No excluded tags yet';

  @override
  String get excludedTagsHint => 'Enter a tag to exclude';

  @override
  String excludedTagsAdded(Object tag) {
    return 'Excluded “$tag”';
  }

  @override
  String excludedTagsRemoved(Object tag) {
    return 'Removed “$tag”';
  }

  @override
  String get searchFilterTitle => 'Filter';

  @override
  String get searchFilterCurrentExcludes => 'Current excludes';

  @override
  String get searchFilterGlobalExcludes => 'Global excluded tags';

  @override
  String get searchFilterAllowThisTime => 'Allow this time';

  @override
  String get searchFilterManageGlobal => 'Manage global excluded tags';

  @override
  String get searchFilterNoCurrentExcludes => 'No temporary excludes';

  @override
  String get sectionContentFilter => 'Content filter';
}
