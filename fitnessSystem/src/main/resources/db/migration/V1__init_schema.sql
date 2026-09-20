-- Fitness Nutrition Platform
-- V1 数据库初始化脚本
-- 说明：
-- 1. 本文件用于 Flyway migration，默认由 Spring Boot 配置连接到目标数据库。
-- 2. 不包含 CREATE DATABASE、USE、DROP TABLE，避免迁移脚本误删已有数据。
-- 3. V1 仅创建当前版本需要的核心表，后续版本通过新的 migration 文件扩展。

-- ----------------------------
-- 用户表
-- ----------------------------
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `email` varchar(255) NOT NULL COMMENT '登录邮箱',
  `password_hash` varchar(255) NOT NULL COMMENT '密码哈希',
  `nickname` varchar(100) DEFAULT NULL COMMENT '昵称',
  `timezone` varchar(64) NOT NULL DEFAULT 'UTC' COMMENT '用户时区，如 Asia/Shanghai',
  `role` varchar(20) NOT NULL DEFAULT 'USER' COMMENT '角色：USER普通用户，ADMIN管理员',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态：0禁用，1启用',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';


-- ----------------------------
-- 营养目标表
-- ----------------------------
CREATE TABLE `nutrition_goals` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '用户id',
  `calories_target` decimal(10,2) NOT NULL COMMENT '每日目标热量 kcal',
  `protein_target_g` decimal(10,2) NOT NULL COMMENT '每日目标蛋白质 g',
  `fat_target_g` decimal(10,2) NOT NULL COMMENT '每日目标脂肪 g',
  `carbs_target_g` decimal(10,2) NOT NULL COMMENT '每日目标碳水 g',
  `effective_date` date NOT NULL COMMENT '生效日期',
  `end_date` date DEFAULT NULL COMMENT '结束日期，NULL表示当前仍有效',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_nutrition_goal_user_effective` (`user_id`, `effective_date`),
  KEY `idx_nutrition_goal_user_dates` (`user_id`, `effective_date`, `end_date`),
  CONSTRAINT `fk_nutrition_goal_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户每日营养目标历史表';


-- ----------------------------
-- 食品分类表
-- ----------------------------
CREATE TABLE `food_categories` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(100) NOT NULL COMMENT '分类名称',
  `sort_order` int NOT NULL DEFAULT '0' COMMENT '排序值，越小越靠前',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态：0禁用，1启用',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_food_category_name` (`name`),
  KEY `idx_food_category_status_sort` (`status`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='食品分类表';


-- ----------------------------
-- 食品表
-- ----------------------------
CREATE TABLE `foods` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `category_id` bigint NOT NULL COMMENT '食品分类id',
  `name` varchar(255) NOT NULL COMMENT '规范化完整食品名称',
  `calories_per_100g` decimal(10,2) NOT NULL COMMENT '每100g热量 kcal',
  `protein_per_100g` decimal(10,2) NOT NULL COMMENT '每100g蛋白质 g',
  `fat_per_100g` decimal(10,2) NOT NULL COMMENT '每100g脂肪 g',
  `carbs_per_100g` decimal(10,2) NOT NULL COMMENT '每100g碳水 g',
  `source` varchar(100) DEFAULT NULL COMMENT '数据来源，如 USDA、管理员录入',
  `source_food_id` varchar(100) DEFAULT NULL COMMENT '外部数据源中的食品id',
  `description` varchar(500) DEFAULT NULL COMMENT '食品描述',
  `status` tinyint NOT NULL DEFAULT '1' COMMENT '状态：0停用，1启用',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_food_name` (`name`),
  UNIQUE KEY `uk_food_source` (`source`, `source_food_id`),
  KEY `idx_food_category_status` (`category_id`, `status`),
  KEY `idx_food_status` (`status`),
  CONSTRAINT `fk_food_category`
    FOREIGN KEY (`category_id`) REFERENCES `food_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='食品基础数据表';


-- ----------------------------
-- 饮食记录表
-- ----------------------------
CREATE TABLE `food_records` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '用户id',
  `food_id` bigint NOT NULL COMMENT '食品id',
  `record_date` date NOT NULL COMMENT '饮食业务日期',
  `meal_type` varchar(20) NOT NULL COMMENT '餐次：BREAKFAST早餐，LUNCH午餐，DINNER晚餐，SNACK加餐',
  `weight_g` decimal(10,2) NOT NULL COMMENT '实际食用重量 g',

  `food_name_snapshot` varchar(255) NOT NULL COMMENT '记录创建时的食品名称快照',
  `calories_per_100g_snapshot` decimal(10,2) NOT NULL COMMENT '记录创建时每100g热量快照',
  `protein_per_100g_snapshot` decimal(10,2) NOT NULL COMMENT '记录创建时每100g蛋白质快照',
  `fat_per_100g_snapshot` decimal(10,2) NOT NULL COMMENT '记录创建时每100g脂肪快照',
  `carbs_per_100g_snapshot` decimal(10,2) NOT NULL COMMENT '记录创建时每100g碳水快照',

  `calories_actual` decimal(10,2) NOT NULL COMMENT '本次实际摄入热量 kcal',
  `protein_actual` decimal(10,2) NOT NULL COMMENT '本次实际摄入蛋白质 g',
  `fat_actual` decimal(10,2) NOT NULL COMMENT '本次实际摄入脂肪 g',
  `carbs_actual` decimal(10,2) NOT NULL COMMENT '本次实际摄入碳水 g',

  `client_request_id` varchar(64) NOT NULL COMMENT '客户端请求唯一标识，用于防重复提交',
  `created_at` datetime(6) NOT NULL COMMENT '创建时间',
  `updated_at` datetime(6) NOT NULL COMMENT '更新时间',

  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_food_record_request` (`user_id`, `client_request_id`),
  KEY `idx_food_record_user_date` (`user_id`, `record_date`),
  KEY `idx_food_record_user_date_meal` (`user_id`, `record_date`, `meal_type`),
  KEY `idx_food_record_food` (`food_id`),

  CONSTRAINT `fk_food_record_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_food_record_food`
    FOREIGN KEY (`food_id`) REFERENCES `foods` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户饮食记录表';
