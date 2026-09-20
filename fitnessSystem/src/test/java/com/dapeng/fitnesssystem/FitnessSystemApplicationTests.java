package com.dapeng.fitnesssystem;

import com.dapeng.fitnesssystem.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class FitnessSystemApplicationTests {
   @Autowired
   UserRepository userRepository;
    @Test
    void contextLoads() {


    }


    @Test
    void testRepository(){

        boolean b = userRepository.existsByEmail("hello@gmail.com");
        System.out.println(b);

    }

}
