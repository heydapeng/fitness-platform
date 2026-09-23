package com.dapeng.fitnesssystem.common.pagination;

import com.dapeng.fitnesssystem.common.exception.ValidationException;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PageRequestFactoryTest {

    @Test
    void appliesDefaultPaginationAndMapsPageMetadata() {
        Pageable pageable = PageRequestFactory.create(null, null, null, Set.of("createdAt"));
        PageResponse<String> response = PageResponse.from(new PageImpl<>(List.of("a", "b"), PageRequest.of(0, 2), 3));

        assertThat(pageable.getPageNumber()).isEqualTo(0);
        assertThat(pageable.getPageSize()).isEqualTo(20);
        assertThat(response.content()).containsExactly("a", "b");
        assertThat(response.totalElements()).isEqualTo(3);
        assertThat(response.totalPages()).isEqualTo(2);
        assertThat(response.first()).isTrue();
        assertThat(response.last()).isFalse();
    }

    @Test
    void acceptsOnlyWhitelistedSortFieldsAndDirections() {
        Pageable pageable = PageRequestFactory.create(1, 10, "createdAt,desc", Set.of("createdAt"));

        assertThat(pageable.getSort().getOrderFor("createdAt").isDescending()).isTrue();
        assertThatThrownBy(() -> PageRequestFactory.create(0, 20, "id;drop table,asc", Set.of("createdAt")))
                .isInstanceOf(ValidationException.class);
        assertThatThrownBy(() -> PageRequestFactory.create(0, 20, "createdAt,sideways", Set.of("createdAt")))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    void rejectsInvalidPageBounds() {
        assertThatThrownBy(() -> PageRequestFactory.create(-1, 20, null, Set.of())).isInstanceOf(ValidationException.class);
        assertThatThrownBy(() -> PageRequestFactory.create(0, 101, null, Set.of())).isInstanceOf(ValidationException.class);
    }
}
