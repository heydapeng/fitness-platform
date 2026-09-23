package com.dapeng.fitnesssystem;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@EnableJpaAuditing
@SpringBootApplication
public class FitnessSystemApplication {

    public static void main(String[] args) {
        SpringApplication.run(FitnessSystemApplication.class, args);
    }
}
