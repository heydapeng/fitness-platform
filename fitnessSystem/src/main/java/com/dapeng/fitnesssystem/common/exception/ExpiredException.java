package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import org.springframework.http.HttpStatus;

public class ExpiredException extends DomainException {

    public ExpiredException(String message) {
        super(HttpStatus.GONE, ErrorCode.EDIT_WINDOW_EXPIRED, message);
    }
}
