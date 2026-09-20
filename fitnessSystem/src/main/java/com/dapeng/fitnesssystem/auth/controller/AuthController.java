package com.dapeng.fitnesssystem.auth.controller;

import com.dapeng.fitnesssystem.auth.dto.RegisterRequest;
import com.dapeng.fitnesssystem.auth.dto.RegisterResponse;
import com.dapeng.fitnesssystem.auth.service.AuthService;
import com.dapeng.fitnesssystem.common.Result;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService authService;
    public AuthController(AuthService authService) {
        this.authService = authService;
    }
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public Result register(@Valid @RequestBody RegisterRequest registerRequest) {
        RegisterResponse register = authService.register(registerRequest);
        return Result.success(register);
    }




}
