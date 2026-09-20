package com.dapeng.fitnesssystem.food.repository;

import com.dapeng.fitnesssystem.food.entity.FoodRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface FoodRecordRepository extends JpaRepository<FoodRecord, Long> {

    List<FoodRecord> findByUser_IdAndRecordDate(Long userId, LocalDate recordDate);

    Optional<FoodRecord> findByUser_IdAndClientRequestId(Long userId, String clientRequestId);
}
