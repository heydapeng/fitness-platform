package com.dapeng.fitnesssystem.auth.dto;

public record RegisterResponse(
        Long id,
        String email,
        String nickname,
        String timezone
) {

}