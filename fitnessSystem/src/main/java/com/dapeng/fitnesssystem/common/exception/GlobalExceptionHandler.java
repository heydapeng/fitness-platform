package com.dapeng.fitnesssystem.common.exception;

import com.dapeng.fitnesssystem.common.response.ErrorCode;
import com.dapeng.fitnesssystem.common.response.FieldError;
import com.dapeng.fitnesssystem.common.response.Result;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.List;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Result<Void>> handleValidation(MethodArgumentNotValidException ex) {
        List<FieldError> fieldErrors = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> new FieldError(
                        error.getField(),
                        error.getDefaultMessage() == null ? "参数校验失败" : error.getDefaultMessage()
                ))
                .toList();
        String message = fieldErrors.stream()
                .findFirst()
                .map(FieldError::message)
                .orElse("参数校验失败");
        return ResponseEntity.badRequest().body(Result.failure(ErrorCode.VALIDATION_FAILED, message, fieldErrors));
    }

    @ExceptionHandler(DomainException.class)
    public ResponseEntity<Result<Void>> handleDomain(DomainException ex) {
        return ResponseEntity.status(ex.getStatus())
                .body(Result.failure(ex.getErrorCode(), ex.getMessage(), ex.getFieldErrors()));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Result<Void>> handleDataIntegrity(DataIntegrityViolationException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(Result.failure(ErrorCode.RESOURCE_VERSION_CONFLICT, "数据冲突，请刷新后重试"));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Result<Void>> handleUnexpected(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Result.failure(ErrorCode.INTERNAL_ERROR, "服务器内部错误"));
    }

}
