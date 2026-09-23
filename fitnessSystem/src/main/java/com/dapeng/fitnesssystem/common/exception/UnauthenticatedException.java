package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import org.springframework.http.HttpStatus;

public class UnauthenticatedException extends DomainException {

    public UnauthenticatedException() {
        super(HttpStatus.UNAUTHORIZED, ErrorCode.UNAUTHENTICATED, "请先登录");
    }
}
