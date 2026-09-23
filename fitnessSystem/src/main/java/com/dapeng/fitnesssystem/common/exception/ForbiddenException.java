package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import org.springframework.http.HttpStatus;

public class ForbiddenException extends DomainException {

    public ForbiddenException(String message) {
        super(HttpStatus.FORBIDDEN, ErrorCode.ACCESS_DENIED, message);
    }
}
