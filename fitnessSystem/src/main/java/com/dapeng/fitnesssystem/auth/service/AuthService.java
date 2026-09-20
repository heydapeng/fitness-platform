package com.dapeng.fitnesssystem.auth.service;
import com.dapeng.fitnesssystem.auth.dto.RegisterRequest;
import com.dapeng.fitnesssystem.auth.dto.RegisterResponse;
import com.dapeng.fitnesssystem.user.entity.User;
import com.dapeng.fitnesssystem.user.entity.UserRole;
import com.dapeng.fitnesssystem.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.sql.ConnectionBuilder;
import java.time.LocalDateTime;
import java.util.Locale;
@Service
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }
    @Transactional
    public RegisterResponse register(RegisterRequest registerRequest) {
        String email = registerRequest.email().trim().toLowerCase(Locale.ROOT);
        if(!registerRequest.password().equals(registerRequest.confirmPassword())){
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "两次密码输入不一致"
            );
        }
        if(userRepository.existsByEmail(email)){
            throw new ResponseStatusException(HttpStatus.CONFLICT,"该邮箱已经注册");
        }
        String nickname = registerRequest.nickname();
        if(nickname != null && !nickname.isEmpty()){
            nickname = nickname.trim();
        }
        String timezone = registerRequest.timezone() == null || registerRequest.timezone().isBlank()
                ? "UTC" : registerRequest.timezone().trim();
        LocalDateTime now = LocalDateTime.now();

        User user = new User();
        user.setEmail(email);
        ConnectionBuilder request;
        user.setPasswordHash(
                passwordEncoder.encode(registerRequest.password())
        );
        user.setNickname(nickname);
        user.setTimezone(timezone);

        // 这两个字段只能由服务端决定
        user.setRole(UserRole.USER);
        user.setStatus(1);

        user.setCreatedAt(now);
        user.setUpdatedAt(now);

        User savedUser = userRepository.save(user);
        return new RegisterResponse(
                savedUser.getId(),
                savedUser.getEmail(),
                savedUser.getNickname(),
                savedUser.getTimezone()
        );
    }
}
