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

  /// No description provided for @actionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get actionCopy;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @imageDownload.
  ///
  /// In en, this message translates to:
  /// **'Download image'**
  String get imageDownload;

  /// No description provided for @imageDownloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Downloading image…'**
  String get imageDownloadStarted;

  /// No description provided for @imageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get imageLoading;

  /// No description provided for @imageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get imageLoadFailed;

  /// No description provided for @imageLoadRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get imageLoadRetryHint;

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

  /// No description provided for @searchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Search history'**
  String get searchHistoryTitle;

  /// No description provided for @emptySearchHistory.
  ///
  /// In en, this message translates to:
  /// **'No search history yet'**
  String get emptySearchHistory;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @confirmClearSearchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear search history?'**
  String get confirmClearSearchHistoryTitle;

  /// No description provided for @confirmClearSearchHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all search history.'**
  String get confirmClearSearchHistoryBody;

  /// No description provided for @searchHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Search history cleared'**
  String get searchHistoryCleared;

  /// No description provided for @searchHistoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Search history deleted'**
  String get searchHistoryDeleted;

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

  /// No description provided for @favoriteSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Favorites synced'**
  String get favoriteSyncSuccess;

  /// No description provided for @favoriteSyncPartialFailure.
  ///
  /// In en, this message translates to:
  /// **'Partial sync: {count} items failed'**
  String favoriteSyncPartialFailure(Object count);

  /// No description provided for @favoriteSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get favoriteSyncing;

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

  /// No description provided for @recentSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search reading history'**
  String get recentSearchHint;

  /// No description provided for @recentEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get recentEdit;

  /// No description provided for @recentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get recentCancel;

  /// No description provided for @recentSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get recentSelectAll;

  /// No description provided for @recentDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get recentDeselectAll;

  /// Bottom bar delete button with selected count
  ///
  /// In en, this message translates to:
  /// **'Delete ({count})'**
  String recentDelete(int count);

  /// Toast after deleting recent reading records
  ///
  /// In en, this message translates to:
  /// **'Deleted reading history for {count} manga'**
  String recentDeleted(int count);

  /// No description provided for @recentUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get recentUndo;

  /// AppBar title in recent read edit mode
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String recentSelectedCount(int count);

  /// No description provided for @recentSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching reading history'**
  String get recentSearchEmpty;

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

  /// No description provided for @calculatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get calculatingLabel;

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

  /// No description provided for @settingsLogLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Level'**
  String get settingsLogLevelTitle;

  /// No description provided for @settingsLogLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only record logs at or above the selected level'**
  String get settingsLogLevelSubtitle;

  /// No description provided for @logLevelDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get logLevelDebug;

  /// No description provided for @logLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logLevelInfo;

  /// No description provided for @logLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get logLevelWarning;

  /// No description provided for @logLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logLevelError;

  /// No description provided for @dialogAddAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Add JM Account'**
  String get dialogAddAccountTitle;

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

  /// No description provided for @loginRefreshSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Login refreshed'**
  String get loginRefreshSyncTitle;

  /// No description provided for @loginRefreshSyncBody.
  ///
  /// In en, this message translates to:
  /// **'Go to Library to sync?'**
  String get loginRefreshSyncBody;

  /// No description provided for @loginRefreshSyncLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get loginRefreshSyncLater;

  /// No description provided for @loginRefreshSyncGo.
  ///
  /// In en, this message translates to:
  /// **'Go Sync'**
  String get loginRefreshSyncGo;

  /// No description provided for @loginErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or password'**
  String get loginErrorUnauthorized;

  /// No description provided for @loginErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach JM. Please check your network connection.'**
  String get loginErrorNetwork;

  /// No description provided for @loginErrorServer.
  ///
  /// In en, this message translates to:
  /// **'JM service error. Please try again later.'**
  String get loginErrorServer;

  /// No description provided for @loginAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'Account added'**
  String get loginAccountAdded;

  /// No description provided for @loginMergeFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Logging in will merge your local favorites with your JM account favorites.'**
  String get loginMergeFavoritesHint;

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

  /// No description provided for @badgeChapterFinished.
  ///
  /// In en, this message translates to:
  /// **'{chapter}-100%'**
  String badgeChapterFinished(Object chapter);

  /// No description provided for @chapterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get chapterUnread;

  /// No description provided for @chapterReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get chapterReading;

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

  /// No description provided for @logsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search logs'**
  String get logsSearchHint;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @errorNetworkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Network unavailable. Please check your connection or proxy settings.'**
  String get errorNetworkUnavailable;

  /// No description provided for @errorServerResponse.
  ///
  /// In en, this message translates to:
  /// **'Data source returned an unexpected response.'**
  String get errorServerResponse;

  /// No description provided for @errorLoginExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get errorLoginExpired;

  /// No description provided for @errorLocalDataCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Local data is corrupted.'**
  String get errorLocalDataCorrupted;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again later.'**
  String get errorGeneric;

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

  /// No description provided for @aboutCache.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get aboutCache;

  /// No description provided for @aboutHelp.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get aboutHelp;

  /// No description provided for @newVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'New Version'**
  String get newVersionTitle;

  /// No description provided for @releaseNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotesLabel;

  /// No description provided for @noReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'No release notes.'**
  String get noReleaseNotes;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Download now'**
  String get updateNow;

  /// No description provided for @alreadyUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get alreadyUpToDate;

  /// No description provided for @advancedSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advancedSettingsTitle;

  /// No description provided for @advancedSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Proxy, logs, and debugging tools'**
  String get advancedSettingsSubtitle;

  /// No description provided for @advancedSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'These settings are mainly for network-restricted environments or troubleshooting. You usually don\'t need to change them for normal reading.'**
  String get advancedSettingsDescription;

  /// No description provided for @advancedNetworkGroup.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get advancedNetworkGroup;

  /// No description provided for @advancedDiagnosticsGroup.
  ///
  /// In en, this message translates to:
  /// **'Logs & Diagnostics'**
  String get advancedDiagnosticsGroup;

  /// No description provided for @advancedProxyTitle.
  ///
  /// In en, this message translates to:
  /// **'Proxy Settings'**
  String get advancedProxyTitle;

  /// No description provided for @advancedProxySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure an HTTP / SOCKS5 proxy to bypass network restrictions'**
  String get advancedProxySubtitle;

  /// No description provided for @advancedViewLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get advancedViewLogsTitle;

  /// No description provided for @advancedViewLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse or export recent app logs'**
  String get advancedViewLogsSubtitle;

  /// No description provided for @proxyTitle.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get proxyTitle;

  /// No description provided for @proxySubtitle.
  ///
  /// In en, this message translates to:
  /// **'HTTP proxy for API and image requests. HTTPS traffic needs CONNECT support.'**
  String get proxySubtitle;

  /// No description provided for @proxyHint.
  ///
  /// In en, this message translates to:
  /// **'http://127.0.0.1:7890'**
  String get proxyHint;

  /// No description provided for @proxyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid proxy address'**
  String get proxyInvalid;

  /// No description provided for @proxySaved.
  ///
  /// In en, this message translates to:
  /// **'Proxy saved'**
  String get proxySaved;

  /// No description provided for @proxyCleared.
  ///
  /// In en, this message translates to:
  /// **'Proxy cleared'**
  String get proxyCleared;

  /// No description provided for @proxyTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get proxyTest;

  /// No description provided for @proxyReachable.
  ///
  /// In en, this message translates to:
  /// **'Proxy reachable'**
  String get proxyReachable;

  /// No description provided for @proxyUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to proxy. Check the address and make sure the proxy is running.'**
  String get proxyUnreachable;

  /// No description provided for @proxyProtocolHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the HTTP proxy supports the CONNECT method for HTTPS traffic.'**
  String get proxyProtocolHint;

  /// No description provided for @customDomainTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Domain'**
  String get customDomainTitle;

  /// No description provided for @customDomainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Custom domains take priority. Leave blank to use the built-in domains.'**
  String get customDomainSubtitle;

  /// No description provided for @customDomainApiLabel.
  ///
  /// In en, this message translates to:
  /// **'API Domains'**
  String get customDomainApiLabel;

  /// No description provided for @customDomainImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image Domains'**
  String get customDomainImageLabel;

  /// No description provided for @customDomainHint.
  ///
  /// In en, this message translates to:
  /// **'example.com or https://192.168.1.2:8080'**
  String get customDomainHint;

  /// No description provided for @customDomainTest.
  ///
  /// In en, this message translates to:
  /// **'Test all connections'**
  String get customDomainTest;

  /// No description provided for @customDomainTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'All connections successful'**
  String get customDomainTestSuccess;

  /// No description provided for @customDomainTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Some connections failed'**
  String get customDomainTestFailed;

  /// No description provided for @customDomainNoDomainToTest.
  ///
  /// In en, this message translates to:
  /// **'No domain to test'**
  String get customDomainNoDomainToTest;

  /// No description provided for @customDomainAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add domain'**
  String get customDomainAddHint;

  /// No description provided for @customDomainEmpty.
  ///
  /// In en, this message translates to:
  /// **'No custom domains. Add one below.'**
  String get customDomainEmpty;

  /// No description provided for @customDomainLatency.
  ///
  /// In en, this message translates to:
  /// **'{ms}ms'**
  String customDomainLatency(Object ms);

  /// No description provided for @customDomainLatencyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get customDomainLatencyFailed;

  /// No description provided for @customDomainAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get customDomainAdded;

  /// No description provided for @customDomainMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get customDomainMoveUp;

  /// No description provided for @customDomainMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get customDomainMoveDown;

  /// No description provided for @customDomainDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get customDomainDelete;

  /// No description provided for @customDomainSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get customDomainSaved;

  /// No description provided for @customDomainCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get customDomainCleared;

  /// No description provided for @customDomainEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get customDomainEnabled;

  /// No description provided for @customDomainDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get customDomainDisabled;

  /// No description provided for @confirmDeleteDomainTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete domain'**
  String get confirmDeleteDomainTitle;

  /// No description provided for @confirmDeleteDomainBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this domain?'**
  String get confirmDeleteDomainBody;

  /// No description provided for @confirmClearDomainsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear domains'**
  String get confirmClearDomainsTitle;

  /// No description provided for @confirmClearDomainsBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all custom domains?'**
  String get confirmClearDomainsBody;

  /// No description provided for @unsavedChangesHint.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesHint;

  /// No description provided for @customDomainDragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get customDomainDragToReorder;

  /// No description provided for @saveBeforeLeavingTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get saveBeforeLeavingTitle;

  /// No description provided for @saveBeforeLeavingBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Save before leaving?'**
  String get saveBeforeLeavingBody;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChanges;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get actionExit;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit app'**
  String get exitAppTitle;

  /// No description provided for @exitAppBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the app?'**
  String get exitAppBody;

  /// No description provided for @cacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get cacheTitle;

  /// No description provided for @cacheCoverCache.
  ///
  /// In en, this message translates to:
  /// **'Cover cache'**
  String get cacheCoverCache;

  /// No description provided for @cacheImageCache.
  ///
  /// In en, this message translates to:
  /// **'Manga image cache'**
  String get cacheImageCache;

  /// No description provided for @cacheDatabase.
  ///
  /// In en, this message translates to:
  /// **'Local database'**
  String get cacheDatabase;

  /// No description provided for @cacheClearCovers.
  ///
  /// In en, this message translates to:
  /// **'Clear cover cache'**
  String get cacheClearCovers;

  /// No description provided for @cacheClearImages.
  ///
  /// In en, this message translates to:
  /// **'Clear image cache'**
  String get cacheClearImages;

  /// No description provided for @cacheClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all cache'**
  String get cacheClearAll;

  /// No description provided for @cacheCoverCacheZeroHint.
  ///
  /// In en, this message translates to:
  /// **'Covers are not persisted to disk yet'**
  String get cacheCoverCacheZeroHint;

  /// No description provided for @cacheImageCacheZeroHint.
  ///
  /// In en, this message translates to:
  /// **'No local manga image cache yet'**
  String get cacheImageCacheZeroHint;

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

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

  /// No description provided for @faqSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search questions'**
  String get faqSearchHint;

  /// No description provided for @faqEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching questions found'**
  String get faqEmpty;

  /// No description provided for @faqModesQuestion.
  ///
  /// In en, this message translates to:
  /// **'What connection mode does the app use?'**
  String get faqModesQuestion;

  /// No description provided for @faqModesAnswer.
  ///
  /// In en, this message translates to:
  /// **'The app only supports direct mode: it connects directly to JM\'s API and image CDN. There is no backend or Web/PWA support in this version.'**
  String get faqModesAnswer;

  /// No description provided for @faqModesDiffQuestion.
  ///
  /// In en, this message translates to:
  /// **'Will backend mode be supported?'**
  String get faqModesDiffQuestion;

  /// No description provided for @faqModesDiffAnswer.
  ///
  /// In en, this message translates to:
  /// **'Backend mode and Web/PWA support are not included in this version. The current build only supports iOS and Android with direct JM connections.'**
  String get faqModesDiffAnswer;

  /// No description provided for @faqNoAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Can I use the app without a JM account?'**
  String get faqNoAccountQuestion;

  /// No description provided for @faqNoAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes. Without logging in you can browse, search, read and save favorites locally. Logging in is only required to merge your local favorites with your JM account and sync across devices.'**
  String get faqNoAccountAnswer;

  /// No description provided for @faqFavoriteHowQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do favorites work?'**
  String get faqFavoriteHowQuestion;

  /// No description provided for @faqFavoriteHowAnswer.
  ///
  /// In en, this message translates to:
  /// **'Favorites are local-first:\n\n• Tapping favorite/unfavorite writes immediately to local storage and updates the UI.\n\n• To sync with JM, go to the Favorites tab and tap the \'Sync\' button in the top right.\n\n• Sync is manual; the app does not refresh automatically in the background.'**
  String get faqFavoriteHowAnswer;

  /// No description provided for @faqFavoriteOrderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why does the favorite order change after syncing?'**
  String get faqFavoriteOrderQuestion;

  /// No description provided for @faqFavoriteOrderAnswer.
  ///
  /// In en, this message translates to:
  /// **'JM\'s official favorite list puts the most recently favorited items first. After syncing, the app keeps the same order as JM, so it may differ from the order in which you originally added them locally.'**
  String get faqFavoriteOrderAnswer;

  /// No description provided for @faqReaderSlowQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should I do if the reader loads slowly or shows a black screen?'**
  String get faqReaderSlowQuestion;

  /// No description provided for @faqReaderSlowAnswer.
  ///
  /// In en, this message translates to:
  /// **'Try the following:\n\n1. Check your network or proxy connection.\n2. Try switching proxies or refreshing login in Settings to renew cookies.\n3. Image CDN auto-selection tests multiple domains; set the log level to DEBUG to see which image is failing.\n4. If it stays black, go to Settings > Advanced > View Logs and look for 401 or HandshakeException.'**
  String get faqReaderSlowAnswer;

  /// No description provided for @faqCdnQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is image CDN auto-selection?'**
  String get faqCdnQuestion;

  /// No description provided for @faqCdnAnswer.
  ///
  /// In en, this message translates to:
  /// **'The app races multiple JM image domains for each image type (covers, pages, etc.) and caches the fastest as the preferred domain.\n\nIf a single image later fails on that domain, the app tries other domains first; only when all domains fail does it re-select a preferred domain.'**
  String get faqCdnAnswer;

  /// No description provided for @faqProxyQuestion.
  ///
  /// In en, this message translates to:
  /// **'How should I configure a proxy?'**
  String get faqProxyQuestion;

  /// No description provided for @faqProxyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Advanced > Proxy Settings and enter an HTTP or SOCKS5 proxy, e.g. http://127.0.0.1:7890 or socks5://127.0.0.1:1080.\n\nNote: HTTP proxies must support the CONNECT method to forward HTTPS traffic.'**
  String get faqProxyAnswer;

  /// No description provided for @faqErrorsQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I fix 401 / HandshakeException / Connection refused?'**
  String get faqErrorsQuestion;

  /// No description provided for @faqErrorsAnswer.
  ///
  /// In en, this message translates to:
  /// **'• 401: usually means the JM session expired. Go to Settings > JM Accounts to re-login or refresh login.\n\n• HandshakeException: the proxy cannot forward HTTPS correctly, or its certificate/protocol is unsupported. Check your proxy settings.\n\n• Connection refused: the proxy address is wrong or the proxy is not running. Make sure it is reachable.'**
  String get faqErrorsAnswer;

  /// No description provided for @faqLogLevelQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do log levels work?'**
  String get faqLogLevelQuestion;

  /// No description provided for @faqLogLevelAnswer.
  ///
  /// In en, this message translates to:
  /// **'The log level in Settings controls which logs are recorded:\n\n• DEBUG: records everything including request URLs, responses and CDN selection. Best for troubleshooting.\n• INFO / WARN / ERROR: progressively quieter. Use INFO or WARN for daily use to reduce noise.\n\nChanges take effect immediately.'**
  String get faqLogLevelAnswer;

  /// No description provided for @faqCacheLogsQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I clear cache or export logs?'**
  String get faqCacheLogsQuestion;

  /// No description provided for @faqCacheLogsAnswer.
  ///
  /// In en, this message translates to:
  /// **'• Clear cache: Settings > Cache, where you can clear cover cache and manga image cache separately.\n\n• Export logs: Settings > Advanced > View Logs, then tap the share button in the top right to export the full log file.'**
  String get faqCacheLogsAnswer;

  /// No description provided for @faqLogHint.
  ///
  /// In en, this message translates to:
  /// **'Still stuck? Go to Settings > Advanced > View Logs for request details.'**
  String get faqLogHint;

  /// No description provided for @sectionContentFilter.
  ///
  /// In en, this message translates to:
  /// **'Content filter'**
  String get sectionContentFilter;
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
