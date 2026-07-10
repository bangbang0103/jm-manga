# JMComic 读评论接口探测报告

- **探测目标**：漫画 `1215913` 的评论接口 `/forum`
- **参考实现**：`jmcomic-qt/src/server/req.py::GetCommentReq2`、`jmcomic-qt/src/tools/tool.py::ParseBookComment`
- **探测时间**：2026-07-08T21:18:20+08:00
- **运行环境**：`jmcomic==2.7.0`，Python 3.14.6，server/.venv
- **请求策略**：串行请求，每次间隔 4.0 秒；分别测试 `mode=manhua/all/chat` 的第 1、2 页
- **运行命令**：
  ```bash
  cd /Users/bbangqian/git/my-jmcomic
  server/.venv/bin/python docs/research/probe_comments.py
  ```

## 接口定义

| 项目 | 内容 |
| --- | --- |
| Method | `GET` |
| Path | `/forum` |
| 关键参数 | `mode=manhua` / `all` / `chat`，`aid=1215913`，`page=1` |
| 响应外层 | `{"code": 200, "data": "<encrypted/base64 string>"}` |
| 解密后结构 | `{"total": "2130", "list": [...]}` |

## 探测结果

| mode | page | HTTP | code | total | count | 备注 |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `manhua` | 1 | 200 | 200 | 2130 | 10 | 正常返回评论列表 |
| `manhua` | 2 | 200 | 200 | 2130 | 10 | 翻到第 2 页，CID 与第 1 页不重复 |
| `all` | 1 | 200 | 200 | 2130 | 10 | 与 `manhua` 返回内容一致 |
| `all` | 2 | 200 | 200 | 2130 | 10 | 与 `manhua` 返回内容一致 |
| `chat` | 1 | 200 | 200 | 0 | 0 | 该漫画下无 chat 类型评论 |
| `chat` | 2 | 200 | 200 | 0 | 0 | 同上 |

说明：
- `total` 是字符串，不是数字。
- 每页固定返回 10 条（与排行榜接口的 80 条不同）。
- 在指定 `aid` 的情况下，`mode=manhua` 与 `mode=all` 返回结果完全相同，`chat` 为空。

## 字段映射

实际返回的单条评论字段：

| 字段 | 类型 | 说明 | 与 `jmcomic-qt` 对应 |
| --- | --- | --- | --- |
| `CID` | string | 评论 ID | `id` |
| `UID` | string | 用户 ID | `uid` |
| `username` | string | 用户名 | `name` |
| `nickname` | string | 昵称（与 username 通常相同） | — |
| `expinfo.level` | int | 用户等级 | `level` |
| `expinfo.level_name` | string | 等级称号 | `title` |
| `content` | string (HTML) | 评论正文，外层包在 `<div>` 中 | `content` |
| `likes` | string | 点赞数 | `like` |
| `addtime` | string | 发布时间，如 `Jul 08, 2026` | `date` |
| `photo` | string | 头像文件名，`nopic-Male.gif` 表示默认头像 | 需拼 `/media/users/{photo}` |
| `spoiler` | string | 是否有剧透？如 `"1"` | — |
| `gender` | string | 性别 | — |
| `update_at` | string | 时间戳字符串，多为 `"0"` | — |
| `AID` | string | 所属漫画 ID | `linkBookId` |
| `BID` | string/null | 预留字段，当前为 null | — |
| `parent_CID` | string | 父评论 ID，`"0"` 表示顶层评论 | — |
| `replys` | list | 子评论数组（仅顶层评论可能有） | `subComments` |

子评论字段与顶层评论基本一致，但 `parent_CID` 指向被回复评论的 `CID`。

## 与 `jmcomic-qt` 的差异

1. **评论层级结构**
   - `jmcomic-qt` 的 `ParseBookComment` 期望顶层评论带有 `replys` 嵌套数组。
   - 当前 `/forum` 接口确实会在顶层评论下挂 `replys`，但**不是每条都有**；没有子评论时该字段直接缺失。
   - 子评论里用 `parent_CID` 标记父评论，说明服务端返回的是“嵌套 + 扁平”混合结构。

2. **`name` 字段含义**
   - `jmcomic-qt` 用 `name` 作为“跳转漫画名”。
   - 当前接口在指定 `aid` 时，`name` 固定为 `"JM1215913"`，没有实际标题含义；漫画标题应另从 `/album` 获取。

3. **字段类型**
   - `total` / `likes` / `level` 等在 `jmcomic-qt` 部分按 int 处理，实际接口返回为字符串，解析时需兼容。

4. **`chat` mode**
   - 对单部漫画来说 `chat` 返回为空，目前看不出用途。如后续要做“全部评论”可再探测不带 `aid` 的情况。

## 结论

- **接口可用**：`/forum?mode=manhua&aid=1215913&page={page}` 能稳定返回评论数据。
- **字段基本对齐**：`jmcomic-qt` 的 `CommentInfo` 映射大部分可以直接复用，只需注意 `replys` 可能缺失、`name` 不要当标题用、以及数值字段是字符串。
- **Flutter 端实现建议**：
  - Dart 模型：`Comment` 包含 `id`, `uid`, `username`, `level`, `levelName`, `content`, `likes`, `addTime`, `photo`, `replyCount`, `replies`。
  - 头像 URL：非默认头像时拼 `/media/users/{photo}`，复用现有 `JmDecodedImageProvider`。
  - 正文：`content` 是 HTML，可用 `flutter_html` 或简单 strip 标签后纯文本展示。
  - 分页：每页 10 条，按 `total` 计算总页数。
  - 暂不需要探测“我的评论”接口。
