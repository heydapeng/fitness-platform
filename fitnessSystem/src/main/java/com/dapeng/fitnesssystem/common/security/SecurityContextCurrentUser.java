package com.dapeng.fitnesssystem.common.security;

import com.dapeng.fitnesssystem.common.exception.UnauthenticatedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.time.ZoneId;

@Component
public class SecurityContextCurrentUser implements CurrentUser {

    @Override
    public Long currentUserId() {
        return authenticatedUser().userId();
    }

    @Override
    public ZoneId currentUserTimezone() {
        return authenticatedUser().timezone();
    }

    @Override
    public boolean isAdmin() {
        return authentication().getAuthorities().stream()
                .anyMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority()));
    }

    private AuthenticatedUser authenticatedUser() {
        Object principal = authentication().getPrincipal();
        if (principal instanceof AuthenticatedUser authenticatedUser) {
            return authenticatedUser;
        }
        throw new UnauthenticatedException();
    }

    private Authentication authentication() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new UnauthenticatedException();
        }
        return authentication;
    }
}
