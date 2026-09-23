package com.dapeng.fitnesssystem.auth.dto;

public record LoginResponse(
        Long id,
        String email,
        String nickname,
        String timezone,
        String accessToken,
        String tokenType,
        long expiresIn
) {
}
