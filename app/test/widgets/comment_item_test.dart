import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/l10n/app_localizations.dart';
import 'package:jm_manga/models/comment.dart';
import 'package:jm_manga/widgets/comment_item.dart';

void main() {
  group('CommentItem spoiler', () {
    Widget build(Widget child) {
      return MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );
    }

    Comment makeComment({required bool isSpoiler}) => Comment(
          id: '1',
          uid: '42',
          username: 'tester',
          level: 5,
          levelName: 'Lv5',
          content: '<div>secret ending explained</div>',
          likes: '0',
          addTime: 'Sep 01, 2026',
          isSpoiler: isSpoiler,
        );

    testWidgets('spoiler content is masked until tapped', (tester) async {
      await tester.pumpWidget(
        build(SingleChildScrollView(child: CommentItem(comment: makeComment(isSpoiler: true)))),
      );

      // 遮罩态：提示可见，正文被 ImageFiltered 模糊包裹。
      expect(find.text('剧透 · 点击查看剧透内容'), findsOneWidget);
      expect(find.text('secret ending explained'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsOneWidget);

      await tester.tap(find.text('剧透 · 点击查看剧透内容'));
      await tester.pump();

      // 揭示态：提示消失，正文不再模糊。
      expect(find.text('剧透 · 点击查看剧透内容'), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.text('secret ending explained'), findsOneWidget);
    });

    testWidgets('hides like icon when likes is zero', (tester) async {
      await tester.pumpWidget(
        build(SingleChildScrollView(child: CommentItem(comment: makeComment(isSpoiler: false)))),
      );

      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);

      final liked = Comment(
        id: '2',
        uid: '42',
        username: 'tester',
        level: 5,
        levelName: 'Lv5',
        content: 'nice',
        likes: '128',
        addTime: 'Sep 01, 2026',
      );
      await tester.pumpWidget(
        build(SingleChildScrollView(child: CommentItem(comment: liked))),
      );

      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
    });

    testWidgets('non-spoiler content renders directly without mask', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(SingleChildScrollView(child: CommentItem(comment: makeComment(isSpoiler: false)))),
      );

      expect(find.text('secret ending explained'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.textContaining('剧透'), findsNothing);
    });
  });
}
