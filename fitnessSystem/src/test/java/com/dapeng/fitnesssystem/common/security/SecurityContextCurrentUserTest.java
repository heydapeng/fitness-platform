package com.dapeng.fitnesssystem.common.security;

import com.dapeng.fitnesssystem.common.exception.UnauthenticatedException;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.ZoneId;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class SecurityContextCurrentUserTest {

    private final SecurityContextCurrentUser currentUser = new SecurityContextCurrentUser();

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void rejectsUnauthenticatedAccess() {
        assertThatThrownBy(currentUser::currentUserId)
                .isInstanceOf(UnauthenticatedException.class);
    }

    @Test
    void readsNormalUserIdentityAndTimezoneFromSecurityContext() {
        authenticate(42L, "Asia/Shanghai", "ROLE_USER");

        assertThat(currentUser.currentUserId()).isEqualTo(42L);
        assertThat(currentUser.currentUserTimezone()).isEqualTo(ZoneId.of("Asia/Shanghai"));
        assertThat(currentUser.isAdmin()).isFalse();
    }

    @Test
    void identifiesAdminFromGrantedRole() {
        authenticate(7L, "UTC", "ROLE_ADMIN");

        assertThat(currentUser.isAdmin()).isTrue();
    }

    private void authenticate(Long userId, String timezone, String role) {
        AuthenticatedUser principal = new AuthenticatedUser(userId, ZoneId.of(timezone));
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, AuthorityUtils.createAuthorityList(role))
        );
    }
}
