package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import com.dapeng.fitnesssystem.common.response.FieldError;
import org.springframework.http.HttpStatus;

import java.util.List;

public abstract class DomainException extends RuntimeException {

    private final HttpStatus status;
    private final ErrorCode errorCode;
    private final List<FieldError> fieldErrors;

    protected DomainException(HttpStatus status, ErrorCode errorCode, String message) {
        this(status, errorCode, message, null);
    }

    protected DomainException(HttpStatus status, ErrorCode errorCode, String message, List<FieldError> fieldErrors) {
        super(message);
        this.status = status;
        this.errorCode = errorCode;
        this.fieldErrors = fieldErrors;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public ErrorCode getErrorCode() {
        return errorCode;
    }

    public List<FieldError> getFieldErrors() {
        return fieldErrors;
    }
}
