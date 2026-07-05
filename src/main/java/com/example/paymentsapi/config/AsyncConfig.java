package com.example.paymentsapi.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

@Configuration
@EnableAsync
public class AsyncConfig {

    @Bean(name = "paymentExecutor")
    public Executor paymentExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();

        // Core threads always alive and ready
        executor.setCorePoolSize(10);

        // Max threads under heavy load
        executor.setMaxPoolSize(50);

        // Queue size before new threads are spun up beyond core
        executor.setQueueCapacity(200);

        // Prefix for thread names — visible in logs and stack traces
        executor.setThreadNamePrefix("payment-worker-");

        // On shutdown, wait for in-flight tasks to finish
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(30);

        executor.initialize();
        return executor;
    }

}