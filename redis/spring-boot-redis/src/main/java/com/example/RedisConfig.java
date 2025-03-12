package com.example;

import org.springframework.context.annotation.Configuration;
import org.springframework.boot.autoconfigure.data.redis.RedisProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.connection.RedisClusterConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import io.lettuce.core.ReadFrom;
import io.lettuce.core.cluster.ClusterClientOptions;
import io.lettuce.core.cluster.ClusterTopologyRefreshOptions;

import java.time.Duration;

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

        // Configure Redis Cluster
        RedisClusterConfiguration clusterConfig = new RedisClusterConfiguration(redisProperties.getCluster().getNodes());
        if (redisProperties.getPassword() != null) {
            clusterConfig.setPassword(redisProperties.getPassword());
        }

        // Configure topology refresh options
        ClusterTopologyRefreshOptions topologyRefreshOptions = ClusterTopologyRefreshOptions.builder()
            .enablePeriodicRefresh(Duration.ofSeconds(60)) // Refresh topology every 60 seconds
            .enableAllAdaptiveRefreshTriggers()           // Refresh on MOVED, ASK, or other triggers
            .build();

        // Apply topology refresh to cluster client options
        ClusterClientOptions clusterClientOptions = ClusterClientOptions.builder()
            .topologyRefreshOptions(topologyRefreshOptions)
            .build();

        // Build Lettuce client configuration with topology refresh
        LettuceClientConfiguration clientConfig = LettuceClientConfiguration.builder()
            .clientOptions(clusterClientOptions)       // Set client options first
            .commandTimeout(Duration.ofSeconds(10))    // Set timeout before SSL
            .readFrom(ReadFrom.REPLICA_PREFERRED)      // Then read preference
            .useSsl()                                  // SSL last
            .build();

        // Create and return the connection factory
        return new LettuceConnectionFactory(clusterConfig, clientConfig);
    }
}