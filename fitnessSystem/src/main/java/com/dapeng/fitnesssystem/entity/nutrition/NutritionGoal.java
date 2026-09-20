package com.dapeng.fitnesssystem.entity.nutrition;

import com.dapeng.fitnesssystem.entity.user.User;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "nutrition_goals",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_nutrition_goal_user_effective",
                columnNames = {"user_id", "effective_date"}
        ),
        indexes = @Index(
                name = "idx_nutrition_goal_user_dates",
                columnList = "user_id,effective_date,end_date"
        )
)
public class NutritionGoal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "calories_target", nullable = false, precision = 10, scale = 2)
    private BigDecimal caloriesTarget;

    @Column(name = "protein_target_g", nullable = false, precision = 10, scale = 2)
    private BigDecimal proteinTargetG;

    @Column(name = "fat_target_g", nullable = false, precision = 10, scale = 2)
    private BigDecimal fatTargetG;

    @Column(name = "carbs_target_g", nullable = false, precision = 10, scale = 2)
    private BigDecimal carbsTargetG;

    @Column(name = "effective_date", nullable = false)
    private LocalDate effectiveDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected NutritionGoal() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public BigDecimal getCaloriesTarget() {
        return caloriesTarget;
    }

    public void setCaloriesTarget(BigDecimal caloriesTarget) {
        this.caloriesTarget = caloriesTarget;
    }

    public BigDecimal getProteinTargetG() {
        return proteinTargetG;
    }

    public void setProteinTargetG(BigDecimal proteinTargetG) {
        this.proteinTargetG = proteinTargetG;
    }

    public BigDecimal getFatTargetG() {
        return fatTargetG;
    }

    public void setFatTargetG(BigDecimal fatTargetG) {
        this.fatTargetG = fatTargetG;
    }

    public BigDecimal getCarbsTargetG() {
        return carbsTargetG;
    }

    public void setCarbsTargetG(BigDecimal carbsTargetG) {
        this.carbsTargetG = carbsTargetG;
    }

    public LocalDate getEffectiveDate() {
        return effectiveDate;
    }

    public void setEffectiveDate(LocalDate effectiveDate) {
        this.effectiveDate = effectiveDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
