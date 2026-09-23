package com.dapeng.fitnesssystem.common.response;

public record FieldError(
        String field,
        String message
) {
}
