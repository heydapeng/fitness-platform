package com.dapeng.fitnesssystem.common.persistence;

import org.junit.jupiter.api.Test;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;

import java.lang.reflect.Field;
import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

class UtcAuditingConfigurationTest {

    @Test
    void providesAnInstantForJpaAuditing() {
        Object auditedTime = new UtcAuditingConfiguration().utcDateTimeProvider().getNow().orElseThrow();

        assertThat(auditedTime).isInstanceOf(Instant.class);
        assertThat((Instant) auditedTime).isBetween(Instant.now().minusSeconds(1), Instant.now().plusSeconds(1));
    }

    @Test
    void baseEntityUsesAuditedUtcInstants() throws Exception {
        Field createdAt = BaseEntity.class.getDeclaredField("createdAt");
        Field updatedAt = BaseEntity.class.getDeclaredField("updatedAt");

        assertThat(createdAt.getType()).isEqualTo(Instant.class);
        assertThat(updatedAt.getType()).isEqualTo(Instant.class);
        assertThat(createdAt.isAnnotationPresent(CreatedDate.class)).isTrue();
        assertThat(updatedAt.isAnnotationPresent(LastModifiedDate.class)).isTrue();
    }
}
