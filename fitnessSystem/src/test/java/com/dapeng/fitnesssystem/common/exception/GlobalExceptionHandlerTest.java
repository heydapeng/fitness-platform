package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import com.dapeng.fitnesssystem.common.response.FieldError;
import com.dapeng.fitnesssystem.common.response.Result;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void mapsEachDomainExceptionToItsContractedHttpStatusAndErrorCode() {
        assertDomainException(new ValidationException("参数错误"), HttpStatus.BAD_REQUEST, ErrorCode.VALIDATION_FAILED);
        assertDomainException(new NotFoundException("不存在"), HttpStatus.NOT_FOUND, ErrorCode.RESOURCE_NOT_FOUND);
        assertDomainException(new ForbiddenException("没有权限"), HttpStatus.FORBIDDEN, ErrorCode.ACCESS_DENIED);
        assertDomainException(new ConflictException("数据冲突"), HttpStatus.CONFLICT, ErrorCode.RESOURCE_VERSION_CONFLICT);
        assertDomainException(new ExpiredException("资源已过期"), HttpStatus.GONE, ErrorCode.EDIT_WINDOW_EXPIRED);
        assertDomainException(new ExternalServiceException("服务暂不可用"), HttpStatus.SERVICE_UNAVAILABLE, ErrorCode.EXTERNAL_SERVICE_UNAVAILABLE);
    }

    @Test
    void validationExceptionPreservesFieldErrors() {
        List<FieldError> fieldErrors = List.of(new FieldError("email", "邮箱格式不正确"));

        ResponseEntity<Result<Void>> response = handler.handleDomain(new ValidationException("参数错误", fieldErrors));

        assertThat(response.getBody().fieldErrors()).containsExactlyElementsOf(fieldErrors);
    }

    @Test
    void unexpectedExceptionDoesNotExposeInternalMessage() {
        ResponseEntity<Result<Void>> response = handler.handleUnexpected(new IllegalStateException("数据库连接字符串"));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody().code()).isEqualTo(ErrorCode.INTERNAL_ERROR.value());
        assertThat(response.getBody().message()).isEqualTo("服务器内部错误");
    }

    private void assertDomainException(DomainException exception, HttpStatus status, ErrorCode errorCode) {
        ResponseEntity<Result<Void>> response = handler.handleDomain(exception);

        assertThat(response.getStatusCode()).isEqualTo(status);
        assertThat(response.getBody().code()).isEqualTo(errorCode.value());
        assertThat(response.getBody().message()).isEqualTo(exception.getMessage());
    }
}
