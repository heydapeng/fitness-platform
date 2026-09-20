package com.dapeng.fitnesssystem.food.entity;

import com.dapeng.fitnesssystem.user.entity.User;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(
        name = "food_records",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_food_record_request",
                columnNames = {"user_id", "client_request_id"}
        ),
        indexes = {
                @Index(name = "idx_food_record_user_date", columnList = "user_id,record_date"),
                @Index(name = "idx_food_record_user_date_meal", columnList = "user_id,record_date,meal_type"),
                @Index(name = "idx_food_record_food", columnList = "food_id")
        }
)
public class FoodRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "food_id", nullable = false)
    private Food food;

    @Column(name = "record_date", nullable = false)
    private LocalDate recordDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "meal_type", nullable = false, length = 20)
    private MealType mealType;

    @Column(name = "weight_g", nullable = false, precision = 10, scale = 2)
    private BigDecimal weightG;

    @Column(name = "food_name_snapshot", nullable = false, length = 255)
    private String foodNameSnapshot;

    @Column(name = "calories_per_100g_snapshot", nullable = false, precision = 10, scale = 2)
    private BigDecimal caloriesPer100gSnapshot;

    @Column(name = "protein_per_100g_snapshot", nullable = false, precision = 10, scale = 2)
    private BigDecimal proteinPer100gSnapshot;

    @Column(name = "fat_per_100g_snapshot", nullable = false, precision = 10, scale = 2)
    private BigDecimal fatPer100gSnapshot;

    @Column(name = "carbs_per_100g_snapshot", nullable = false, precision = 10, scale = 2)
    private BigDecimal carbsPer100gSnapshot;

    @Column(name = "calories_actual", nullable = false, precision = 10, scale = 2)
    private BigDecimal caloriesActual;

    @Column(name = "protein_actual", nullable = false, precision = 10, scale = 2)
    private BigDecimal proteinActual;

    @Column(name = "fat_actual", nullable = false, precision = 10, scale = 2)
    private BigDecimal fatActual;

    @Column(name = "carbs_actual", nullable = false, precision = 10, scale = 2)
    private BigDecimal carbsActual;

    @Column(name = "client_request_id", nullable = false, length = 64)
    private String clientRequestId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected FoodRecord() {
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

    public Food getFood() {
        return food;
    }

    public void setFood(Food food) {
        this.food = food;
    }

    public LocalDate getRecordDate() {
        return recordDate;
    }

    public void setRecordDate(LocalDate recordDate) {
        this.recordDate = recordDate;
    }

    public MealType getMealType() {
        return mealType;
    }

    public void setMealType(MealType mealType) {
        this.mealType = mealType;
    }

    public BigDecimal getWeightG() {
        return weightG;
    }

    public void setWeightG(BigDecimal weightG) {
        this.weightG = weightG;
    }

    public String getFoodNameSnapshot() {
        return foodNameSnapshot;
    }

    public void setFoodNameSnapshot(String foodNameSnapshot) {
        this.foodNameSnapshot = foodNameSnapshot;
    }

    public BigDecimal getCaloriesPer100gSnapshot() {
        return caloriesPer100gSnapshot;
    }

    public void setCaloriesPer100gSnapshot(BigDecimal caloriesPer100gSnapshot) {
        this.caloriesPer100gSnapshot = caloriesPer100gSnapshot;
    }

    public BigDecimal getProteinPer100gSnapshot() {
        return proteinPer100gSnapshot;
    }

    public void setProteinPer100gSnapshot(BigDecimal proteinPer100gSnapshot) {
        this.proteinPer100gSnapshot = proteinPer100gSnapshot;
    }

    public BigDecimal getFatPer100gSnapshot() {
        return fatPer100gSnapshot;
    }

    public void setFatPer100gSnapshot(BigDecimal fatPer100gSnapshot) {
        this.fatPer100gSnapshot = fatPer100gSnapshot;
    }

    public BigDecimal getCarbsPer100gSnapshot() {
        return carbsPer100gSnapshot;
    }

    public void setCarbsPer100gSnapshot(BigDecimal carbsPer100gSnapshot) {
        this.carbsPer100gSnapshot = carbsPer100gSnapshot;
    }

    public BigDecimal getCaloriesActual() {
        return caloriesActual;
    }

    public void setCaloriesActual(BigDecimal caloriesActual) {
        this.caloriesActual = caloriesActual;
    }

    public BigDecimal getProteinActual() {
        return proteinActual;
    }

    public void setProteinActual(BigDecimal proteinActual) {
        this.proteinActual = proteinActual;
    }

    public BigDecimal getFatActual() {
        return fatActual;
    }

    public void setFatActual(BigDecimal fatActual) {
        this.fatActual = fatActual;
    }

    public BigDecimal getCarbsActual() {
        return carbsActual;
    }

    public void setCarbsActual(BigDecimal carbsActual) {
        this.carbsActual = carbsActual;
    }

    public String getClientRequestId() {
        return clientRequestId;
    }

    public void setClientRequestId(String clientRequestId) {
        this.clientRequestId = clientRequestId;
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
