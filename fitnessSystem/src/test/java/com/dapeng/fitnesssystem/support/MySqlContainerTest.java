package com.dapeng.fitnesssystem.support;

import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.mysql.MySQLContainer;

@Testcontainers
public abstract class MySqlContainerTest {

    @Container
    protected static final MySQLContainer MYSQL =
            new MySQLContainer("mysql:8.0")
                    .withCommand("--log-bin-trust-function-creators=1")
                    .withDatabaseName("fitness_test")
                    .withUsername("fitness_test")
                    .withPassword("fitness_test");

    @DynamicPropertySource
    static void databaseProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MYSQL::getJdbcUrl);
        registry.add("spring.datasource.username", MYSQL::getUsername);
        registry.add("spring.datasource.password", MYSQL::getPassword);
        registry.add("spring.datasource.driver-class-name", MYSQL::getDriverClassName);
    }
}