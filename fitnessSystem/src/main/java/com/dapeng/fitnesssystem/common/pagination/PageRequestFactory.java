package com.dapeng.fitnesssystem.common.pagination;

import com.dapeng.fitnesssystem.common.exception.ValidationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import java.util.Locale;
import java.util.Set;

public final class PageRequestFactory {

    public static final int DEFAULT_PAGE = 0;
    public static final int DEFAULT_SIZE = 20;
    public static final int MAX_SIZE = 100;

    private PageRequestFactory() {
    }

    public static Pageable create(Integer page, Integer size, String sort, Set<String> allowedSortFields) {
        int requestedPage = page == null ? DEFAULT_PAGE : page;
        int requestedSize = size == null ? DEFAULT_SIZE : size;
        if (requestedPage < 0) {
            throw new ValidationException("page 不能小于 0");
        }
        if (requestedSize < 1 || requestedSize > MAX_SIZE) {
            throw new ValidationException("size 必须在 1 到 100 之间");
        }
        if (sort == null || sort.isBlank()) {
            return PageRequest.of(requestedPage, requestedSize);
        }
        String[] values = sort.split(",", -1);
        if (values.length != 2 || !allowedSortFields.contains(values[0])) {
            throw new ValidationException("sort 字段不合法");
        }
        Sort.Direction direction = switch (values[1].toLowerCase(Locale.ROOT)) {
            case "asc" -> Sort.Direction.ASC;
            case "desc" -> Sort.Direction.DESC;
            default -> throw new ValidationException("sort 方向只能是 asc 或 desc");
        };
        return PageRequest.of(requestedPage, requestedSize, direction, values[0]);
    }
}
