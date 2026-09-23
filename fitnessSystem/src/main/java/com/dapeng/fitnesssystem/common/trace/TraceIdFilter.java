package com.dapeng.fitnesssystem.common.trace;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Component
public class TraceIdFilter extends OncePerRequestFilter {

    public static final String HEADER_NAME = "X-Trace-Id";
    private static final String MDC_KEY = "traceId";

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String traceId = requestedOrGeneratedTraceId(request);
        TraceIdContext.set(traceId);
        MDC.put(MDC_KEY, traceId);
        response.setHeader(HEADER_NAME, traceId);
        try {
            filterChain.doFilter(request, response);
        } finally {
            MDC.remove(MDC_KEY);
            TraceIdContext.clear();
        }
    }

    private String requestedOrGeneratedTraceId(HttpServletRequest request) {
        String requestedTraceId = request.getHeader(HEADER_NAME);
        return requestedTraceId == null || requestedTraceId.isBlank()
                ? UUID.randomUUID().toString()
                : requestedTraceId;
    }
}
