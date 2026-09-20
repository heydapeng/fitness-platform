package com.dapeng.fitnesssystem.food.repository;

import com.dapeng.fitnesssystem.food.entity.FoodCategory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FoodCategoryRepository extends JpaRepository<FoodCategory, Long> {

    boolean existsByName(String name);

    List<FoodCategory> findByStatusOrderBySortOrderAsc(Integer status);
}
