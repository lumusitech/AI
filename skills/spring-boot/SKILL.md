---
name: spring-boot
description: Enterprise Spring Boot 4.x / 3.5 LTS architecture, Virtual Threads (Project Loom), Spring AI, Declarative HTTP Clients, and Security best practices.
version: 4.0.0
last_updated: 2026-08-01
---

# 🍃 Spring Boot 4.x & 3.5 LTS Engineering Guide

This skill provides enterprise patterns for building high-performance, AI-ready Spring Boot microservices targeting Java 21/25 LTS.

## 🚀 Core Configuration & Performance Rules

### 1. Virtual Threads (Project Loom)
Always enable Virtual Threads by default in `application.properties`:
```properties
spring.threads.virtual.enabled=true
```

### 2. Spring AI Integration (LLMs & Vector DBs)
Use Spring AI starter abstractions for LLM interaction and vector search:
```java
@RestController
@RequestMapping("/api/v1/ai")
public class ChatController {

    private final ChatClient chatClient;
    private final VectorStore vectorStore;

    public ChatController(ChatClient.Builder chatClientBuilder, VectorStore vectorStore) {
        this.chatClient = chatClientBuilder.build();
        this.vectorStore = vectorStore;
    }

    @PostMapping("/query")
    public String query(@RequestBody String prompt) {
        List<Document> similarDocs = vectorStore.similaritySearch(prompt);
        String context = similarDocs.stream().map(Document::getContent).collect(Collectors.joining("\n"));

        return chatClient.prompt()
                .system("Responde usando el contexto provisto:\n" + context)
                .user(prompt)
                .call()
                .content();
    }
}
```

### 3. Declarative HTTP Clients (`@HttpExchange`)
Prefer declarative client interfaces instead of RestTemplate/WebClient:
```java
@HttpExchange("/api/v1/payments")
public interface PaymentClient {

    @GetExchange("/{id}")
    PaymentResponse getPayment(@PathVariable("id") String id);

    @PostExchange
    PaymentResponse createPayment(@RequestBody PaymentRequest request);
}

// Bean Configuration
@Configuration
public class ClientConfig {
    @Bean
    public PaymentClient paymentClient(RestClient.Builder builder) {
        RestClient restClient = builder.baseUrl("https://api.mercadopago.com").build();
        RestClientAdapter adapter = RestClientAdapter.create(restClient);
        HttpServiceProxyFactory factory = HttpServiceProxyFactory.builderFor(adapter).build();
        return factory.createClient(PaymentClient.class);
    }
}
```

### 4. Pragmatic Clean Architecture & Testing
- Keep controllers thin and place business rules inside domain services.
- Use Spring Security with stateless JWT or OAuth2 Resource Server configuration.
- Write slice unit tests using `@WebMvcTest` and integration tests with `@SpringBootTest` and `@Testcontainers`.
