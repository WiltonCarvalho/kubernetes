package com.example;

import org.springframework.context.annotation.Configuration;
import org.springframework.boot.autoconfigure.data.redis.RedisProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.connection.RedisClusterConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import io.lettuce.core.ReadFrom;

@Configuration
public class RedisConfig {
    private final RedisProperties redisProperties;

    public RedisConfig(RedisProperties redisProperties) {
        this.redisProperties = redisProperties;
    }

    @Bean
    public LettuceConnectionFactory redisConnectionFactory() {
        if (redisProperties.getCluster() == null || redisProperties.getCluster().getNodes() == null) {
            throw new IllegalStateException("Redis cluster nodes are not configured. Please check your application properties.");
        }

        RedisClusterConfiguration clusterConfig = new RedisClusterConfiguration(redisProperties.getCluster().getNodes());
        if (redisProperties.getPassword() != null) {
            clusterConfig.setPassword(redisProperties.getPassword());
        }
        LettuceClientConfiguration clientConfig = LettuceClientConfiguration.builder()
                .readFrom(ReadFrom.REPLICA_PREFERRED)
                .useSsl()
                .build();

        return new LettuceConnectionFactory(clusterConfig, clientConfig);
    }
}
