package com.example;

import lombok.extern.slf4j.Slf4j;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.redisson.spring.starter.RedissonAutoConfiguration;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/demo")
@Slf4j
@RefreshScope
public class RedissonController {
    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Autowired
    private RedissonClient redissonClient;

    @Value("${greeting.message1}")
    private String message1;
    @Value("${greeting.message2}")
    private String message2;
    @Value("${greeting.message3}")
    private String message3;
    @Value("${greeting.message4}")
    private String message4;
    @Value("${greeting.encryptedmessage}")
    private String encryptedmessage;

    @ResponseBody
    @RequestMapping("/lock")
    public String lock(@RequestParam("sid") String serverId) {
        Long counter = redisTemplate.opsForValue().increment("COUNTER", 1);
        RLock lock = redissonClient.getLock("TEST");
        try {
            lock.lock();
            log.info("Request Thread - " + counter + "[" + serverId + "] locked and begun...");
            Thread.sleep(5000); // 5 sec
            log.info("Request Thread - " + counter + "[" + serverId + "] ended successfully...");
        } catch (Exception ex) {
            log.error("Error occurred");
        } finally {
            lock.unlock();
            log.info("Request Thread - " + counter + "[" + serverId + "] unlocked...");
        }
        return "lock-" + counter + "[" + serverId + "]";
    }

    @GetMapping("/greetings")
    public ResponseEntity<Map> showGreeting(){
        Map<String, String> envVars = new HashMap<>();
        envVars.put("message1", message1);
        envVars.put("message2", message2);
        envVars.put("message3", message3);
        envVars.put("message4", message4);
        envVars.put("encryptedmessage", encryptedmessage);
        return ResponseEntity.ok(envVars);
    }
}
