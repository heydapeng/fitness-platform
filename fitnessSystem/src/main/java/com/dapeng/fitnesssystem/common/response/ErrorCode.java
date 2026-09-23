package com.dapeng.fitnesssystem.common.response;

public enum ErrorCode {
    SUCCESS,
    VALIDATION_FAILED,
    UNAUTHENTICATED,
    ACCESS_DENIED,
    RESOURCE_NOT_FOUND,
    RESOURCE_VERSION_CONFLICT,
    IDEMPOTENCY_CONFLICT,
    EDIT_WINDOW_EXPIRED,
    EXTERNAL_SERVICE_UNAVAILABLE,
    RATE_LIMITED,
    INTERNAL_ERROR;

    public String value() {
        return name();
    }
}
