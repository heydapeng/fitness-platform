# 健迹 FitTrace

**中文全称：健迹 Fitness Platform**
**AI 助手：小迹 / Tracey**
**品牌口号：吃练有数，进步有迹**

> 当前阶段目标：任何开发者按照本 README，可以在干净环境中完成项目的构建、测试和启动。
> M0 阶段只建立工程基线，不新增业务功能。

---

## 1. 技术栈

### 后端

- Java 21
- Spring Boot 3.x
- Maven Wrapper
- MySQL 8
- Redis 7
- Flyway
- Testcontainers
- JUnit 5

### 前端

- Node.js 22
- npm
- TypeScript
- Vue
- Vite
- Vitest

### 本地基础设施

- Docker
- Docker Compose

### CI

- GitHub Actions

---

## 2. 前置要求

开始前请确认本机已安装以下工具：

| 工具           | 要求                | 检查命令                 |
| -------------- | ------------------- | ------------------------ |
| JDK            | Java 21             | `java -version`          |
| Git            | 近期版本            | `git --version`          |
| Docker         | 可正常运行容器      | `docker --version`       |
| Docker Compose | Compose v2          | `docker compose version` |
| Node.js        | 22.x                | `node --version`         |
| npm            | 与 Node.js 配套版本 | `npm --version`          |

后端**不要求全局安装 Maven**。

项目使用 Maven Wrapper：

- Linux / macOS：`./mvnw`
- Windows PowerShell：`.\mvnw.cmd`

MySQL 和 Redis 由 Docker Compose 提供，本机无需单独安装。

---

## 3. 克隆项目

```bash
git clone https://github.com/heydapeng/fitness-platform.git
cd fitness-platform
```

如果需要使用当前开发分支：

```bash
git switch dev-v1
```

---

## 4. 项目目录

主要目录：

```text
fitness-platform/
├─ .github/
│  └─ workflows/
│     └─ ci.yml
├─ fitnessSystem/
├─ fitness-frontend/
├─ fitness_platform_db_design/
├─ .env.example
├─ compose.yaml
└─ README.md
```

其中：

```text
fitnessSystem/
```

为 Spring Boot 后端工程。

```text
fitness-frontend/
```

为前端工程。

---

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
cd fitnessSystem
./mvnw --version
```

Windows PowerShell：

```powershell
Set-Location .\fitnessSystem
.\mvnw.cmd --version
```

当前工程基线：

```text
Java 21
Apache Maven 3.9.16
Maven Wrapper 3.3.4
```

Maven Wrapper 会自动下载项目指定的 Maven 版本，因此无需在开发机上单独安装 Maven。

Maven 下载内容位于开发者自己的本地 Maven 仓库，例如：

Windows：

```text
C:\Users\<username>\.m2
```

Linux / macOS：

```text
~/.m2
```

`.m2` 不属于项目文件，不应提交到 Git。

---

## 6. 环境变量

敏感配置不得直接写入 Git。

当前工程通过环境变量读取敏感值，例如：

```text
DB_PASSWORD
JWT_SECRET
```

Docker Compose 还可能使用：

```text
MYSQL_ROOT_PASSWORD
```

禁止在 Git 中提交：

- 真实数据库密码
- JWT Secret
- API Key
- `.env`
- 本地私有配置
- 生产环境凭据

仓库提供：

```text
.env.example
```

作为本地环境变量模板。

可以复制为：

```text
.env
```

然后填写本机使用的值。

### Linux / macOS

```bash
cp .env.example .env
```

### Windows PowerShell

```powershell
Copy-Item .env.example .env
```

示例配置必须使用占位值，例如：

```text
DB_PASSWORD=<db-password>
JWT_SECRET=<至少 32 字节随机字符串>
```

不要把真实密码写回：

```text
.env.example
```

### Windows PowerShell 临时环境变量

```powershell
$env:DB_PASSWORD = "your-local-password"
$env:JWT_SECRET = "your-local-secret"
```

这些变量仅对当前 PowerShell 会话生效。

### Linux / macOS 临时环境变量

```bash
export DB_PASSWORD="your-local-password"
export JWT_SECRET="your-local-secret"
```

---

## 7. 本地 MySQL 与 Redis

项目使用根目录：

```text
compose.yaml
```

提供本地基础设施。

当前包括：

- MySQL 8
- Redis 7
- 持久化 volume
- 健康检查
- 环境变量配置

当前本地端口基线：

```text
MySQL: 3307
Redis: 6380
```

### 7.1 启动

在项目根目录执行：

```bash
docker compose up -d
```

### 7.2 查看状态

```bash
docker compose ps
```

正常情况下 MySQL 和 Redis 应处于：

```text
healthy
```

或正常运行状态。

### 7.3 Redis 连通性验证

可以执行：

```bash
docker compose exec redis redis-cli ping
```

正常返回：

```text
PONG
```

### 7.4 停止容器

```bash
docker compose down
```

该命令停止并删除容器，但保留 volume 中的数据。

### 7.5 完全清理

```bash
docker compose down -v
```

该命令会同时删除 MySQL 和 Redis 的本地数据卷。

> `docker compose down -v` 会删除本地开发数据，只应在需要完全重置数据库或进行空库验收时使用。

---

## 8. 后端配置

后端目录：

```text
fitnessSystem/
```

主要配置文件：

```text
fitnessSystem/src/main/resources/application.yaml
```

数据库密码和 JWT Secret 不直接写死在配置文件中，而是从环境变量读取。

例如：

```yaml
password: ${DB_PASSWORD}
```

以及：

```yaml
secret: ${JWT_SECRET}
```

这样可以避免把真实凭据提交到 Git。

---

## 9. Flyway 数据库迁移

项目使用 Flyway 管理数据库结构。

迁移目录：

```text
fitnessSystem/src/main/resources/db/migration/
```

迁移文件格式：

```text
V<version>__<description>.sql
```

例如：

```text
V1_0_0__create_app_user.sql
V1_0_1__create_food_catalog.sql
V3_5_0__add_training_analytics_indexes.sql
```

当前规则：

- 不修改已经正式执行过的历史 migration；
- 数据库结构变更通过新增 migration 完成；
- 空数据库启动时 Flyway 自动创建数据库结构；
- 应用重复启动时不重复执行已经成功的 migration；
- migration 执行记录由 Flyway schema history 管理。

本项目部分 migration 包含 trigger。

因此 MySQL 使用：

```text
--log-bin-trust-function-creators=1
```

以允许相关 migration 正常执行。

### 9.1 空数据库验证

完全重置本地数据库：

```bash
docker compose down -v
docker compose up -d
```

等待 MySQL 健康后启动后端。

第一次启动时，Flyway 应：

1. 连接空数据库；
2. 创建 Flyway schema history；
3. 按版本顺序执行 migration；
4. 建立当前完整数据库结构。

### 9.2 重复启动验证

再次启动后端时，Flyway 应识别当前数据库版本，并显示类似：

```text
Schema fitness is up to date. No migration necessary.
```

已经成功执行过的 migration 不会重复执行。

---

## 10. 后端测试

后端测试使用 Maven Wrapper。

Linux / macOS：

```bash
cd fitnessSystem
./mvnw test
```

Windows PowerShell：

```powershell
Set-Location .\fitnessSystem
.\mvnw.cmd test
```

当前测试基线使用：

```text
Testcontainers + MySQL 8
```

而不是开发者本机已有的 MySQL 数据库。

测试环境具有以下特性：

- 不依赖本机 `fitness` 数据库；
- 不依赖开发者历史数据；
- 每次测试使用独立 MySQL 8 容器；
- Flyway 在空测试数据库中执行 migration；
- 测试数据库配置动态注入；
- 测试不会污染开发数据库；
- CI 中可以使用相同机制运行。

测试 profile：

```text
fitnessSystem/src/test/resources/application-test.yml
```

Testcontainers 支持代码：

```text
fitnessSystem/src/test/java/com/dapeng/fitnesssystem/support/MySqlContainerTest.java
```

测试 MySQL 使用：

```text
--log-bin-trust-function-creators=1
```

保证包含 trigger 的 Flyway migration 可以执行。

当前后端测试已经验证：

```text
Tests run: 1
Failures: 0
Errors: 0
Skipped: 0
BUILD SUCCESS
```

并且可以连续重复运行。

---

## 11. Windows + WSL 测试说明

Testcontainers 必须能够访问 Docker daemon。

如果 Docker 运行在 Docker Desktop 中，并且 Windows Java 可以访问 Docker daemon，可以直接使用：

```powershell
.\mvnw.cmd test
```

如果 Docker daemon 只运行在 WSL 内部，而 Windows JVM 无法访问该 Docker daemon，则应在 WSL 中运行后端测试。

例如：

```powershell
wsl bash -lc "cd /mnt/d/codes/fitness-platform/fitnessSystem && ./mvnw test"
```

此时需要确保 WSL 中也安装了 Java 21。

检查：

```bash
java -version
```

测试运行环境与 Docker daemon 应能够互相访问。

---

## 12. 后端构建

进入：

```text
fitnessSystem/
```

### Linux / macOS

完整验证：

```bash
./mvnw clean verify
```

只编译打包：

```bash
./mvnw package
```

### Windows PowerShell

完整验证：

```powershell
.\mvnw.cmd clean verify
```

只编译打包：

```powershell
.\mvnw.cmd package
```

构建产物位于：

```text
fitnessSystem/target/
```

具体 JAR 文件名以实际构建结果为准。

---

## 13. 启动后端

启动前应确保：

- MySQL 已启动；
- Redis 已启动；
- 所需环境变量已经设置；
- Java 版本为 21。

进入：

```text
fitnessSystem/
```

### Linux / macOS

```bash
./mvnw spring-boot:run
```

### Windows PowerShell

```powershell
.\mvnw.cmd spring-boot:run
```

也可以先构建：

```bash
./mvnw package
```

然后运行 `target/` 中生成的 JAR。

---

## 14. 前端安装、测试与构建

前端目录：

```text
fitness-frontend/
```

进入目录：

```bash
cd fitness-frontend
```

### 14.1 安装依赖

```bash
npm ci
```

CI 和干净环境均使用：

```text
npm ci
```

而不是依赖开发者已有的 `node_modules`。

### 14.2 TypeScript 类型检查

```bash
npm run type-check
```

实际执行：

```text
vue-tsc --build
```

### 14.3 单元测试

```bash
npm run test:unit -- --run
```

当前测试框架：

```text
Vitest
```

`--run` 用于单次执行测试并退出，适用于 CI。

当前测试基线已经验证：

```text
Test Files  1 passed
Tests       1 passed
```

### 14.4 Production Build

```bash
npm run build
```

当前 `build` script 会执行：

```text
type-check
build-only
```

其中 `build-only` 使用：

```text
vite build
```

### 14.5 当前前端基线

以下命令已经验证全部通过：

```bash
npm ci
npm run type-check
npm run test:unit -- --run
npm run build
```

Vitest TypeScript 配置已经恢复。

测试配置不能通过删除 Vitest TypeScript 引用的方式绕过。

---

## 15. 测试隔离设计

M0 使用：

```text
Testcontainers + MySQL 8
```

作为后端数据库测试隔离方案。

选择 Testcontainers 的原因：

- 与开发和目标运行环境使用相同的 MySQL 8 数据库引擎；
- 不依赖开发者本机已有数据库；
- 可以从空数据库验证 Flyway；
- 测试环境自动创建；
- 测试结束后可以自动清理；
- 多次运行结果可重复；
- GitHub Actions 可以直接运行；
- 避免 H2 与 MySQL SQL 行为差异。

测试不得依赖开发者本机已有的：

```text
fitness
```

数据库。

Testcontainers 会动态提供：

```text
spring.datasource.url
spring.datasource.username
spring.datasource.password
spring.datasource.driver-class-name
```

因此测试配置中不需要保存真实数据库密码。

---

## 16. CI

项目使用 GitHub Actions。

Workflow 文件：

```text
.github/workflows/ci.yml
```

触发条件：

```text
push
pull_request
workflow_dispatch
```

因此代码提交或 Pull Request 会自动运行 CI。

`workflow_dispatch` 提供可选的 `failure_probe` 开关。手动运行并启用该开关时，
工作流会执行一个明确标记的故意失败任务，用于验证 GitHub Actions 能正确识别失败；
普通 push、Pull Request 和未启用该开关的手动运行不受影响。

### 16.1 后端 CI

运行环境：

```text
ubuntu-latest
```

Java：

```text
Java 21
```

后端命令：

```bash
./mvnw --batch-mode --no-transfer-progress test
```

GitHub Runner 提供 Docker 环境。

后端测试通过 Testcontainers 自动启动 MySQL 8，不依赖 CI 中预先配置的开发数据库。

### 16.2 前端 CI

运行环境：

```text
ubuntu-latest
```

Node：

```text
Node.js 22
```

执行：

```bash
npm ci
npm run type-check
npm run test:unit -- --run
npm run build
```

### 16.3 CI 缓存

CI 使用：

- Maven dependency cache
- npm dependency cache

缓存只用于依赖。

缓存不得：

- 跳过后端测试；
- 跳过前端测试；
- 跳过 type-check；
- 跳过 production build。

### 16.4 CI Secret 要求

CI 不需要提交真实：

```text
DB_PASSWORD
JWT_SECRET
MYSQL_ROOT_PASSWORD
```

测试数据库由 Testcontainers 提供。

CI 日志不得主动执行：

```bash
cat .env
env
printenv
```

等可能暴露凭据的命令。

### 16.5 CI 验收

CI 基线需要满足：

- 正常提交可以成功；
- 故意制造失败时 CI 可以正确失败；
- 缓存不会掩盖失败；
- CI 不依赖开发者本机环境；
- 日志不存在真实 Secret。

---

## 17. `.gitignore`

仓库应忽略以下内容。

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

但是：

```text
.env.example
```

允许提交。

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

---

## 18. Windows PowerShell 常用命令

进入项目：

```powershell
Set-Location "D:\codes\fitness-platform"
```

检查 Git：

```powershell
git status
```

检查 Java：

```powershell
java -version
```

进入后端：

```powershell
Set-Location ".\fitnessSystem"
```

检查 Maven Wrapper：

```powershell
.\mvnw.cmd --version
```

运行后端测试：

```powershell
.\mvnw.cmd test
```

如果 Docker 只运行在 WSL：

```powershell
wsl bash -lc "cd /mnt/d/codes/fitness-platform/fitnessSystem && ./mvnw test"
```

构建后端：

```powershell
.\mvnw.cmd clean verify
```

启动后端：

```powershell
.\mvnw.cmd spring-boot:run
```

进入前端：

```powershell
Set-Location "D:\codes\fitness-platform\fitness-frontend"
```

安装前端依赖：

```powershell
npm ci
```

类型检查：

```powershell
npm run type-check
```

运行单元测试：

```powershell
npm run test:unit -- --run
```

构建：

```powershell
npm run build
```

回到项目根目录：

```powershell
Set-Location "D:\codes\fitness-platform"
```

启动基础设施：

```powershell
docker compose up -d
```

查看状态：

```powershell
docker compose ps
```

停止：

```powershell
docker compose down
```

完全清理：

```powershell
docker compose down -v
```

> PowerShell 不使用 CMD 的 `cd /d` 语法。
> PowerShell 中可直接使用 `Set-Location "D:\path"` 或 `cd "D:\path"`。

---

## 19. M0 干净环境验收

M0 最终验收应在新的目录中重新 clone 项目执行。

不要使用原开发目录中的：

- `target/`
- `node_modules/`
- `dist/`
- 本地数据库数据
- 未提交配置

来完成验收。

### 19.1 克隆

```bash
git clone https://github.com/heydapeng/fitness-platform.git
cd fitness-platform
```

如果 M0 当前位于开发分支：

```bash
git switch dev-v1
```

### 19.2 检查工具

```bash
java -version
node --version
npm --version
docker --version
docker compose version
```

要求：

```text
Java 21
Node.js 22
Docker 可用
Docker Compose v2 可用
```

不要求安装全局 Maven。

### 19.3 创建本地环境配置

Linux / macOS：

```bash
cp .env.example .env
```

Windows PowerShell：

```powershell
Copy-Item .env.example .env
```

填写本地开发使用的密码。

不要提交 `.env`。

### 19.4 启动基础设施

```bash
docker compose up -d
docker compose ps
```

确认：

- MySQL 正常；
- Redis 正常。

Redis 验证：

```bash
docker compose exec redis redis-cli ping
```

应返回：

```text
PONG
```

### 19.5 后端测试

Linux / macOS：

```bash
cd fitnessSystem
./mvnw --version
./mvnw test
```

Windows PowerShell，如果 Windows 可以直接访问 Docker：

```powershell
Set-Location .\fitnessSystem
.\mvnw.cmd --version
.\mvnw.cmd test
```

如果 Docker daemon 运行在 WSL：

```powershell
wsl bash -lc "cd /mnt/d/codes/fitness-platform/fitnessSystem && ./mvnw test"
```

要求：

```text
BUILD SUCCESS
```

并且测试实际执行，不能以：

```text
Tests run: 0
```

作为测试通过的依据。

### 19.6 后端构建

Linux / macOS：

```bash
./mvnw clean verify
```

Windows：

```powershell
.\mvnw.cmd clean verify
```

### 19.7 Flyway 空库验收

回到项目根目录：

```bash
docker compose down -v
docker compose up -d
```

等待 MySQL 正常。

启动后端：

```bash
cd fitnessSystem
./mvnw spring-boot:run
```

Flyway 应：

- 发现空 schema；
- 创建 schema history；
- 执行全部 migration；
- 最终到达当前最新版本。

停止后端后再次启动。

第二次启动时不应重复执行 migration。

应看到类似：

```text
Schema fitness is up to date. No migration necessary.
```

### 19.8 前端

回到根目录后进入：

```bash
cd fitness-frontend
```

执行：

```bash
npm ci
npm run type-check
npm run test:unit -- --run
npm run build
```

全部必须成功。

### 19.9 CI

push 一个正常提交。

GitHub Actions 应执行：

```text
Backend tests
Frontend checks
```

并正确通过。

在 GitHub Actions 页面手动运行 `CI`，并启用 `failure_probe`，验证一次故意失败场景。

故意失败时 GitHub Actions 必须正确标记失败。

不得通过缓存或条件判断掩盖实际失败。

### 19.10 Secret 检查

Git 中不得存在：

- 真实数据库密码；
- JWT Secret；
- API Key；
- `.env`；
- 生产环境凭据。

允许：

```text
${DB_PASSWORD}
${JWT_SECRET}
```

这类环境变量引用。

允许：

```text
<db-password>
your-local-password
your-local-secret
```

这类明显的示例占位符。

### 19.11 最终验收标准

全部满足以下条件才算 M0 完成：

- Java 21 正确；
- Maven Wrapper 可以独立工作；
- 不依赖全局 Maven；
- 后端测试实际执行并通过；
- 后端构建通过；
- 前端 `npm ci` 通过；
- 前端 type-check 通过；
- 前端 Vitest 测试通过；
- 前端 production build 通过；
- MySQL 8 可以通过 Docker Compose 启动；
- Redis 可以通过 Docker Compose 启动；
- Redis 连通性验证通过；
- 空数据库 Flyway 自动执行全部 migration；
- 重复启动不会重复执行 migration；
- 测试不依赖开发者本机 `fitness` 数据库；
- Testcontainers 可以重复执行；
- CI 对正常提交可以正确通过；
- CI 对故意失败可以正确识别；
- CI cache 不掩盖失败；
- CI 日志不泄漏 Secret；
- README 中的命令可以从 clean checkout 直接执行；
- Git 中不存在真实数据库密码、JWT Secret 或其他 Secret；
- 工作区可以保持 clean。

---

## 20. M0 当前进度

### T0.1 保护现有工作并建立提交基线

**已完成。**

完成内容：

- 已整理现有工作；
- 已检查新增、修改和目录变化；
- `.gitignore` 已覆盖工程基线；
- 数据库密码和 JWT Secret 已改为环境变量读取；
- 已避免提交真实 Secret；
- 已建立语义明确的 Git 提交；
- 当前工作区可以保持 clean。

---

### T0.2 Java 与 Maven 环境

**已完成。**

当前工程基线：

```text
Java 21
Apache Maven 3.9.16
Maven Wrapper 3.3.4
```

Maven Wrapper 可以正常运行。

项目不依赖全局 Maven。

Linux / macOS：

```bash
./mvnw --version
./mvnw test
```

Windows PowerShell：

```powershell
.\mvnw.cmd --version
.\mvnw.cmd test
```

---

### T0.3 前端构建基线

**已完成。**

前端目录：

```text
fitness-frontend/
```

已验证：

```bash
npm ci
npm run type-check
npm run test:unit -- --run
npm run build
```

全部通过。

Vitest TypeScript 配置已经恢复。

没有通过删除测试配置的方式绕过问题。

---

### T0.4 MySQL / Redis 本地基础设施

**已完成。**

已实现：

- MySQL 8 Docker Compose 服务；
- Redis 7 Docker Compose 服务；
- 持久化 volume；
- 健康检查；
- 环境变量配置；
- `.env.example`；
- MySQL 本地端口 3307；
- Redis 本地端口 6380。

已验证：

- MySQL 正常启动；
- Redis 正常启动；
- Redis `PING` 返回 `PONG`；
- 空数据库 Flyway 可以执行全部 migration；
- 重复启动不会重复执行 migration；
- `docker compose down` 可停止；
- `docker compose down -v` 可完全清理。

---

### T0.5 测试配置隔离

**已完成。**

测试方案：

```text
Testcontainers + MySQL 8
```

已实现：

- 独立 test profile；
- 独立 MySQL Testcontainer；
- datasource 动态注入；
- Flyway 在测试数据库中执行；
- trigger migration 支持；
- 测试不依赖本机 `fitness`；
- 测试可以重复运行。

当前后端测试已经验证：

```text
Tests run: 1
Failures: 0
Errors: 0
BUILD SUCCESS
```

并连续执行通过。

---

### T0.6 CI 基线

**已完成。**

CI：

```text
GitHub Actions
```

Workflow：

```text
.github/workflows/ci.yml
```

触发：

```text
push
pull_request
workflow_dispatch（可选 failure_probe）
```

后端执行：

```bash
./mvnw --batch-mode --no-transfer-progress test
```

前端执行：

```bash
npm ci
npm run type-check
npm run test:unit -- --run
npm run build
```

CI 使用：

- Java 21；
- Node.js 22；
- Maven dependency cache；
- npm dependency cache；
- GitHub-hosted Ubuntu runner；
- Docker；
- Testcontainers。

CI 不依赖：

- 开发者本地 Maven；
- 开发者本地 MySQL 数据；
- 开发者本地 Redis 数据。

`failure_probe` 只在手动触发并显式启用时运行，用于验证 CI 能正确标记失败，
不会影响正常提交和 Pull Request。

---

## 21. M0 完成定义

当第 19 节的 clean checkout 验收全部通过后，可以正式认为：

```text
M0 完成
```

M0 提供以下工程能力：

- 干净环境可安装；
- 干净环境可构建；
- 干净环境可测试；
- 干净环境可启动；
- 数据库迁移可重复；
- 测试环境可隔离；
- CI 行为可重复；
- 开发者无需依赖未文档化的本地状态。

M0 不新增业务功能。

后续业务功能开发应建立在该工程基线上。
