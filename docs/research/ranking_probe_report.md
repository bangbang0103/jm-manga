# JMComic 排行榜接口实测报告

- 生成时间：`2026-06-17T22:54:12+08:00`
- 项目版本：`2.7.0`
- 请求策略：串行请求；每次请求前等待 `4.0` 秒；每个榜单只请求第 1 页；每个返回只记录前 2 条摘要；不下载图片。
- 运行命令：`python usage/probe_rankings.py --sleep 4.0`

## 可请求的排行榜接口

| 项目方法 | 榜单 | 底层 App API | 关键参数 | 说明 |
| --- | --- | --- | --- | --- |
| `day_ranking(page, category='0')` | 日榜 | `GET /categories/filter` | `o=mv_t` | `mv` + `t`，按今日观看排行 |
| `week_ranking(page, category='0')` | 周榜 | `GET /categories/filter` | `o=mv_w` | `mv` + `w`，按本周观看排行 |
| `month_ranking(page, category='0')` | 月榜 | `GET /categories/filter` | `o=mv_m` | `mv` + `m`，按本月观看排行 |

这些方法都接受 `category` 参数，因此可以请求总榜 `c=0`，也可以请求各父分类榜单，例如 `c=doujin`、`c=hanman`。

## App API 榜单结果

| 分类 | 榜单 | 方法 | o 参数 | 状态 | total | page_count | count | 前 2 条 album_id / title |
| --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |
| 0 / all / 全部 | 日榜 | `day_ranking` | `mv_t` | 成功 | 167 | 3 | 80 | `1446996` [宇宙田協] [甘泉少女 (のとくるみ)] 初戀の母さんにデカチン童貞を捧げて僕の赤ちゃんを孕んでもらうまでの話 [中國翻譯] [DL版]<br>`1446936` [藥舐太郎] 鬼滅ヒロインズ對催眠鬼 (鬼滅の刃) [AI Generated] RATKING機翻] |
| 0 / all / 全部 | 周榜 | `week_ranking` | `mv_w` | 成功 | 245 | 4 | 80 | `1446782` [隻因你AI] 在超市後門抽肉菸的女人<br>`1446859` [千字笙] tsf漫展一日記 [AI Generated] |
| 0 / all / 全部 | 月榜 | `month_ranking` | `mv_m` | 成功 | 1723 | 22 | 80 | `1445682` [きつねのおんがえし (スズガミ)] サキュバス酒場 ユメカナウ Episode of LUMI [中國翻譯] [DL版]<br>`1444110` [いわお] 六花ちゃん (SSSS.GRIDMAN) [中國翻譯][星屑飛塵個人漢化] |
| another / Other/Cosplay / 其他类 | 日榜 | `day_ranking` | `mv_t` | 成功 | 10 | 1 | 10 | `1447141` [Queltza]我們的承諾(Our Promise)01-07<br>`1447108` [Kaba] 卑媚 01 |
| another / Other/Cosplay / 其他类 | 周榜 | `week_ranking` | `mv_w` | 成功 | 12 | 1 | 12 | `1446863` [] 截癱師母性冷妻 01-07<br>`1446871` [zzzz] 不死癡女 玲玉 00-01 |
| another / Other/Cosplay / 其他类 | 月榜 | `month_ranking` | `mv_m` | 成功 | 114 | 2 | 80 | `1444357` [不愛我就拉倒] [女友小葉] 第一章 (1-2)<br>`1444545` [3D]冊母為後01-04 |
| doujin / 同人 | 日榜 | `day_ranking` | `mv_t` | 成功 | 147 | 2 | 80 | `1446936` [藥舐太郎] 鬼滅ヒロインズ對催眠鬼 (鬼滅の刃) [AI Generated] RATKING機翻]<br>`1446996` [宇宙田協] [甘泉少女 (のとくるみ)] 初戀の母さんにデカチン童貞を捧げて僕の赤ちゃんを孕んでもらうまでの話 [中國翻譯] [DL版] |
| doujin / 同人 | 周榜 | `week_ranking` | `mv_w` | 成功 | 216 | 3 | 80 | `1446782` [隻因你AI] 在超市後門抽肉菸的女人<br>`1446859` [千字笙] tsf漫展一日記 [AI Generated] |
| doujin / 同人 | 月榜 | `month_ranking` | `mv_m` | 成功 | 1403 | 18 | 80 | `1445682` [きつねのおんがえし (スズガミ)] サキュバス酒場 ユメカナウ Episode of LUMI [中國翻譯] [DL版]<br>`1444110` [いわお] 六花ちゃん (SSSS.GRIDMAN) [中國翻譯][星屑飛塵個人漢化] |
| hanman / 韩漫 | 日榜 | `day_ranking` | `mv_t` | 成功 | 0 | 0 | 0 |  |
| hanman / 韩漫 | 周榜 | `week_ranking` | `mv_w` | 成功 | 0 | 0 | 0 |  |
| hanman / 韩漫 | 月榜 | `month_ranking` | `mv_m` | 成功 | 15 | 1 | 15 | `1444530` 陽菜阿姨[虎哥個人漢化][Elijahzx (Bobtheneet)]Aunt hina<br>`1444613` 我的偷渡日記 |
| hanmansfw / 一般向韩漫 | 日榜 | `day_ranking` | `mv_t` | 成功 | 0 | 0 | 0 |  |
| hanmansfw / 一般向韩漫 | 周榜 | `week_ranking` | `mv_w` | 成功 | 0 | 0 | 0 |  |
| hanmansfw / 一般向韩漫 | 月榜 | `month_ranking` | `mv_m` | 成功 | 0 | 0 | 0 |  |
| meiman / 英文漫画 / 美漫 | 日榜 | `day_ranking` | `mv_t` | 成功 | 0 | 0 | 0 |  |
| meiman / 英文漫画 / 美漫 | 周榜 | `week_ranking` | `mv_w` | 成功 | 0 | 0 | 0 |  |
| meiman / 英文漫画 / 美漫 | 月榜 | `month_ranking` | `mv_m` | 成功 | 0 | 0 | 0 |  |
| short / 短篇 | 日榜 | `day_ranking` | `mv_t` | 成功 | 5 | 1 | 5 | `1446944` [おなまえ] お母さん、あのね (COMIC クリベロン DUMA 2026年6月號 Vol.85) [中國翻譯]<br>`1446943` [海老名えび] 女性化すると1000倍強くなるスキルを手に入れた! 變身するたびにときめく女性化†無雙! 冒險の第二章 (COMIC ルクセリア vol.05) [中國翻譯] [DL版] |
| short / 短篇 | 周榜 | `week_ranking` | `mv_w` | 成功 | 9 | 1 | 9 | `1446902` 異世界エルフ發情の魔眼10～パーティ寢取り編～ (オリジナル) [DL版]<br>`1446944` [おなまえ] お母さん、あのね (COMIC クリベロン DUMA 2026年6月號 Vol.85) [中國翻譯] |
| short / 短篇 | 月榜 | `month_ranking` | `mv_m` | 成功 | 68 | 1 | 68 | `1444235` [宇宙田協] [gonza] 彼女の母親 〜新・友達の母親 番外編〜 第19話 [中國翻譯]<br>`1444315` [宇宙田協] [gonza] 彼女の母親 〜新・友達の母親 番外編〜 第20話 [中國翻譯] |
| single / 单本 | 日榜 | `day_ranking` | `mv_t` | 成功 | 5 | 1 | 5 | `1447126` [飛龍亂] 母子相・談<br>`1447125` [吉舎和幸] セクサロイドにAIをこめて 2 |
| single / 单本 | 周榜 | `week_ranking` | `mv_w` | 成功 | 8 | 1 | 8 | `1446778` 童貞勇者與後宮的魔王討伐記 [三ッ葉稔] 童貞勇者のハーレム魔王討伐記<br>`1446844` 人形機器人瑪麗Plus [鵝媽媽漢化組] [あきもと明希] 機械じかけのマリー＋ |
| single / 单本 | 月榜 | `month_ranking` | `mv_m` | 成功 | 123 | 2 | 80 | `1444436` [Amerins漢化] [えこひいき] えろびいき [中國翻譯] [DL版]<br>`1445572` [Amerins補漢] [ワレモノ] 女上 |

## 网页端排行榜探测

### HTML 总榜 日榜

- 状态：失败
- 错误：`ResponseUnexpectedException: 请求失败，响应状态码为403，原因为: [ip地区禁止访问/爬虫被识别], URL=[https://18comic.vip/albums?page=1&o=mv&t=t]`
- 处理：检测到网页端 403/Cloudflare/反爬风险，已停止后续网页端榜单探测。

## 请求与返回记录

### R1: App API 0 日榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=0&o=mv_t`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=0&o=mv_t`
- HTTP 状态：`200`；耗时：`1757.61ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`30789`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=30296>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 167,
  "content": [
    {
      "id": "1446996",
      "author": "のとくるみ",
      "name": "[宇宙田協] [甘泉少女 (のとくるみ)] 初戀の母さんにデカチン童貞を捧げて僕の赤ちゃんを孕んでもらうまでの話 [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781657679
    },
    {
      "id": "1446936",
      "author": "藥舐太郎",
      "name": "[藥舐太郎] 鬼滅ヒロインズ對催眠鬼 (鬼滅の刃) [AI Generated] RATKING機翻]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633213
    },
    {
      "id": "1447036",
      "author": "N/A",
      "name": "我妻柒柒·改 第七章",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781664449
    },
    {
      "id": "1447098",
      "author": "nansha
... <truncated, total_chars=2970>
```

### R2: App API 0 周榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=0&o=mv_w`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=0&o=mv_w`
- HTTP 状态：`200`；耗时：`982.18ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`32018`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=31532>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 245,
  "content": [
    {
      "id": "1446782",
      "author": "隻因你AI",
      "name": "[隻因你AI] 在超市後門抽肉菸的女人",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "3",
        "title": "短篇"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781602871
    },
    {
      "id": "1446859",
      "author": "千字笙",
      "name": "[千字笙] tsf漫展一日記 [AI Generated]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "3",
        "title": "短篇"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633295
    },
    {
      "id": "1446858",
      "author": "ベビーリーフ工房",
      "name": "[村長個人漢化] [ベビーリーフ工房]金髪爆乳秘書のセクハラ業務日志【本編＋おまけ】 [AI Generated] [中國翻譯]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633295
    },
    {
      "id": "1446856",
      "author": "ぷらんぷまん",
      "name
... <truncated, total_chars=3029>
```

### R3: App API 0 月榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=0&o=mv_m`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=0&o=mv_m`
- HTTP 状态：`200`；耗时：`1258.78ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`31045`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=30572>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 1723,
  "content": [
    {
      "id": "1445682",
      "author": "スズガミ",
      "name": "[きつねのおんがえし (スズガミ)] サキュバス酒場 ユメカナウ Episode of LUMI [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781142889
    },
    {
      "id": "1444110",
      "author": "いわお",
      "name": "[いわお] 六花ちゃん (SSSS.GRIDMAN) [中國翻譯][星屑飛塵個人漢化]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780394681
    },
    {
      "id": "1445571",
      "author": "達瓦里希",
      "name": "[達瓦里希] 秘密企劃-出行",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781079136
    },
    {
      "id": "1444357",
      "author": "不愛我就拉倒",
      "na
... <truncated, total_chars=2957>
```

### R4: App API another 日榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=another&o=mv_t`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=another&o=mv_t`
- HTTP 状态：`200`；耗时：`1801.4ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`3202`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=3136>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 10,
  "content": [
    {
      "id": "1447141",
      "author": "Queltza",
      "name": "[Queltza]我們的承諾(Our Promise)01-07",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781681338
    },
    {
      "id": "1447108",
      "author": "Kaba",
      "name": "[Kaba] 卑媚 01",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781676587
    },
    {
      "id": "1447016",
      "author": "N/A",
      "name": "[奶娘]",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781662378
    },
    {
      "id": "1446963",
      "author": "Kerberus",
      "name": "[Kerberus] 新艾利都皮物軼事2",
      "image": "",
      "catego
... <truncated, total_chars=2830>
```

### R5: App API another 周榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=another&o=mv_w`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=another&o=mv_w`
- HTTP 状态：`200`；耗时：`843.78ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`3893`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=3820>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 12,
  "content": [
    {
      "id": "1446863",
      "author": "射絲小飛俠",
      "name": "[] 截癱師母性冷妻 01-07",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633295
    },
    {
      "id": "1446871",
      "author": "zzzz",
      "name": "[zzzz] 不死癡女 玲玉 00-01",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633295
    },
    {
      "id": "1447141",
      "author": "Queltza",
      "name": "[Queltza]我們的承諾(Our Promise)01-07",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781681338
    },
    {
      "id": "1447108",
      "author": "Kaba",
      "name": "[Kaba] 卑媚 01",
      "image": "",

... <truncated, total_chars=2850>
```

### R6: App API another 月榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=another&o=mv_m`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=another&o=mv_m`
- HTTP 状态：`200`；耗时：`975.69ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`25797`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=25408>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 114,
  "content": [
    {
      "id": "1444357",
      "author": "不愛我就拉倒",
      "name": "[不愛我就拉倒] [女友小葉] 第一章 (1-2)",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780556824
    },
    {
      "id": "1444545",
      "author": "3D",
      "name": "[3D]冊母為後01-04",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780632457
    },
    {
      "id": "1444598",
      "author": "N/A",
      "name": "小九的絕區零曆險記",
      "image": "",
      "category": {
        "id": "4",
        "title": "其他類"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780649147
    },
    {
      "id": "1444220",
      "author": "N/A",
      "name": "臣服於巨根的舞蹈老師母親01-2.1",
      "image": "",
      "category": {

... <truncated, total_chars=2826>
```

### R7: App API doujin 日榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=doujin&o=mv_t`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=doujin&o=mv_t`
- HTTP 状态：`200`；耗时：`885.94ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`31216`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=30720>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 147,
  "content": [
    {
      "id": "1446936",
      "author": "藥舐太郎",
      "name": "[藥舐太郎] 鬼滅ヒロインズ對催眠鬼 (鬼滅の刃) [AI Generated] RATKING機翻]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633213
    },
    {
      "id": "1446996",
      "author": "のとくるみ",
      "name": "[宇宙田協] [甘泉少女 (のとくるみ)] 初戀の母さんにデカチン童貞を捧げて僕の赤ちゃんを孕んでもらうまでの話 [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781657679
    },
    {
      "id": "1446952",
      "author": "下っ端",
      "name": "[Amerins漢化] [下っ端] クダンの劍 (ANGEL 俱樂部 2026年7月號) [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633213
    },
    {
... <truncated, total_chars=2985>
```

### R8: App API doujin 周榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=doujin&o=mv_w`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=doujin&o=mv_w`
- HTTP 状态：`200`；耗时：`882.92ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`31739`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=31212>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 216,
  "content": [
    {
      "id": "1446782",
      "author": "隻因你AI",
      "name": "[隻因你AI] 在超市後門抽肉菸的女人",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "3",
        "title": "短篇"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781602871
    },
    {
      "id": "1446859",
      "author": "千字笙",
      "name": "[千字笙] tsf漫展一日記 [AI Generated]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "3",
        "title": "短篇"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633295
    },
    {
      "id": "1446858",
      "author": "ベビーリーフ工房",
      "name": "[村長個人漢化] [ベビーリーフ工房]金髪爆乳秘書のセクハラ業務日志【本編＋おまけ】 [AI Generated] [中國翻譯]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633295
    },
    {
      "id": "1446856",
      "author": "ぷらんぷまん",
      "name
... <truncated, total_chars=3006>
```

### R9: App API doujin 月榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=doujin&o=mv_m`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=doujin&o=mv_m`
- HTTP 状态：`200`；耗时：`922.69ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`32630`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=32088>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 1403,
  "content": [
    {
      "id": "1445682",
      "author": "スズガミ",
      "name": "[きつねのおんがえし (スズガミ)] サキュバス酒場 ユメカナウ Episode of LUMI [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781142889
    },
    {
      "id": "1444110",
      "author": "いわお",
      "name": "[いわお] 六花ちゃん (SSSS.GRIDMAN) [中國翻譯][星屑飛塵個人漢化]",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780394681
    },
    {
      "id": "1445571",
      "author": "達瓦里希",
      "name": "[達瓦里希] 秘密企劃-出行",
      "image": "",
      "category": {
        "id": "1",
        "title": "同人"
      },
      "category_sub": {
        "id": "1",
        "title": "同人"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781079136
    },
    {
      "id": "1444244",
      "author": "しゃみどーまいちもんじ",

... <truncated, total_chars=2999>
```

### R10: App API hanman 日榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=hanman&o=mv_t`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=hanman&o=mv_t`
- HTTP 状态：`200`；耗时：`903.54ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`151`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=128>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 0,
  "content": [],
  "tags": [
    "戀愛",
    "章魚大戰吸塵器",
    "糞作"
  ]
}
```

### R11: App API hanman 周榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=hanman&o=mv_w`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=hanman&o=mv_w`
- HTTP 状态：`200`；耗时：`1211.48ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`151`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=128>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 0,
  "content": [],
  "tags": [
    "騎大車",
    "女大生",
    "老少配"
  ]
}
```

### R12: App API hanman 月榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=hanman&o=mv_m`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=hanman&o=mv_m`
- HTTP 状态：`200`；耗时：`837.72ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`4783`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=4696>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 15,
  "content": [
    {
      "id": "1444530",
      "author": "Bobtheneet",
      "name": "陽菜阿姨[虎哥個人漢化][Elijahzx (Bobtheneet)]Aunt hina",
      "image": "",
      "category": {
        "id": "5",
        "title": "韓漫"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780629655
    },
    {
      "id": "1444613",
      "author": "IO",
      "name": "我的偷渡日記",
      "image": "",
      "category": {
        "id": "5",
        "title": "韓漫"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781277769
    },
    {
      "id": "1444633",
      "author": "elijahzx",
      "name": "【李風漢化】pray for sex",
      "image": "",
      "category": {
        "id": "5",
        "title": "韓漫"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780708632
    },
    {
      "id": "1445454",
      "author": "ob&犬子",
      "name": "她們的最愛.ZIP",
      "image": "",

... <truncated, total_chars=2856>
```

### R13: App API hanmansfw 日榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=hanmansfw&o=mv_t`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=hanmansfw&o=mv_t`
- HTTP 状态：`200`；耗时：`1745.47ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`177`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=152>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 0,
  "content": [],
  "tags": [
    "達豐拜託你彆來搞事",
    "亂倫",
    "姐姐"
  ]
}
```

### R14: App API hanmansfw 周榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=hanmansfw&o=mv_w`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=hanmansfw&o=mv_w`
- HTTP 状态：`200`；耗时：`1029.32ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`150`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=128>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 0,
  "content": [],
  "tags": [
    "純愛",
    "近親",
    "人形泰迪"
  ]
}
```

### R15: App API hanmansfw 月榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=hanmansfw&o=mv_m`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=hanmansfw&o=mv_m`
- HTTP 状态：`200`；耗时：`1593.88ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`196`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=172>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 0,
  "content": [],
  "tags": [
    "魚與熊掌一定要兼得",
    "NTR",
    "冇有ntr，放心食用"
  ]
}
```

### R16: App API meiman 日榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=meiman&o=mv_t`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=meiman&o=mv_t`
- HTTP 状态：`200`；耗时：`1230.96ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`150`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=128>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 0,
  "content": [],
  "tags": [
    "名作之璧",
    "動畫化",
    "吸奶"
  ]
}
```

### R17: App API meiman 周榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=meiman&o=mv_w`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=meiman&o=mv_w`
- HTTP 状态：`200`；耗时：`1177.06ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`130`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=108>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 0,
  "content": [],
  "tags": [
    "魅魔",
    "群像劇",
    "111"
  ]
}
```

### R18: App API meiman 月榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=meiman&o=mv_m`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=meiman&o=mv_m`
- HTTP 状态：`200`；耗时：`1238.68ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`153`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=128>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 0,
  "content": [],
  "tags": [
    "美庭組長yyds",
    "豐滿",
    "懷孕"
  ]
}
```

### R19: App API short 日榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=short&o=mv_t`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=short&o=mv_t`
- HTTP 状态：`200`；耗时：`808.5ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`2683`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=2624>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 5,
  "content": [
    {
      "id": "1446944",
      "author": "おなまえ",
      "name": "[おなまえ] お母さん、あのね (COMIC クリベロン DUMA 2026年6月號 Vol.85) [中國翻譯]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633213
    },
    {
      "id": "1446943",
      "author": "海老名えび",
      "name": "[海老名えび] 女性化すると1000倍強くなるスキルを手に入れた! 變身するたびにときめく女性化†無雙! 冒險の第二章 (COMIC ルクセリア vol.05) [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633213
    },
    {
      "id": "1446945",
      "author": "青年ホルモン",
      "name": "[青年ホルモン] 敏腕上司と絡み酒 (COMIC ルクセリア vol.05) [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "u
... <truncated, total_chars=2112>
```

### R20: App API short 周榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=short&o=mv_w`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=short&o=mv_w`
- HTTP 状态：`200`；耗时：`1451.36ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`4108`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=4032>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 9,
  "content": [
    {
      "id": "1446902",
      "author": "あやかわりく",
      "name": "異世界エルフ發情の魔眼10～パーティ寢取り編～ (オリジナル) [DL版]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781628096
    },
    {
      "id": "1446944",
      "author": "おなまえ",
      "name": "[おなまえ] お母さん、あのね (COMIC クリベロン DUMA 2026年6月號 Vol.85) [中國翻譯]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633213
    },
    {
      "id": "1446943",
      "author": "海老名えび",
      "name": "[海老名えび] 女性化すると1000倍強くなるスキルを手に入れた! 變身するたびにときめく女性化†無雙! 冒險の第二章 (COMIC ルクセリア vol.05) [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 178
... <truncated, total_chars=3161>
```

### R21: App API short 月榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=short&o=mv_m`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=short&o=mv_m`
- HTTP 状态：`200`；耗时：`899.91ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`28587`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=28160>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 68,
  "content": [
    {
      "id": "1444235",
      "author": "gonza",
      "name": "[宇宙田協] [gonza] 彼女の母親 〜新・友達の母親 番外編〜 第19話 [中國翻譯]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780536868
    },
    {
      "id": "1444315",
      "author": "gonza",
      "name": "[宇宙田協] [gonza] 彼女の母親 〜新・友達の母親 番外編〜 第20話 [中國翻譯]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780537042
    },
    {
      "id": "1444121",
      "author": "霧島鮎",
      "name": "[霧島鮎] 今から息子の友達とセックスします (COMIC 真激 2026年6月號) [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "3",
        "title": "短篇"
      },
      "category_sub": {
        "id": "7",
        "title": "一般向韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780394681
    },
    {
      "id": "1446754
... <truncated, total_chars=3089>
```

### R22: App API single 日榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=single&o=mv_t`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=single&o=mv_t`
- HTTP 状态：`200`；耗时：`1011.91ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`1924`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=1880>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 5,
  "content": [
    {
      "id": "1447126",
      "author": "飛龍亂",
      "name": "[飛龍亂] 母子相・談",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": "5",
        "title": "韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781680711
    },
    {
      "id": "1447125",
      "author": "吉舎和幸",
      "name": "[吉舎和幸] セクサロイドにAIをこめて 2",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": "5",
        "title": "韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781680711
    },
    {
      "id": "1447096",
      "author": "吾瀨わぎもこ",
      "name": "[吾瀨わぎもこ] 真夏のユリイカ︱盛夏的心動發現 [Chinese][全1卷]",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": "5",
        "title": "韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781676587
    },
    {
      "id": "1447148",
      "author": "小牧まりあ",
      "name": "狼戀上月 [鵝媽媽漢化組] [小牧まりあ] オオカミは月に戀をする",

... <truncated, total_chars=1852>
```

### R23: App API single 周榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=single&o=mv_w`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=single&o=mv_w`
- HTTP 状态：`200`；耗时：`853.27ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`3116`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=3052>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 8,
  "content": [
    {
      "id": "1446778",
      "author": "三ッ葉稔",
      "name": "童貞勇者與後宮的魔王討伐記 [三ッ葉稔] 童貞勇者のハーレム魔王討伐記",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781633295
    },
    {
      "id": "1446844",
      "author": "あきもと明希",
      "name": "人形機器人瑪麗Plus [鵝媽媽漢化組] [あきもと明希] 機械じかけのマリー＋",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": null,
        "title": null
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781590583
    },
    {
      "id": "1447126",
      "author": "飛龍亂",
      "name": "[飛龍亂] 母子相・談",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": "5",
        "title": "韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781680711
    },
    {
      "id": "1447125",
      "author": "吉舎和幸",
      "name": "[吉舎和幸] セクサロイドにAIをこめて 2",

... <truncated, total_chars=2928>
```

### R24: App API single 月榜

- Client：`api`
- Method：`GET`
- 输入路径/URL：`/categories/filter?page=1&order=&c=single&o=mv_m`
- 最终 URL：`https://www.cdnhjk.net/categories/filter?page=1&order=&c=single&o=mv_m`
- HTTP 状态：`200`；耗时：`1942.58ms`；内容类型：`application/json; charset=utf-8;`；响应字节：`32722`
- 外层 JSON 摘要：
```json
{
  "code": 200,
  "data": "<encrypted/base64 string, chars=32256>"
}
```
- 解密/解析后返回摘要：
```json
{
  "search_query": "",
  "total": 123,
  "content": [
    {
      "id": "1444436",
      "author": "えこひいき",
      "name": "[Amerins漢化] [えこひいき] えろびいき [中國翻譯] [DL版]",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": "5",
        "title": "韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780588413
    },
    {
      "id": "1445572",
      "author": "ワレモノ",
      "name": "[Amerins補漢] [ワレモノ] 女上",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": "5",
        "title": "韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1781079136
    },
    {
      "id": "1444940",
      "author": "砂濱のさめ",
      "name": "[Amerins補漢] [砂濱のさめ] 年上の黒ギャル同級生",
      "image": "",
      "category": {
        "id": "2",
        "title": "單本"
      },
      "category_sub": {
        "id": "5",
        "title": "韓漫"
      },
      "liked": false,
      "is_favorite": false,
      "update_at": 1780818696
    },
    {
      "id": "1444921",
      "author": "作者 江田島電氣 エロッチ",
      "name": "[超勇漢化組X禁漫天堂]WE
... <truncated, total_chars=2941>
```

### R25: HTML 总榜 日榜

- Client：`html`
- Method：`GET`
- 输入路径/URL：`/albums?page=1&o=mv&t=t`
- 最终 URL：`https://18comic.vip/albums?page=1&o=mv&t=t`
- HTTP 状态：`403`；耗时：`1101.01ms`；内容类型：`text/html; charset=UTF-8`；响应字节：`6174`
- 响应文本样本：
```text
<!DOCTYPE html><html lang="en-US"><head><title>Just a moment...</title><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><meta http-equiv="X-UA-Compatible" content="IE=Edge"><meta name="robots" content="noindex,nofollow"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="content-security-policy" content="default-src &#39;none&#39;; script-src &#39;nonce-HcWPgSgLXwZfZrt8Um4DEh&#39; &#39;unsafe-eval&#39; https://challenges.cloudflare.com; script-src-attr &#39;none&#39;; style-src &#39;unsafe-inline&#39;; img-src &#39;self&#39; https://challenges.cloudflare.com; connect-src &#39;self&#39; https://challenges.cloudflare.com; frame-src &#39;self&#
... <truncated, total_chars=734>
```

## 结论

- App API 共尝试 `24` 个榜单组合，成功 `24` 个。
- 可用排行榜接口为日榜、周榜、月榜，底层都是 `/categories/filter`，通过 `o=mv_t/mv_w/mv_m` 区分。
- 父分类参数可与排行榜组合使用；本次覆盖了 `0`、`another`、`doujin`、`hanman`、`hanmansfw`、`meiman`、`short`、`single`。
- 网页端也能由 `JmHtmlClient.categories_filter()` 构造 `/albums?...&o=mv&t=t/w/m`，但当前环境下网页端被 403/Cloudflare 拦截。
