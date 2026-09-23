package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import com.dapeng.fitnesssystem.common.response.FieldError;
import org.springframework.http.HttpStatus;

import java.util.List;

public class ValidationException extends DomainException {

    public ValidationException(String message) {
        super(HttpStatus.BAD_REQUEST, ErrorCode.VALIDATION_FAILED, message);
    }

    public ValidationException(String message, List<FieldError> fieldErrors) {
        super(HttpStatus.BAD_REQUEST, ErrorCode.VALIDATION_FAILED, message, fieldErrors);
    }
}
