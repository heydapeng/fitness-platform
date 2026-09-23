package com.dapeng.fitnesssystem.common.security;
import java.time.ZoneId;
import java.util.Objects;

public record AuthenticatedUser(
        Long userId,
        ZoneId timezone
) {
    public AuthenticatedUser {
        Objects.requireNonNull(userId, "userId must not be null");
        Objects.requireNonNull(timezone, "timezone must not be null");
    }
}
