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