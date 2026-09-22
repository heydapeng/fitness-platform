# 健迹 FitTrace

**中文全称：健迹 Fitness Platform**
**AI 助手：小迹 / Tracey**
**品牌口号：吃练有数，进步有迹**

> 当前阶段目标：任何开发者按照本 README，可以在干净环境中完成项目的构建、测试和启动。
> M0 阶段只建立工程基线，不新增业务功能。

------

## 1. 技术栈

### 后端

- Java 21
- Spring Boot 3.x
- Maven Wrapper
- MySQL 8
- Redis 7+
- Flyway

### 前端

- Node.js
- npm
- TypeScript
- Vite
- Vitest

### 本地基础设施

- Docker
- Docker Compose

------

## 2. 前置要求

开始前请确认本机已安装以下工具：

| 工具           | 要求                           | 检查命令                 |
| -------------- | ------------------------------ | ------------------------ |
| JDK            | Java 21                        | `java -version`          |
| Git            | 近期版本                       | `git --version`          |
| Docker         | 支持 Docker Compose v2         | `docker --version`       |
| Docker Compose | v2                             | `docker compose version` |
| Node.js        | 以项目 `package.json` 要求为准 | `node --version`         |
| npm            | 与 Node.js 配套版本            | `npm --version`          |

后端**不要求全局安装 Maven**。

项目使用 Maven Wrapper：

- Linux / macOS：`./mvnw`
- Windows PowerShell：`.\mvnw.cmd`

MySQL 和 Redis 后续由 Docker Compose 提供，本机无需单独安装。

------

## 3. 克隆项目

```bash
git clone https://github.com/heydapeng/fitness-platform.git
cd fitness-platform
```

------

## 4. 后端环境

后端目录：

```text
fitnessSystem/
```

进入后端目录：

### Linux / macOS

```bash
cd fitnessSystem
```

### Windows PowerShell

```powershell
Set-Location .\fitnessSystem
```

------

## 5. Java 与 Maven Wrapper

### 5.1 检查 Java

```bash
java -version
```

要求使用 Java 21。

示例：

```text
java version "21.x.x"
```

或者：

```text
openjdk version "21.x.x"
```

### 5.2 检查 Maven Wrapper

Linux / macOS：

```bash
./mvnw --version
```

Windows PowerShell：

```powershell
.\mvnw.cmd --version
```

当前工程基线使用：

```text
Apache Maven 3.9.16
Java 21
```

Maven Wrapper 会自动下载项目指定的 Maven 版本，因此无需在开发机上单独安装 Maven。

Maven 下载内容位于开发者自己的 Maven 本地仓库，例如：

```text
C:\Users\<username>\.m2
```

或：

```text
~/.m2
```

`.m2` 不属于项目文件，不应提交到 Git。

------

## 6. 后端构建

进入：

```text
fitnessSystem/
```

Linux / macOS：

```bash
./mvnw clean verify
```

Windows PowerShell：

```powershell
.\mvnw.cmd clean verify
```

如果只需要编译打包：

Linux / macOS：

```bash
./mvnw package
```

Windows PowerShell：

```powershell
.\mvnw.cmd package
```

------

## 7. 后端测试

Linux / macOS：

```bash
./mvnw test
```

Windows PowerShell：

```powershell
.\mvnw.cmd test
```

当前 Maven Wrapper、Java 21 和 Maven 测试生命周期已经可以正常执行。

> 注意：当前工程仍需要在 T0.5 中补齐独立测试配置和实际可重复运行的测试。
> M0 最终验收不能以 `Tests run: 0` 作为完整测试基线。

------

## 8. 启动后端

进入：

```text
fitnessSystem/
```

Linux / macOS：

```bash
./mvnw spring-boot:run
```

Windows PowerShell：

```powershell
.\mvnw.cmd spring-boot:run
```

或者先构建：

```bash
./mvnw package
```

Windows：

```powershell
.\mvnw.cmd package
```

再运行生成的 JAR。

具体产物名称以 `target/` 中实际生成的文件为准。

------

## 9. 环境变量

敏感配置不得直接写入 Git。

当前后端配置通过环境变量读取敏感值，例如：

```text
DB_PASSWORD
JWT_SECRET
```

禁止在 Git 中提交：

- 真实数据库密码
- JWT Secret
- API Key
- `.env`
- 本地私有配置
- 生产环境凭据

示例配置只能使用占位值，例如：

```text
DB_PASSWORD=<db-password>
JWT_SECRET=<至少 32 字节随机字符串>
LLM_API_KEY=<your-api-key>
```

### Windows PowerShell 示例

临时设置环境变量：

```powershell
$env:DB_PASSWORD = "your-local-password"
$env:JWT_SECRET = "your-local-secret"
```

这些变量仅对当前 PowerShell 会话生效。

### Linux / macOS 示例

```bash
export DB_PASSWORD="your-local-password"
export JWT_SECRET="your-local-secret"
```

------

## 10. 本地 MySQL 与 Redis

M0 的 T0.4 将使用 Docker Compose 提供：

- MySQL 8
- Redis
- 本地持久化 volume
- 环境变量配置
- 健康检查

完成 T0.4 后，标准启动命令应为：

```bash
docker compose up -d
```

查看状态：

```bash
docker compose ps
```

停止容器：

```bash
docker compose down
```

删除容器以及本地数据卷：

```bash
docker compose down -v
```

> `docker compose down -v` 会删除本地 MySQL 和 Redis 数据，只应在需要完全重置本地环境时使用。

------

## 11. Flyway 数据库迁移

项目使用 Flyway 管理数据库结构。

后端迁移目录：

```text
fitnessSystem/src/main/resources/db/migration/
```

迁移文件采用：

```text
V<version>__<description>.sql
```

例如：

```text
V1_0_0__create_app_user.sql
V1_0_1__create_food_catalog.sql
V3_5_0__add_training_analytics_indexes.sql
```

规则：

- 不修改已经正式执行过的历史 migration；
- 数据库结构变更通过新增 migration 完成；
- 空数据库启动时 Flyway 应自动建表；
- 应用重复启动时不得重复执行已经成功的 migration；
- migration 执行记录由 Flyway schema history 管理。

T0.4 完成后，需要验证：

1. 删除本地数据库 volume；
2. 启动新的 MySQL；
3. 启动后端；
4. Flyway 自动建立全部表；
5. 再次启动后端；
6. 已执行 migration 不重复执行。

------

## 12. 前端构建

前端工程将在 T0.3 中完成构建基线修复。

T0.3 需要保证：

```bash
npm ci
npm run type-check
npm test
npm run build
```

全部通过。

当前已知问题：

```text
tsconfig.vitest.json
```

缺失导致 TypeScript 配置引用失败。

该问题应通过恢复正确的 Vitest TypeScript 配置解决，不能通过删除测试配置引用绕过。

完成 T0.3 后，本节应更新为项目实际的前端目录和最终可执行命令。

------

## 13. 测试隔离

T0.5 将建立独立测试配置。

测试不得依赖开发者本机已有的：

```text
fitness
```

数据库。

计划使用隔离的测试环境，使测试满足：

- 可重复运行；
- 不污染开发数据库；
- 不依赖开发者本机历史数据；
- CI 中可以运行；
- Flyway migration 可以在空测试数据库上验证。

测试环境最终将根据项目实际情况选择 Testcontainers 或独立测试数据库，并在本节记录选择原因。

------

## 14. CI

T0.6 将建立持续集成基线。

每次提交或 Pull Request 至少执行：

### 后端

```text
Java 21
Maven Wrapper
Backend tests
```

### 前端

```text
npm ci
npm run type-check
npm test
npm run build
```

CI 必须满足：

- 正常提交可以正确通过；
- 故意破坏测试后 CI 可以正确失败；
- 缓存不能跳过实际测试或构建；
- 日志不得输出 Secret；
- CI 不依赖开发者本机环境。

------

## 15. `.gitignore`

仓库应忽略至少以下内容：

### IDE

```text
.idea/
.vscode/
*.iml
.project
.classpath
.settings/
```

### 敏感和本地环境

```text
.env
.env.*
application-local.yml
application-secret.yml
```

`.env.example` 可以提交。

### Java / Maven

```text
target/
**/target/
.m2/
*.log
```

注意：

```text
.mvn/
mvnw
mvnw.cmd
```

属于 Maven Wrapper，必须提交到 Git，不能忽略。

### Node

```text
node_modules/
dist/
coverage/
```

### 本地数据库及运行数据

```text
*.db
*.sqlite
*.sqlite3
data/
mysql-data/
redis-data/
```

### 临时文件和导出物

```text
tmp/
temp/
exports/
*.zip
*.tar
*.tar.gz
```

------

## 16. Windows PowerShell 常用命令

进入项目：

```powershell
Set-Location "D:\codes\fitness-platform"
```

进入后端：

```powershell
Set-Location ".\fitnessSystem"
```

检查 Java：

```powershell
java -version
```

检查 Maven Wrapper：

```powershell
.\mvnw.cmd --version
```

运行测试：

```powershell
.\mvnw.cmd test
```

构建：

```powershell
.\mvnw.cmd clean verify
```

启动：

```powershell
.\mvnw.cmd spring-boot:run
```

> PowerShell 不使用 CMD 的 `cd /d` 语法。
> PowerShell 中可以直接使用 `Set-Location "D:\path"` 或 `cd "D:\path"`。

------

## 17. M0 干净环境验收

M0 完成后，需要在新的目录重新 clone 项目进行完整验收。

### 17.1 克隆

```bash
git clone https://github.com/heydapeng/fitness-platform.git
cd fitness-platform
```

### 17.2 检查工具

```bash
java -version
node --version
npm --version
docker --version
docker compose version
```

Java 必须为 21。

### 17.3 启动基础设施

```bash
docker compose up -d
docker compose ps
```

### 17.4 后端

Linux / macOS：

```bash
cd fitnessSystem
./mvnw --version
./mvnw test
./mvnw clean verify
```

Windows PowerShell：

```powershell
Set-Location .\fitnessSystem
.\mvnw.cmd --version
.\mvnw.cmd test
.\mvnw.cmd clean verify
```

### 17.5 前端

完成 T0.3 后，应可以在前端目录执行：

```bash
npm ci
npm run type-check
npm test
npm run build
```

### 17.6 验收标准

全部满足以下条件才算 M0 完成：

- Java 21 正确；
- Maven Wrapper 可以独立工作；
- 不依赖全局 Maven；
- 后端测试通过；
- 前端 type-check 通过；
- 前端测试通过；
- 前端构建通过；
- MySQL 8 可以启动；
- Redis 可以连接；
- 空数据库 Flyway 自动建表；
- 重复启动不会重复建表；
- 测试不依赖开发者本机 `fitness` 数据库；
- CI 可以正确识别成功和失败；
- README 中的命令可以从干净 checkout 直接执行；
- Git 中不存在真实数据库密码、JWT Secret 或其他 Secret。

------

## 18. M0 当前进度

### T0.1 保护现有工作并建立提交基线

进行中。

已完成：

- 已备份现有工作区；
- `.gitignore` 已补充工程基线规则；
- 数据库密码和 JWT Secret 改为通过环境变量读取。

仍需：

- 整理已有修改、目录移动和新增文件；
- 建立语义明确的 Git 提交。

### T0.2 Java 与 Maven 环境

核心验证已完成。

当前已验证：

```text
Java 21.0.7
Apache Maven 3.9.16
Maven Wrapper 3.3.4
```

Windows PowerShell：

```powershell
.\mvnw.cmd --version
.\mvnw.cmd test
```

Maven Wrapper 可以正常运行，不依赖机器全局 Maven。

仍需：

- 将 `mvnw`、`mvnw.cmd`、`.mvn/wrapper/maven-wrapper.properties` 纳入 Git；
- 完成 T0.2 对应提交。

### T0.3 前端构建基线

待处理。

### T0.4 MySQL / Redis 本地基础设施

待处理。

### T0.5 测试配置隔离

待处理。

### T0.6 CI 基线

待处理。

------

## 19. 当前阶段范围

M0 阶段只保证：

- 干净环境可安装；
- 干净环境可构建；
- 干净环境可测试；
- 干净环境可启动；
- 开发环境和 CI 行为可重复。

M0 不新增业务功能。
