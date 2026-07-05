package com.example.paymentsapi.config;

import oracle.jdbc.pool.OracleDataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.sql.SQLException;
import java.util.Properties;

@Configuration
public class DataSourceConfig {

    @Value("${spring.datasource.url}")
    private String url;

    @Value("${spring.datasource.username}")
    private String username;

    @Value("${spring.datasource.password}")
    private String password;

    @Bean
    public DataSource dataSource() throws SQLException {
        OracleDataSource ds = new OracleDataSource();
        ds.setURL(url);
        ds.setUser(username);
        ds.setPassword(password);

        // Force a consistent date format for every session
        Properties connProps = new Properties();
        connProps.setProperty("oracle.jdbc.defaultNChar", "true");
        connProps.setProperty("NLS_DATE_FORMAT",      "YYYY-MM-DD");
        connProps.setProperty("NLS_TIMESTAMP_FORMAT", "YYYY-MM-DD HH24:MI:SS");
        ds.setConnectionProperties(connProps);

        return ds;
    }

    @Bean
    public JdbcTemplate jdbcTemplate(DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }

}