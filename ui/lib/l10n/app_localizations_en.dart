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
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get loading => 'Loading...';

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
  String get actionAdd => 'Add';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionLogin => 'Login';

  @override
  String get actionLoginLoading => 'Logging in...';

  @override
  String get actionConnectLoading => 'Connecting...';

  @override
  String get actionScanLanLoading => 'Scanning...';

  @override
  String get actionConnect => 'Connect';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionDelete => 'Delete';

  @override
  String get searchHint => 'Search manga...';

  @override
  String get searchPrompt => 'Enter a keyword to search';

  @override
  String get searchNoResults => 'No results';

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
  String get favoriteSyncTooltip => 'Sync favorites';

  @override
  String get favoriteSyncSuccess => 'Favorites synced';

  @override
  String favoriteSyncFailure(Object message) {
    return 'Sync failed: $message';
  }

  @override
  String get favoriteEmpty => 'No favorites yet';

  @override
  String get favoriteSyncNow => 'Sync now';

  @override
  String get recentEmpty => 'No reading history yet';

  @override
  String get recentBrowseManga => 'Browse manga';

  @override
  String get libraryNeedAccount => 'Please add a JM account in Settings';

  @override
  String get libraryAnonymousDenied =>
      'Anonymous account cannot access Library';

  @override
  String get libraryGoSettings => 'Go to Settings';

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
  String get progressUnread => 'Unread';

  @override
  String get progressFinished => 'Finished';

  @override
  String progressPage(Object page) {
    return 'Page $page';
  }

  @override
  String get progressStarted => 'Started';

  @override
  String get tooltipToggleFavorite => 'Toggle favorite';

  @override
  String pageCounter(Object current, Object total) {
    return 'Page $current / $total';
  }

  @override
  String get finishedBadge => 'Finished';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionService => 'Service';

  @override
  String get sectionAccounts => 'JM Comic Accounts';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionReader => 'Reader';

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
  String get coverCacheLabel => 'Cover cache';

  @override
  String get mangaImageCacheLabel => 'Manga image cache';

  @override
  String get dataUsageLabel => 'Data usage';

  @override
  String get uptimeLabel => 'Uptime';

  @override
  String get calculatingLabel => 'Calculating…';

  @override
  String get refreshLabel => 'Refresh';

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
  String get disconnectService => 'Disconnect Service';

  @override
  String appVersion(Object version) {
    return 'JM Manga $version';
  }

  @override
  String get dialogAddAccountTitle => 'Add JM Account';

  @override
  String get dialogEditAccountTitle => 'Edit JM Account';

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
  String loginRefreshFailed(Object message) {
    return 'Refresh failed: $message';
  }

  @override
  String get loginErrorUnauthorized => 'Incorrect username or password';

  @override
  String get loginErrorNetwork =>
      'Cannot reach the service. Please check your server connection.';

  @override
  String get loginErrorServer => 'Server error. Please try again later.';

  @override
  String get loginLoggingIn => 'Logging in...';

  @override
  String loginFailed(Object message) {
    return 'Login failed: $message';
  }

  @override
  String get loginAccountAdded => 'Account added';

  @override
  String get serviceSubtitle =>
      'Select a service to begin, scan your local network, or add one manually.';

  @override
  String get actionManualAdd => 'Manual Add';

  @override
  String get actionScanLan => 'Scan LAN';

  @override
  String get sectionYourServices => 'Your Services';

  @override
  String get serviceEmptyTitle => 'No services yet';

  @override
  String get serviceEmptyHint =>
      'Add a service manually or scan your local network to get started.';

  @override
  String get actionAddService => 'Add Service';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get dialogConnectTitle => 'Connect to Service';

  @override
  String get fieldTokenOptional => 'Token (Optional)';

  @override
  String get tokenHint => 'Leave empty if no token required';

  @override
  String get dialogManualTitle => 'Add Service Manually';

  @override
  String get fieldNameOptional => 'Name (Optional)';

  @override
  String get nameHint => 'My Home Server';

  @override
  String get dialogDeleteServerTitle => 'Delete Service';

  @override
  String dialogDeleteServerContent(Object name) {
    return 'Delete \"$name\" from the service list?';
  }

  @override
  String get fieldHost => 'Host';

  @override
  String get hostHint => '192.168.1.100';

  @override
  String get fieldHostRequired => 'Please enter a host address';

  @override
  String get fieldPort => 'Port';

  @override
  String get portHint => '8000';

  @override
  String connectFailed(Object message) {
    return 'Connect failed: $message';
  }

  @override
  String get connectFailedHint => 'Please check the host, port and token.';

  @override
  String get scanNoServicesFound =>
      'No services found on LAN. Try adding one manually.';

  @override
  String get serverGateReconnectFailed =>
      'Could not reconnect to the last service. Please select or add a service.';

  @override
  String get favoriteNeedAccount => 'Please add a JM account to favorite';

  @override
  String get favoriteAdded => 'Added to favorites';

  @override
  String get favoriteRemoved => 'Removed from favorites';

  @override
  String favoriteFailed(Object message) {
    return 'Favorite failed: $message';
  }

  @override
  String get urlValidationError =>
      'Please enter a valid server address, e.g. http://127.0.0.1:8000';

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
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutGitHub => 'GitHub';

  @override
  String get aboutFeedback => 'Submit Feedback';

  @override
  String get aboutViewLogs => 'View Logs';

  @override
  String get aboutHelp => 'Help';

  @override
  String get deviceIdLabel => 'Device ID';

  @override
  String get deviceIdCopied => 'Device ID copied';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpIntro =>
      'JM Manga is a self-hosted manga reader. Below is a quick guide to the main features.';

  @override
  String get helpServerTitle => 'Connect to a service';

  @override
  String get helpServerBody =>
      'On the first launch the app tries to reconnect to the last used service. If that fails, you can:\n\n• Add a service manually by entering its host, port and optional token.\n\n• Scan the local network to discover services advertised via mDNS.\n\n• Tap a discovered or saved service to connect.';

  @override
  String get helpBrowseTitle => 'Browse and search';

  @override
  String get helpBrowseBody =>
      'The Home tab shows featured and recently updated albums. Use the Rankings tab to see popular titles by day, week or month. Tap the search icon to search by title or click a tag on an album detail page to search for that tag.';

  @override
  String get helpFavoriteTitle => 'Favorites';

  @override
  String get helpFavoriteBody =>
      'Tap the heart on a cover or album detail page to add the album to your favorites. Favorites are tied to your JM account and can be synced across devices. You need to add a JM account in Settings to use favorites.';

  @override
  String get helpReadTitle => 'Reading';

  @override
  String get helpReadBody =>
      'Tap \'Read Now\' on an album detail page or select a chapter from the list. While reading, tap the screen to show the toolbar where you can see your progress, jump chapters and toggle favorite. Reading progress is synced automatically.';

  @override
  String get helpAccountTitle => 'Accounts';

  @override
  String get helpAccountBody =>
      'Go to Settings > JM Comic Accounts to add or manage JM accounts. The app supports multiple accounts; tap one to switch. Anonymous mode is available but cannot use favorites or the Library.';

  @override
  String get helpLogTitle => 'Troubleshooting';

  @override
  String get helpLogBody =>
      'If something goes wrong, go to Settings > About > View Logs to see recent requests and errors. You can filter by log level, copy a single log entry, or export the full log to share for debugging.';
}
