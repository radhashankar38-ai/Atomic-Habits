package com.example.habittracker;

public class Habit {
    private String name;
    private boolean isCompleted;

    public Habit(String name) {
        this.name = name;
        this.isCompleted = false;
    }
    public String getName() { return name; }
    public boolean isCompleted() { return isCompleted; }
    public void setCompleted(boolean completed) { isCompleted = completed; }
}
