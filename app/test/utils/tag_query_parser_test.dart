import 'package:flutter_test/flutter_test.dart';
import 'package:jm_manga/utils/tag_query_parser.dart';

void main() {
  group('TagQueryParser.parse', () {
    test('parses plain keywords', () {
      final request = TagQueryParser.parse('MANA 治愈');
      expect(request.keywords, 'MANA 治愈');
      expect(request.includes, isEmpty);
      expect(request.excludes, isEmpty);
    });

    test('parses include and exclude tags', () {
      final request = TagQueryParser.parse('MANA +无修正 -全彩');
      expect(request.keywords, 'MANA');
      expect(request.includes, ['无修正']);
      expect(request.excludes, ['全彩']);
    });

    test('compresses multiple spaces', () {
      final request = TagQueryParser.parse('MANA   +无修正    -全彩');
      expect(request.keywords, 'MANA');
      expect(request.includes, ['无修正']);
      expect(request.excludes, ['全彩']);
    });

    test('treats multiple +/- as keyword', () {
      final request = TagQueryParser.parse('++无修正 --全彩');
      expect(request.keywords, '++无修正 --全彩');
      expect(request.includes, isEmpty);
      expect(request.excludes, isEmpty);
    });

    test('later occurrence wins for same tag', () {
      final request = TagQueryParser.parse('-全彩 +全彩');
      expect(request.includes, ['全彩']);
      expect(request.excludes, isEmpty);

      final reversed = TagQueryParser.parse('+全彩 -全彩');
      expect(reversed.includes, isEmpty);
      expect(reversed.excludes, ['全彩']);
    });

    test('parses plus global excluded tag as allow-this-time', () {
      final request = TagQueryParser.parse(
        'MANA +全彩 +无修正',
        globalExcludes: const ['全彩'],
      );
      expect(request.keywords, 'MANA');
      expect(request.includes, ['无修正']);
      expect(request.allowedGlobal, ['全彩']);
    });
  });

  group('TagQueryParser.buildEffectiveQuery', () {
    test('includes explicit and global excludes', () {
      final request = SearchRequest(
        keywords: 'MANA',
        excludes: const ['全彩'],
        globalExcludes: const ['人妻'],
      );
      expect(TagQueryParser.buildEffectiveQuery(request), 'MANA -人妻 -全彩');
    });

    test('keeps explicit includes and excludes', () {
      final request = SearchRequest(
        keywords: 'MANA',
        includes: const ['无修正'],
        excludes: const ['全彩'],
      );
      expect(TagQueryParser.buildEffectiveQuery(request), 'MANA +无修正 -全彩');
    });

    test('allowed global tag is emitted as +tag', () {
      final request = SearchRequest(
        keywords: 'MANA',
        globalExcludes: const ['全彩'],
        allowedGlobal: const ['全彩'],
      );
      expect(TagQueryParser.buildEffectiveQuery(request), 'MANA +全彩');
    });

    test('explicit includes suppress matching global excludes', () {
      final request = SearchRequest(
        keywords: 'MANA',
        includes: const ['全彩'],
        globalExcludes: const ['全彩', '人妻'],
      );
      expect(TagQueryParser.buildEffectiveQuery(request), 'MANA +全彩 -人妻');
    });

    test('allowed globals suppress matching global excludes', () {
      final request = SearchRequest(
        keywords: 'MANA',
        globalExcludes: const ['全彩', '人妻'],
        allowedGlobal: const ['全彩'],
      );
      expect(TagQueryParser.buildEffectiveQuery(request), 'MANA +全彩 -人妻');
    });
  });

  group('TagQueryParser.buildHistoryQuery', () {
    test('does not include global excludes', () {
      final request = SearchRequest(
        keywords: 'MANA',
        excludes: const ['全彩'],
        globalExcludes: const ['人妻'],
      );
      expect(TagQueryParser.buildHistoryQuery(request), 'MANA -全彩');
    });

    test('includes allowed global tags as +tag', () {
      final request = SearchRequest(
        keywords: 'MANA',
        globalExcludes: const ['全彩'],
        allowedGlobal: const ['全彩'],
      );
      expect(TagQueryParser.buildHistoryQuery(request), 'MANA +全彩');
    });
  });
}
