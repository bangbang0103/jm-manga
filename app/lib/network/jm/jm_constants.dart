class JmConstants {
  const JmConstants._();

  static const appTokenSecret = '185Hcomic3PAPP7R';
  static const appTokenSecretForContent = '18comicAPPContent';
  static const appDataSecret = '185Hcomic3PAPP7R';
  static const appVersion = '2.0.26';

  static const scramble220980 = 220980;
  static const scramble268850 = 268850;
  static const scramble421926 = 421926;

  static const apiDomains = <String>[
    // 2026-06-27 从 Android 缓存确认可用
    'www.cdngwc.cc',
    'www.cdnhjk.net',
    'www.cdngwc.net',
    'www.cdngwc.club',
    'www.cdnutc.me',
    // 历史 fallback，保留以备恢复
    'www.cdnaspa.club',
    'www.cdnaspa.vip',
    'www.cdnplaystation6.cc',
    'www.cdnplaystation6.vip',
  ];

  static const imageDomains = <String>[
    'cdn-msp.jmapiproxy1.cc',
    'cdn-msp.jmapiproxy2.cc',
    'cdn-msp2.jmapiproxy2.cc',
    'cdn-msp3.jmapiproxy2.cc',
    'cdn-msp.jmapinodeudzn.net',
    'cdn-msp3.jmapinodeudzn.net',
  ];

  static const appUserAgent =
      'Mozilla/5.0 (Linux; Android 9; V1938CT Build/PQ3A.190705.11211812; wv) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 '
      'Chrome/91.0.4472.114 Safari/537.36';

  /// 域名服务器下发配置时使用的解密密钥。
  static const apiDomainServerSecret = 'diosfjckwpqpdfjkvnqQjsik';

  /// 域名服务器地址列表，用于动态获取当前可用的 JM API 域名。
  static const apiDomainUpdateUrls = <String>[
    'https://rup4a04-c01.tos-ap-southeast-1.bytepluses.com/newsvr-2025.txt',
    'https://rup4a04-c02.tos-cn-hongkong.bytepluses.com/newsvr-2025.txt',
    'https://rup4a04-c03.tos-cn-beijing.bytepluses.com.cn/newsvr-2025.txt',
  ];
}
