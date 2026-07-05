package com.example.paymentsapi.repository;

import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
public class MerchantRepository {

    private final JdbcTemplate jdbcTemplate;

    public MerchantRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public boolean existsAndActive(String merchantId) {
        int count;
        String sql = """
                SELECT COUNT(*)
                FROM   merchants
                WHERE  merchant_id = ?
                AND    status      = 'ACTIVE'
                """;

        try {
            count = jdbcTemplate.queryForObject(sql, Integer.class, merchantId);
        } catch (DataAccessException e) {
            throw new IllegalStateException("Failed to execute SQL: " + sql, e);
        }

        return count > 0;
    }

}