package com.example.paymentsapi;

import com.example.paymentsapi.model.PaymentRequest;
import com.example.paymentsapi.model.PaymentResponse;
import com.example.paymentsapi.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.testng.AbstractTestNGSpringContextTests;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.DataProvider;
import org.testng.annotations.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
public class PaymentConcurrencyTest extends AbstractTestNGSpringContextTests {

    @Autowired
    private PaymentService paymentService;

    // Counters — thread-safe
    private final AtomicInteger successCount = new AtomicInteger(0);
    private final AtomicInteger failureCount = new AtomicInteger(0);

    private long startTime;

    @BeforeClass
    public void setUp() {
        startTime = System.currentTimeMillis();
        System.out.println("=== Concurrency test starting ===");
    }

    @AfterClass
    public void printSummary() {
        long elapsed = System.currentTimeMillis() - startTime;
        System.out.println("=== Concurrency test complete ===");
        System.out.printf("  Total requests : %d%n",
                successCount.get() + failureCount.get());
        System.out.printf("  Succeeded      : %d%n", successCount.get());
        System.out.printf("  Failed         : %d%n", failureCount.get());
        System.out.printf("  Total time     : %d ms%n", elapsed);
        System.out.printf("  Throughput     : %.1f req/sec%n",
                (successCount.get() + failureCount.get()) / (elapsed / 1000.0));
    }

    // ----------------------------------------------------------------
    // Test 1: Fire 500 requests in parallel, all valid merchants
    // ----------------------------------------------------------------
    @Test(description = "500 concurrent requests — all valid merchants")
    public void shouldHandleHighConcurrencyWithValidMerchants()
            throws ExecutionException, InterruptedException {

        int requestCount = 500;
        List<CompletableFuture<PaymentResponse>> futures = new ArrayList<>();

        for (int i = 0; i < requestCount; i++) {
            // Cycle through MERCH-01 to MERCH-10 to spread the load
            String merchantId = String.format("MERCH-%02d", (i % 10) + 1);
            String accountId  = String.format("ACC-%03d",  (i % 10) + 1);

            PaymentRequest request = buildRequest(accountId, merchantId);
            futures.add(paymentService.processRequest(request));
        }

        // Wait for all futures to complete
        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        // Assert every one succeeded
        for (CompletableFuture<PaymentResponse> future : futures) {
            PaymentResponse response = future.get();
            assertThat(response).isNotNull();
            assertThat(response.getDate()).matches("\\d{4}-\\d{2}-\\d{2}");
            successCount.incrementAndGet();
        }

        assertThat(successCount.get()).isEqualTo(requestCount);
    }

    // ----------------------------------------------------------------
    // Test 2: Mix of valid and invalid merchants — check error handling
    //         holds up under concurrency
    // ----------------------------------------------------------------
    @Test(description = "300 concurrent requests — mixed valid and invalid merchants",
            dependsOnMethods = "shouldHandleHighConcurrencyWithValidMerchants")
    public void shouldHandleMixedMerchantsUnderConcurrency() {

        int requestCount = 300;
        List<CompletableFuture<PaymentResponse>> futures = new ArrayList<>();

        for (int i = 0; i < requestCount; i++) {
            // Even index = valid merchant, odd = invalid
            boolean valid     = i % 2 == 0;
            String merchantId = valid ? String.format("MERCH-%02d", (i % 10) + 1)
                    : "MERCH-INVALID";
            String accountId  = valid ? String.format("ACC-%03d", (i % 10) + 1)
                    : "ACC-999";

            PaymentRequest request = buildRequest(accountId, merchantId);
            futures.add(
                    paymentService.processRequest(request)
                            .whenComplete((response, ex) -> {
                                if (ex != null) {
                                    failureCount.incrementAndGet();
                                } else {
                                    successCount.incrementAndGet();
                                }
                            })
            );
        }

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
                .exceptionally(ex -> null) // allow partial failures
                .join();

        System.out.printf("  Mixed test — succeeded: %d, failed: %d%n",
                successCount.get(), failureCount.get());

        // Half should succeed, half should fail with MerchantNotFoundException
        assertThat(successCount.get()).isGreaterThan(0);
        assertThat(failureCount.get()).isGreaterThan(0);
    }

    // ----------------------------------------------------------------
    // Test 3: DataProvider-driven — parameterised per merchant
    //         TestNG runs each row as a separate thread
    // ----------------------------------------------------------------
    @Test(description      = "One request per merchant — all 10 in parallel",
            dataProvider     = "merchantProvider",
            threadPoolSize   = 10,
            invocationCount  = 1)
    public void shouldProcessEachMerchantConcurrently(
            String merchantId, String accountId)
            throws ExecutionException, InterruptedException {

        PaymentRequest request = buildRequest(accountId, merchantId);

        PaymentResponse response = paymentService.processRequest(request).get();

        assertThat(response).isNotNull();
        assertThat(response.getDate()).isNotBlank();
        successCount.incrementAndGet();
    }

    @DataProvider(name = "merchantProvider", parallel = true)
    public Object[][] merchantProvider() {
        Object[][] data = new Object[10][2];
        for (int i = 0; i < 10; i++) {
            data[i][0] = String.format("MERCH-%02d", i + 1);
            data[i][1] = String.format("ACC-%03d",   i + 1);
        }
        return data;
    }

    // ----------------------------------------------------------------
    // Helper
    // ----------------------------------------------------------------
    private PaymentRequest buildRequest(String accountId, String merchantId) {
        PaymentRequest request = new PaymentRequest();
        request.setName("LoadTest-" + Thread.currentThread().getName());
        request.setMerchantId(merchantId);
        // Unique idempotency key per request — avoids DB constraint collision
        request.setIdempotencyKey(UUID.randomUUID().toString());
        return request;
    }

}