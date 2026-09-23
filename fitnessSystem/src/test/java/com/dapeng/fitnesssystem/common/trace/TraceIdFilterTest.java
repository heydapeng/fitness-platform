package com.dapeng.fitnesssystem.common.trace;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;

class TraceIdFilterTest {

    private final TraceIdFilter filter = new TraceIdFilter();

    @AfterEach
    void clearTraceId() {
        TraceIdContext.clear();
    }

    @Test
    void reusesIncomingTraceIdAndClearsContextAfterRequest() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.addHeader(TraceIdFilter.HEADER_NAME, "client-trace-123");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, (ignoredRequest, ignoredResponse) ->
                assertThat(TraceIdContext.current()).isEqualTo("client-trace-123"));

        assertThat(response.getHeader(TraceIdFilter.HEADER_NAME)).isEqualTo("client-trace-123");
        assertThat(TraceIdContext.current()).isNull();
    }

    @Test
    void createsTraceIdWhenHeaderIsMissing() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(new MockHttpServletRequest(), response, (ignoredRequest, ignoredResponse) -> {
        });

        assertThat(response.getHeader(TraceIdFilter.HEADER_NAME)).isNotBlank();
    }
}
