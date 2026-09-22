package com.dapeng.fitnesssystem.auth.dto;

public record LoginResponse(
        Long id,
        String email,
        String nickname,
        String timezone)
{
}
