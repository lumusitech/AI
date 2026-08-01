---
name: java-lts
description: Java 21 & 25 LTS features, idioms, performance tuning (ZGC, Loom), Record Patterns, Sequenced Collections, and Scoped Values.
version: 25.0.0
last_updated: 2026-08-01
---

# ☕ Java LTS (21 / 25) Developer Guide

This skill covers idioms, language features, and runtime configurations for modern Java LTS versions (Java 21 and Java 25).

## ⚡ Modern Java Language Features

### 1. Record Patterns & Switch Pattern Matching
```java
public sealed interface OrderEvent permits OrderCreated, OrderCancelled {}

public record OrderCreated(String orderId, double amount, Customer customer) implements OrderEvent {}
public record OrderCancelled(String orderId, String reason) implements OrderEvent {}
public record Customer(String name, String email) {}

public class EventProcessor {
    public String process(OrderEvent event) {
        return switch (event) {
            case OrderCreated(var id, var amount, Customer(var name, _)) when amount > 1000 ->
                "High value order " + id + " from " + name;
            case OrderCreated(var id, var amount, _) ->
                "Standard order " + id + " (" + amount + ")";
            case OrderCancelled(var id, var reason) ->
                "Order " + id + " cancelled: " + reason;
        };
    }
}
```

### 2. Sequenced Collections
Uniform methods for accessing first/last elements in ordered collections:
```java
List<String> list = new ArrayList<>(List.of("first", "middle", "last"));
String first = list.getFirst(); // "first"
String last = list.getLast();   // "last"
List<String> reversed = list.reversed();
```

### 3. Virtual Threads & Structured Concurrency
```java
public void processBatch(List<Task> tasks) {
    try (var scope = new StructuredTaskScope.ShutdownOnFailure()) {
        List<Supplier<Result>> futures = tasks.stream()
            .map(task -> scope.fork(() -> task.execute()))
            .toList();

        scope.join();           // Join all subtasks
        scope.throwIfFailed();  // Propagate errors if any subtask failed

        List<Result> results = futures.stream()
            .map(Supplier::get)
            .toList();
    } catch (Exception e) {
        throw new RuntimeException("Batch execution failed", e);
    }
}
```

### 4. Memory & Garbage Collection (ZGC / Generational ZGC)
For ultra-low latency applications (< 1ms pause time), configure Generational ZGC:
```bash
java -XX:+UseZGC -XX:+ZGenerational -jar app.jar
```
