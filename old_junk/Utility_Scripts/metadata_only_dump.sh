mysqldump -h <host> -u <user> -p emolt_dev --no-data > emolt_dev.sql
mysqldump -h <host> -u <user> -p emolt_dev --no-create-info --ignore-table=emolt_dev.TOWS --ignore-table=emolt_dev.TOWS_ENV --ignore-table=emolt_dev.TOWS_POINTS --ignore-table=emolt_dev.TOWS_SUMMARY --ignore-table=emolt_dev.TOW_SEGMENTS --ignore-table=emolt_dev.TOW_SENSORS >> emolt_dev.sql
