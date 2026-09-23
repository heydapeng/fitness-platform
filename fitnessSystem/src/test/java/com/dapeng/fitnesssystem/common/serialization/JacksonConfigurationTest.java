package com.dapeng.fitnesssystem.common.serialization;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

import java.math.BigDecimal;
import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class JacksonConfigurationTest {

    @Test
    void serializesInstantBigDecimalAndEnumWithApiConventions() throws Exception {
        Jackson2ObjectMapperBuilder builder = new Jackson2ObjectMapperBuilder();
        new JacksonConfiguration().apiJsonCustomizer().customize(builder);
        ObjectMapper objectMapper = builder.build();

        String json = objectMapper.writeValueAsString(new SerializationSample(
                Instant.parse("2026-09-23T08:00:00Z"), new BigDecimal("12.345"), Status.ACTIVE
        ));

        assertThat(json).contains("\"occurredAt\":\"2026-09-23T08:00:00Z\"");
        assertThat(json).contains("\"calories\":12.35");
        assertThat(json).contains("\"status\":\"ACTIVE\"");
    }

    private record SerializationSample(Instant occurredAt, BigDecimal calories, Status status) {
    }

    private enum Status {
        ACTIVE
    }
}
