## Adapted from
## https://www.datadoghq.com/blog/monitoring-mysql-performance-metrics

## Query Throughput
SHOW GLOBAL STATUS 
WHERE 
  VARIABLE_NAME LIKE 'Questions'
  OR VARIABLE_NAME LIKE 'Com_select'
  OR VARIABLE_NAME LIKE 'Com_insert'
  OR VARIABLE_NAME LIKE 'Com_update'
  OR VARIABLE_NAME LIKE 'Com_delete';
  
## Query Performance
SELECT 
  schema_name, 
  SUM(count_star) count, 
  ROUND((SUM(sum_timer_wait)/SUM(count_star))/1000000) 
  AS avg_microsec
FROM 
  performance_schema.events_statements_summary_by_digest
WHERE 
  schema_name IS NOT NULL
GROUP BY 
  schema_name;
  
## Connection Status
SHOW GLOBAL STATUS 
WHERE 
  VARIABLE_NAME LIKE 'Threads_connected'
  OR VARIABLE_NAME LIKE 'Threads_running'
  OR VARIABLE_NAME LIKE 'Connection_errors_internal'
  OR VARIABLE_NAME LIKE 'Aborted_connects'
  OR VARIABLE_NAME LIKE 'Connection_errors_max_connections';
  
## Resource usage
SHOW processlist;

\! top