package com.dapeng.fitnesssystem.common.security;

import java.time.ZoneId;

public interface CurrentUser {

    Long currentUserId();

    ZoneId currentUserTimezone();

    boolean isAdmin();
}
