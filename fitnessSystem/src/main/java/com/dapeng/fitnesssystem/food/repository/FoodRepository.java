package com.dapeng.fitnesssystem.food.repository;

import com.dapeng.fitnesssystem.food.entity.Food;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface FoodRepository extends JpaRepository<Food, Long> {

    boolean existsByName(String name);

    Optional<Food> findByName(String name);

    @Query("""
            select f
            from Food f
            where f.status = :status
              and (:keyword is null or f.name like concat('%', :keyword, '%'))
              and (:categoryId is null or f.category.id = :categoryId)
            """)
    Page<Food> search(
            @Param("keyword") String keyword,
            @Param("categoryId") Long categoryId,
            @Param("status") Integer status,
            Pageable pageable
    );
}
