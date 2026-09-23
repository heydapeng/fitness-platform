package com.dapeng.fitnesssystem.common.response;

import com.dapeng.fitnesssystem.common.trace.TraceIdContext;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ResultTest {

    @AfterEach
    void clearTraceId() {
        TraceIdContext.clear();
    }

    @Test
    void successUsesStableStringCode() {
        Result<String> result = Result.success("ok");

        assertThat(result.code()).isEqualTo("SUCCESS");
        assertThat(result.message()).isEqualTo("success");
        assertThat(result.data()).isEqualTo("ok");
        assertThat(result.traceId()).isNull();
        assertThat(result.fieldErrors()).isNull();
    }

    @Test
    void failureIncludesCurrentTraceIdAndFieldErrors() {
        TraceIdContext.set("trace-123");
        List<FieldError> fieldErrors = List.of(new FieldError("email", "邮箱格式不正确"));

        Result<Void> result = Result.failure(ErrorCode.VALIDATION_FAILED, "参数校验失败", fieldErrors);

        assertThat(result.code()).isEqualTo("VALIDATION_FAILED");
        assertThat(result.data()).isNull();
        assertThat(result.traceId()).isEqualTo("trace-123");
        assertThat(result.fieldErrors()).containsExactlyElementsOf(fieldErrors);
    }
}
