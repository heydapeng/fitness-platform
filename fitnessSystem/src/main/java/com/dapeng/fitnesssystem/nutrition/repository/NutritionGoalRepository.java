package com.dapeng.fitnesssystem.nutrition.repository;
import com.dapeng.fitnesssystem.nutrition.entity.NutritionGoal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
@Repository
public interface NutritionGoalRepository extends JpaRepository<NutritionGoal, Long> {

    List<NutritionGoal> findByUser_IdOrderByEffectiveDateDesc(Long userId);

    Optional<NutritionGoal> findByUser_IdAndEffectiveDate(Long userId, LocalDate effectiveDate);

    @Query("""
            select g
            from NutritionGoal g
            where g.user.id = :userId
              and g.effectiveDate <= :date
              and (g.endDate is null or g.endDate >= :date)
            order by g.effectiveDate desc
            """)
    List<NutritionGoal> findEffectiveGoals(
            @Param("userId") Long userId,
            @Param("date") LocalDate date
    );
}
