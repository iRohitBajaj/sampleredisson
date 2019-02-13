package com.example;

import lombok.extern.slf4j.Slf4j;
import org.redisson.Redisson;
import org.redisson.api.RedissonClient;
import org.redisson.config.Config;
import org.redisson.spring.starter.RedissonProperties;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.service.AbstractServiceConnectorCreator;
import org.springframework.cloud.service.ServiceConnectorConfig;
import org.springframework.cloud.service.common.RedisServiceInfo;
import org.springframework.context.ApplicationContext;
import org.springframework.core.io.Resource;

import java.io.IOException;
import java.io.InputStream;

@Slf4j
public class RedissonConnectorCreator extends AbstractServiceConnectorCreator<RedissonClient, RedisServiceInfo> {


    @Autowired
    private ApplicationContext ctx;

    @Autowired
    private RedissonProperties redissonProperties;

    @Value("${spring.redis.redisson.singleServerConfig.connectionMinimumIdleSize}")
    private int connectionMinimumIdleSize;


    @Override
    public RedissonClient create(RedisServiceInfo redisServiceInfo, ServiceConnectorConfig serviceConnectorConfig) {
        Config config = null;

        log.info("redisserviceinfo" + redisServiceInfo.toString());

        if (redissonProperties != null && redissonProperties.getConfig() != null) {
            log.info("redissonProperties.getConfig() : " + redissonProperties.getConfig());
            try {
                InputStream is = getConfigStream();
                config = Config.fromJSON(is);
            } catch (IOException e) {
                // trying next format
                try {
                    InputStream is = getConfigStream();
                    config = Config.fromYAML(is);
                } catch (IOException e1) {
                    throw new IllegalArgumentException("Can't parse config", e1);
                }
            }
        } else {
            config = new Config();
            String prefix = "redis://";

            config.useSingleServer()
                    .setAddress(prefix + redisServiceInfo.getHost() + ":" + redisServiceInfo.getPort())
                    .setPassword(redisServiceInfo.getPassword())
                    .setConnectionMinimumIdleSize(connectionMinimumIdleSize);
        }

        return Redisson.create(config);
    }

    private InputStream getConfigStream() throws IOException {
        Resource resource = ctx.getResource(redissonProperties.getConfig());
        InputStream is = resource.getInputStream();
        return is;
    }
}
