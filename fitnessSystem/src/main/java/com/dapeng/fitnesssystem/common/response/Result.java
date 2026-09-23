package com.dapeng.fitnesssystem.common.response;

import com.dapeng.fitnesssystem.common.trace.TraceIdContext;
import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record Result<T>(
        String code,
        String message,
        T data,
        String traceId,
        List<FieldError> fieldErrors
) {
    public static <T> Result<T> success(T data) {
        return new Result<>(ErrorCode.SUCCESS.value(), "success", data, null, null);
    }

    public static <T> Result<T> success(String message, T data) {
        return new Result<>(ErrorCode.SUCCESS.value(), message, data, null, null);
    }

    public static <T> Result<T> failure(ErrorCode code, String message) {
        return failure(code, message, null);
    }

    public static <T> Result<T> failure(ErrorCode code, String message, List<FieldError> fieldErrors) {
        return new Result<>(code.value(), message, null, TraceIdContext.current(), fieldErrors);
    }
}
