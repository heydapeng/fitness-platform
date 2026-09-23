package com.dapeng.fitnesssystem;

import com.dapeng.fitnesssystem.support.MySqlContainerTest;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class FitnessSystemApplicationTests extends MySqlContainerTest {

    @Test
    void contextLoads() {
    }
}