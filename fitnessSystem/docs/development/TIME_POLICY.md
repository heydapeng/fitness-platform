# 时间与审计约定

- `createdAt`、`updatedAt` 使用 `Instant`，表示不带本地时区歧义的 UTC 时间点。
- JPA Auditing 通过 `utcDateTimeProvider` 自动赋值；业务 Service 不应手工维护这两个字段。
- MySQL 的 `DATETIME(3)` 存储 UTC 值；Hibernate JDBC 时区固定为 UTC。
- API 序列化使用 ISO-8601 带 `Z` 或偏移的时间字符串。用户时区只用于计算业务日期和“今天”，不改变审计时间点。
