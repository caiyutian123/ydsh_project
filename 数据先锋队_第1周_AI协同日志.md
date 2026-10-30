# 数据先锋队 · 第 1 周 AI 协同日志

> 项目：云购生活新零售企业——企业级数据仓库与经营分析可视化系统
> 周期：第 1 周（2026-10-26 ~ 2026-10-30）
> 用途：记录本周使用 AI 工具参与需求拆解、脚本生成、排障与文档整理的全过程，供阶段性答辩与后续复盘使用。

## 一、基本信息

| 项目 | 内容 |
|------|------|
| 团队名称 | 数据先锋队 |
| 团队成员 | caiyutian（一人多岗：项目经理 / 数据工程师 / 数据分析师 / 可视化工程师） |
| 协作周期 | 2026-10-26 ~ 2026-10-30 |
| 协同场景 | 环境搭建排障、Hive SQL 编写、数据质量评估、数据清洗、Git 规范、文档整理 |
| 记录条数 | 9 条（本周必交 ≥ 5 条） |
| 记录人 | caiyutian |

## 二、使用的工具 / 模型

| 类别 | 名称 | 用途 |
|------|------|------|
| AI 编程助手 | Trae IDE（内置 AI Agent） | 任务拆解、脚本生成、排障分析、文档转换 |
| 大模型 | DeepSeek-V4.1-Flash | 自然语言理解、SQL 生成与解释、报错日志分析 |
| 数据库 / 数仓 | Apache Hive 4.0.0（Metastore + HiveServer2）、MySQL 8.0 | 建表、导数、质量扫描、清洗 |
| 容器环境 | Docker Desktop（WSL2 后端）、Docker Compose | 一键编排 mysql + hive-metastore + hive-server |
| 版本管理 | Git 2.53（Conventional Commits） | 提交历史、.gitignore、远程推送 |
| 文档工具 | Markdown / Excel（openpyxl）/ Word（python-docx） | 交付物整理与格式转换 |

## 三、协同记录表

| 序号 | 日期 | 协作任务 | 工具 / 模型 | 输入提示要点 | 模型输出 | 人工修正与校验 | 采纳结果 |
|------|------|----------|-------------|--------------|----------|----------------|----------|
| 1 | 10-26 | 解读第 1 周任务书与数据字典 | Trae AI + DeepSeek-V4.1-Flash | 上传任务书与数据字典，要求拆解 7 个子任务、输出交付物清单与验收标准 | 子任务顺序、6 张表字段与预期行数、五类脏数据分布、评分点对照表 | 人工核对数据字典行数与字段类型；修正"清洗（一）"仅覆盖缺失值与重复值的范围 | 采纳，形成本周任务清单 |
| 2 | 10-26 | Docker / WSL2 环境搭建排障 | Trae AI + DeepSeek-V4.1-Flash | 贴出 Docker Desktop 启动报错与 `wsl --status` 输出，要求给出排查顺序 | 判断为 WSL2 内核未启用，给出 `wsl --install`、`wsl --set-default-version 2` 与重启步骤 | 按建议执行后 Docker 正常启动；人工补充"需管理员权限"的注意事项 | 采纳，写入《环境搭建笔记》问题 7 |
| 3 | 10-27 | Hive Metastore 启动失败定位 | Trae AI + DeepSeek-V4.1-Flash | 贴出 `docker logs hive-metastore` 中 `Communications link failure` 片段 | 定位为 MySQL 未就绪即启动、密码不一致、mysql_native_password 三类原因，给出 compose `depends_on: condition: service_healthy` 方案 | 人工核对 `hive-site.xml` 的 ConnectionPassword 与 compose 保持一致（均为 root） | 采纳，三容器稳定 Up |
| 4 | 10-27 | ODS 建表与导入脚本生成 | Trae AI + DeepSeek-V4.1-Flash | 给出 6 张表字段清单与 CSV 路径，要求生成 `create_ods.sql`、`load_ods.sql` | 6 条 `CREATE TABLE`（含分隔符、`skip.header.line.count=1`）与 6 条 `LOAD DATA LOCAL INPATH` | 人工逐表核对字段类型与顺序；把 `load_ods.sql` 改为容器内绝对路径 | 采纳，`sql/ods/` 两个脚本入库 |
| 5 | 10-27 | 行数校验偏差分析 | Trae AI + DeepSeek-V4.1-Flash | 提供 6 张表 `count(*)` 结果与数据字典预期行数 | 判定每表多 1 行是 CSV 表头未跳过，给出核查 `TBLPROPERTIES` 与过滤表头行的方案 | 人工执行 `select * from ods_user limit 3` 确认首行为表头；在报告中注明偏差原因 | 采纳，行数校验判为通过 |
| 6 | 10-27 | 五维度数据质量扫描 SQL | Trae AI + DeepSeek-V4.1-Flash | 要求按完整性 / 唯一性 / 有效性 / 一致性 / 准确性生成可批量执行的 Hive SQL | `precheck.sql`：空值率、`group by + having`、枚举取值分布、日期与手机号格式、负数与超界值统计 | 人工补充分母口径（含表头行的实际行数）；修正 behavior_type 的合法性判定为"仅中文标准值为合法" | 采纳，输出《数据质量预评估表》 |
| 7 | 10-27 | 缺失值与重复值清洗脚本 | Trae AI + DeepSeek-V4.1-Flash | 要求按预评估结论生成 `clean_missing.sql`、`clean_dedup.sql`，区分整行重复与主键重复内容不同 | 均值填充 age、email 打标 `email_missing_flag`、众数补全 launch_date；`ROW_NUMBER() OVER(PARTITION BY order_id)` 去重 | 人工将均值改为"仅基于有效年龄（0~120）计算"，避免异常值污染均值；去重排序键改为 `order_date desc` | 采纳，`sql/clean/` 两个脚本入库 |
| 8 | 10-28 | Git 规范化提交与 .gitignore | Trae AI + DeepSeek-V4.1-Flash | 要求生成符合 Conventional Commits 的提交说明，并检查忽略规则是否覆盖数据与密钥 | 提交信息模板（feat/fix/docs/chore）、`.gitignore` 规则（`data/*.csv`、`.env`、`*.key`、`*.log`） | 人工追加 `hive-data/` 与 `docs/*.txt` 忽略项，避免把 3.5MB 行为日志与排障临时文件推上远程 | 采纳，提交历史清晰可追溯 |
| 9 | 10-30 | 交付物清单核对与格式补齐 | Trae AI + DeepSeek-V4.1-Flash | 上传《第 1 周作业任务与提交清单》截图，要求逐项核对仓库现状并给出差距 | 输出 7 项对照表：缺 xlsx / docx / AI 协同日志三项，并说明转换方式 | 人工确认转换后内容与此前 SQL 扫描结果一致，抽查 xlsx 空值率与重复率 | 采纳，交付物补齐至 7 项 |

## 四、产出成果清单

| 序号 | 交付物 | 路径 | 类型 | 状态 |
|------|--------|------|------|------|
| 1 | README.md（团队信息、分工、目标、阶段计划） | `README.md` | 文档 | 已完成 |
| 2 | 环境搭建笔记（含 7 个问题的排查与解决） | `docs/环境搭建笔记.md` / `docs/环境搭建笔记.docx` | 文档 | 已完成 |
| 3 | Git 仓库（.gitignore + 规范提交历史） | 仓库根目录 | 代码 | 已完成 |
| 4 | ODS 建表与导入脚本（6 张表） | `sql/ods/create_ods.sql`、`sql/ods/load_ods.sql` | 代码 | 已完成 |
| 5 | 数据质量预评估表（五维度扫描结果） | `docs/数据质量预评估表.xlsx` | 数据 | 已完成 |
| 6 | 缺失值 / 重复值清洗脚本 | `sql/clean/clean_missing.sql`、`sql/clean/clean_dedup.sql` | 代码 | 已完成 |
| 7 | AI 协同日志（本周 9 条记录） | `数据先锋队_第1周_AI协同日志.md` | 日志 | 已完成 |

## 五、问题与解决

| 问题 | 现象 | 定位过程 | 解决方案 | 沉淀 |
|------|------|----------|----------|------|
| Docker 启动失败 | 提示 WSL2 未安装或内核过低 | 查看 `wsl --status` 与系统功能开关 | `wsl --install` + 重启 + 开启 WSL2 引擎 | 环境搭建笔记 问题 7 |
| Hive Metastore 反复重启 | 日志 `Communications link failure` | `docker logs hive-metastore --tail 100` | 加 `depends_on` 健康检查、统一 root 密码、`mysql_native_password` | 环境搭建笔记 问题 1 |
| beeline 连不上 HiveServer2 | `Connection refused` | 查 `docker ps` 与 `hive-server` 日志 | 按 MySQL → Metastore → HiveServer2 顺序启动，等待 30~60 秒 | 环境搭建笔记 问题 3 |
| CSV 行数比预期多 1 | 6 张表 `count(*)` 均 +1 | `select * limit 3` 发现首行为表头 | 核对 `skip.header.line.count`，报告中说明偏差 | 环境搭建笔记 问题 4 |
| 中文字段乱码 | 查询结果中文显示异常 | 检查 JDBC URL 与 CSV 编码 | URL 加 `characterEncoding=UTF-8`，确保 CSV 为 UTF-8 无 BOM | 环境搭建笔记 问题 5 |
| 模型给出的均值填充不合理 | 年龄均值受 -3、200 等异常值影响 | 手工计算有效年龄区间均值对比 | 限定 0~120 有效区间再取均值 | 清洗脚本注释 + 本日志记录 7 |
| 交付物格式不符清单 | 质量表只有 .md，清单要求 .xlsx | 逐项对照提交清单截图 | 转为 9 个 sheet 的 xlsx，笔记导出 docx，补 AI 协同日志 | 本日志记录 9 |

## 六、反思与总结

1. **AI 负责"广度"，人负责"口径"。** 本周 AI 把任务拆解、SQL 骨架、排障方向一次性铺开，节省了大量检索时间；但空值率分母、合法枚举范围、均值有效区间这些"业务口径"必须由人确认，否则数字看起来专业却经不起追问。
2. **提示词质量决定产出质量。** 贴上报错原文、表结构、预期行数后再提问，模型给出的定位步骤可直接执行；只写"环境起不来"得到的建议往往泛泛。后续统一按"现象 + 日志 + 已尝试动作 + 期望结果"四段式提问。
3. **所有 AI 产出都要有可验证的落点。** 本周坚持三条校验：SQL 必在 beeline 实跑、行数必与数据字典对照、文档数字必与扫描结果一致。xlsx 与 docx 转换后也做了抽样核对，避免"格式对了、数据错了"。
4. **排障过程本身是交付物。** 7 个环境问题的现象、日志与解决方案已沉淀进《环境搭建笔记》，下周可直接复用，也符合清单"附关键截图"的要求。
5. **待改进。** 一是提问时曾一次性索要"全部五维度 SQL"，返回内容过长导致重点被稀释，后续按维度分批；二是清洗脚本的排序键一开始未考虑业务含义（应按 `order_date desc` 保留最新订单），由人工修正，说明业务规则需前置写进提示。
6. **下周计划。** 在 DWD/DWS/ADS 建模阶段继续采用"AI 生成骨架 + 人工定口径 + SQL 实跑验证"的协作模式，并把每轮协同记录追加到本日志，保持每周 ≥ 5 条。
