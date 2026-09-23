package com.dapeng.fitnesssystem.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(
        @NotBlank(message = "邮箱不能为空")
        @Email(message = "邮箱格式不正确")
        @Size(max = 255, message = "邮箱长度不能超过255个字符")
        String email,

        @NotBlank(message = "密码不能为空")
        @Size(min = 8, max = 72, message = "密码长度必须为8到72个字符")
        String password
) {
}
