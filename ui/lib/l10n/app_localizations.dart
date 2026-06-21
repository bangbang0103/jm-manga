import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'JM Manga'**
  String get appTitle;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRankings.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get navRankings;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get actionViewAll;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get actionLogin;

  /// No description provided for @actionLoginLoading.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get actionLoginLoading;

  /// No description provided for @actionConnectLoading.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get actionConnectLoading;

  /// No description provided for @actionScanLanLoading.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get actionScanLanLoading;

  /// No description provided for @actionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get actionConnect;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search manga...'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword to search'**
  String get searchPrompt;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchNoResults;

  /// No description provided for @emptyNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get emptyNoItems;

  /// No description provided for @sectionRecentRead.
  ///
  /// In en, this message translates to:
  /// **'Recent Read'**
  String get sectionRecentRead;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @tabFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get tabFavorite;

  /// No description provided for @tabRecentRead.
  ///
  /// In en, this message translates to:
  /// **'RecentRead'**
  String get tabRecentRead;

  /// No description provided for @favoriteSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search favorites'**
  String get favoriteSearchHint;

  /// No description provided for @favoriteSyncTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync favorites'**
  String get favoriteSyncTooltip;

  /// No description provided for @favoriteSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Favorites synced'**
  String get favoriteSyncSuccess;

  /// No description provided for @favoriteSyncFailure.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {message}'**
  String favoriteSyncFailure(Object message);

  /// No description provided for @favoriteEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoriteEmpty;

  /// No description provided for @favoriteSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get favoriteSyncNow;

  /// No description provided for @recentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reading history yet'**
  String get recentEmpty;

  /// No description provided for @recentBrowseManga.
  ///
  /// In en, this message translates to:
  /// **'Browse manga'**
  String get recentBrowseManga;

  /// No description provided for @libraryNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Please add a JM account in Settings'**
  String get libraryNeedAccount;

  /// No description provided for @libraryAnonymousDenied.
  ///
  /// In en, this message translates to:
  /// **'Anonymous account cannot access Library'**
  String get libraryAnonymousDenied;

  /// No description provided for @libraryGoSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get libraryGoSettings;

  /// No description provided for @rankingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rankings'**
  String get rankingsTitle;

  /// No description provided for @periodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'SortBy'**
  String get sortBy;

  /// No description provided for @sortTopView.
  ///
  /// In en, this message translates to:
  /// **'TopView'**
  String get sortTopView;

  /// No description provided for @sortTopFavorite.
  ///
  /// In en, this message translates to:
  /// **'TopFavorite'**
  String get sortTopFavorite;

  /// No description provided for @sortTopRate.
  ///
  /// In en, this message translates to:
  /// **'TopRate'**
  String get sortTopRate;

  /// No description provided for @rankingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rankings yet'**
  String get rankingsEmpty;

  /// No description provided for @categoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryTitle;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryHanman.
  ///
  /// In en, this message translates to:
  /// **'Hanman'**
  String get categoryHanman;

  /// No description provided for @categoryHanmanSfw.
  ///
  /// In en, this message translates to:
  /// **'General Hanman'**
  String get categoryHanmanSfw;

  /// No description provided for @categorySingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get categorySingle;

  /// No description provided for @categoryAnother.
  ///
  /// In en, this message translates to:
  /// **'Another'**
  String get categoryAnother;

  /// No description provided for @categoryShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get categoryShort;

  /// No description provided for @categoryDoujin.
  ///
  /// In en, this message translates to:
  /// **'Doujin'**
  String get categoryDoujin;

  /// No description provided for @categoryMeiman.
  ///
  /// In en, this message translates to:
  /// **'Meiman'**
  String get categoryMeiman;

  /// No description provided for @orderMostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get orderMostRecent;

  /// No description provided for @orderMostViewed.
  ///
  /// In en, this message translates to:
  /// **'Most Viewed'**
  String get orderMostViewed;

  /// No description provided for @orderTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top Rated'**
  String get orderTopRated;

  /// No description provided for @orderTopFavorite.
  ///
  /// In en, this message translates to:
  /// **'Top Favorite'**
  String get orderTopFavorite;

  /// No description provided for @authorLabel.
  ///
  /// In en, this message translates to:
  /// **'Author: {name}'**
  String authorLabel(Object name);

  /// No description provided for @likesLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes {count}'**
  String likesLabel(Object count);

  /// No description provided for @viewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Views {count}'**
  String viewsLabel(Object count);

  /// No description provided for @synopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get synopsis;

  /// No description provided for @chaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapters ({count})'**
  String chaptersTitle(Object count);

  /// No description provided for @jumpToHint.
  ///
  /// In en, this message translates to:
  /// **'Jump to'**
  String get jumpToHint;

  /// No description provided for @chapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterTitle(Object number);

  /// No description provided for @readNow.
  ///
  /// In en, this message translates to:
  /// **'Read Now'**
  String get readNow;

  /// No description provided for @progressUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get progressUnread;

  /// No description provided for @progressFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get progressFinished;

  /// No description provided for @progressPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String progressPage(Object page);

  /// No description provided for @progressStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get progressStarted;

  /// No description provided for @tooltipToggleFavorite.
  ///
  /// In en, this message translates to:
  /// **'Toggle favorite'**
  String get tooltipToggleFavorite;

  /// No description provided for @pageCounter.
  ///
  /// In en, this message translates to:
  /// **'Page {current} / {total}'**
  String pageCounter(Object current, Object total);

  /// No description provided for @finishedBadge.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finishedBadge;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get sectionService;

  /// No description provided for @sectionAccounts.
  ///
  /// In en, this message translates to:
  /// **'JM Comic Accounts'**
  String get sectionAccounts;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionReader.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get sectionReader;

  /// No description provided for @accountAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous / No account'**
  String get accountAnonymous;

  /// No description provided for @accountAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountAddTooltip;

  /// No description provided for @accountRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh login'**
  String get accountRefreshTooltip;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @coverCacheLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover cache'**
  String get coverCacheLabel;

  /// No description provided for @mangaImageCacheLabel.
  ///
  /// In en, this message translates to:
  /// **'Manga image cache'**
  String get mangaImageCacheLabel;

  /// No description provided for @dataUsageLabel.
  ///
  /// In en, this message translates to:
  /// **'Data usage'**
  String get dataUsageLabel;

  /// No description provided for @uptimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get uptimeLabel;

  /// No description provided for @calculatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get calculatingLabel;

  /// No description provided for @refreshLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLabel;

  /// No description provided for @preloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Preload Images'**
  String get preloadTitle;

  /// No description provided for @preloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Number of images to preload ahead while reading'**
  String get preloadSubtitle;

  /// No description provided for @gridColumnsTitle.
  ///
  /// In en, this message translates to:
  /// **'Grid Columns'**
  String get gridColumnsTitle;

  /// No description provided for @gridColumnsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Number of manga covers per row'**
  String get gridColumnsSubtitle;

  /// No description provided for @disconnectService.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Service'**
  String get disconnectService;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'JM Manga {version}'**
  String appVersion(Object version);

  /// No description provided for @dialogAddAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Add JM Account'**
  String get dialogAddAccountTitle;

  /// No description provided for @dialogEditAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit JM Account'**
  String get dialogEditAccountTitle;

  /// No description provided for @fieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUsername;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get fieldUsernameRequired;

  /// No description provided for @fieldPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get fieldPasswordRequired;

  /// No description provided for @loginRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing login...'**
  String get loginRefreshing;

  /// No description provided for @loginRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Login refreshed'**
  String get loginRefreshed;

  /// No description provided for @loginRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed: {message}'**
  String loginRefreshFailed(Object message);

  /// No description provided for @loginErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or password'**
  String get loginErrorUnauthorized;

  /// No description provided for @loginErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the service. Please check your server connection.'**
  String get loginErrorNetwork;

  /// No description provided for @loginErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get loginErrorServer;

  /// No description provided for @loginLoggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loginLoggingIn;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {message}'**
  String loginFailed(Object message);

  /// No description provided for @loginAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'Account added'**
  String get loginAccountAdded;

  /// No description provided for @serviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a service to begin, scan your local network, or add one manually.'**
  String get serviceSubtitle;

  /// No description provided for @actionManualAdd.
  ///
  /// In en, this message translates to:
  /// **'Manual Add'**
  String get actionManualAdd;

  /// No description provided for @actionScanLan.
  ///
  /// In en, this message translates to:
  /// **'Scan LAN'**
  String get actionScanLan;

  /// No description provided for @sectionYourServices.
  ///
  /// In en, this message translates to:
  /// **'Your Services'**
  String get sectionYourServices;

  /// No description provided for @serviceEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get serviceEmptyTitle;

  /// No description provided for @serviceEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a service manually or scan your local network to get started.'**
  String get serviceEmptyHint;

  /// No description provided for @actionAddService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get actionAddService;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @dialogConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to Service'**
  String get dialogConnectTitle;

  /// No description provided for @fieldTokenOptional.
  ///
  /// In en, this message translates to:
  /// **'Token (Optional)'**
  String get fieldTokenOptional;

  /// No description provided for @tokenHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if no token required'**
  String get tokenHint;

  /// No description provided for @dialogManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Service Manually'**
  String get dialogManualTitle;

  /// No description provided for @fieldNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (Optional)'**
  String get fieldNameOptional;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'My Home Server'**
  String get nameHint;

  /// No description provided for @dialogDeleteServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Service'**
  String get dialogDeleteServerTitle;

  /// No description provided for @dialogDeleteServerContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" from the service list?'**
  String dialogDeleteServerContent(Object name);

  /// No description provided for @fieldHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get fieldHost;

  /// No description provided for @hostHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.100'**
  String get hostHint;

  /// No description provided for @fieldHostRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a host address'**
  String get fieldHostRequired;

  /// No description provided for @fieldPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get fieldPort;

  /// No description provided for @portHint.
  ///
  /// In en, this message translates to:
  /// **'8000'**
  String get portHint;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Connect failed: {message}'**
  String connectFailed(Object message);

  /// No description provided for @connectFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Please check the host, port and token.'**
  String get connectFailedHint;

  /// No description provided for @scanNoServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services found on LAN. Try adding one manually.'**
  String get scanNoServicesFound;

  /// No description provided for @serverGateReconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reconnect to the last service. Please select or add a service.'**
  String get serverGateReconnectFailed;

  /// No description provided for @favoriteNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Please add a JM account to favorite'**
  String get favoriteNeedAccount;

  /// No description provided for @favoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favoriteAdded;

  /// No description provided for @favoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoriteRemoved;

  /// No description provided for @favoriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Favorite failed: {message}'**
  String favoriteFailed(Object message);

  /// No description provided for @urlValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid server address, e.g. http://127.0.0.1:8000'**
  String get urlValidationError;

  /// No description provided for @badgeFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get badgeFinished;

  /// No description provided for @badgePage.
  ///
  /// In en, this message translates to:
  /// **'P{page}'**
  String badgePage(Object page);

  /// No description provided for @badgePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String badgePercent(Object percent);

  /// No description provided for @badgeChapterPercent.
  ///
  /// In en, this message translates to:
  /// **'{chapter}·{percent}%'**
  String badgeChapterPercent(Object chapter, Object percent);

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsTitle;

  /// No description provided for @logsExport.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get logsExport;

  /// No description provided for @logsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get logsClear;

  /// No description provided for @logsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logsEmpty;

  /// No description provided for @logsAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get logsAllLevels;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutGitHub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get aboutGitHub;

  /// No description provided for @aboutFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get aboutFeedback;

  /// No description provided for @aboutViewLogs.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get aboutViewLogs;

  /// No description provided for @aboutHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get aboutHelp;

  /// No description provided for @deviceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceIdLabel;

  /// No description provided for @deviceIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Device ID copied'**
  String get deviceIdCopied;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'JM Manga is a self-hosted manga reader. Below is a quick guide to the main features.'**
  String get helpIntro;

  /// No description provided for @helpServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a service'**
  String get helpServerTitle;

  /// No description provided for @helpServerBody.
  ///
  /// In en, this message translates to:
  /// **'On the first launch the app tries to reconnect to the last used service. If that fails, you can:\n\n• Add a service manually by entering its host, port and optional token.\n\n• Scan the local network to discover services advertised via mDNS.\n\n• Tap a discovered or saved service to connect.'**
  String get helpServerBody;

  /// No description provided for @helpBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and search'**
  String get helpBrowseTitle;

  /// No description provided for @helpBrowseBody.
  ///
  /// In en, this message translates to:
  /// **'The Home tab shows featured and recently updated albums. Use the Rankings tab to see popular titles by day, week or month. Tap the search icon to search by title or click a tag on an album detail page to search for that tag.'**
  String get helpBrowseBody;

  /// No description provided for @helpFavoriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get helpFavoriteTitle;

  /// No description provided for @helpFavoriteBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a cover or album detail page to add the album to your favorites. Favorites are tied to your JM account and can be synced across devices. You need to add a JM account in Settings to use favorites.'**
  String get helpFavoriteBody;

  /// No description provided for @helpReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get helpReadTitle;

  /// No description provided for @helpReadBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Read Now\' on an album detail page or select a chapter from the list. While reading, tap the screen to show the toolbar where you can see your progress, jump chapters and toggle favorite. Reading progress is synced automatically.'**
  String get helpReadBody;

  /// No description provided for @helpAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get helpAccountTitle;

  /// No description provided for @helpAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > JM Comic Accounts to add or manage JM accounts. The app supports multiple accounts; tap one to switch. Anonymous mode is available but cannot use favorites or the Library.'**
  String get helpAccountBody;

  /// No description provided for @helpLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get helpLogTitle;

  /// No description provided for @helpLogBody.
  ///
  /// In en, this message translates to:
  /// **'If something goes wrong, go to Settings > About > View Logs to see recent requests and errors. You can filter by log level, copy a single log entry, or export the full log to share for debugging.'**
  String get helpLogBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
