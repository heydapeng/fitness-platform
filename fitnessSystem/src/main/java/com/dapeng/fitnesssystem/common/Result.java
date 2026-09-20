package com.dapeng.fitnesssystem.common;


public record Result<T>(
        Integer code,
        String message,
        T data
) {

    public static <T> Result<T> success(T data) {
        return new Result<>(0, "success", data);
    }

    public static <T> Result<T> success(
            String message,
            T data
    ) {
        return new Result<>(0, message, data);
    }

    public static <T> Result<T> failure(
            Integer code,
            String message
    ) {
        return new Result<>(code, message, null);
    }
}