package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import org.springframework.http.HttpStatus;

public class ExternalServiceException extends DomainException {

    public ExternalServiceException(String message) {
        super(HttpStatus.SERVICE_UNAVAILABLE, ErrorCode.EXTERNAL_SERVICE_UNAVAILABLE, message);
    }
}
