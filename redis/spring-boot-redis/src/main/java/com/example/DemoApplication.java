package com.example;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

import java.util.Set;
import java.util.UUID;

@SpringBootApplication
@EnableScheduling
public class DemoApplication implements CommandLineRunner {

    private static final Logger LOGGER = LoggerFactory.getLogger(DemoApplication.class);

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @Override
    public void run(String... args) {
        Set<String> keys = getKeys();
        LOGGER.info("############################################");
        LOGGER.info("Keys in cluster: {}", keys);
        LOGGER.info("############################################");
    }

    @Scheduled(fixedRate = 3000)
    public void manageRandomKey() {
        // Generate a random key using UUID
        String randomKey = "random:" + UUID.randomUUID().toString();
        String randomValue = "value-" + System.currentTimeMillis();

        // Create the key
        redisTemplate.opsForValue().set(randomKey, randomValue);
        LOGGER.info("Created key: {} with value: {}", randomKey, randomValue);

        // Log all keys before deletion
        Set<String> currentKeys = getKeys();
        LOGGER.info("############################################");
        LOGGER.info("All keys before deletion: {}", currentKeys);
        LOGGER.info("############################################");

        // Delete the key
        redisTemplate.delete(randomKey);
        LOGGER.info("Deleted key: {}", randomKey);
    }

    public Set<String> getKeys() {
        return redisTemplate.keys("*");
    }
}