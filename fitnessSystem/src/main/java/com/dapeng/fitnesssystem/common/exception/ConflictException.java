package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import org.springframework.http.HttpStatus;

public class ConflictException extends DomainException {

    public ConflictException(String message) {
        super(HttpStatus.CONFLICT, ErrorCode.RESOURCE_VERSION_CONFLICT, message);
    }
}
