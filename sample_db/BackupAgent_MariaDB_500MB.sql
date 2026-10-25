-- BackupAgent MariaDB test dataset: approximately 500 MiB of InnoDB data.
-- Import with: mariadb -u root -p < BackupAgent_MariaDB_100MB.sql
-- Intended for MariaDB on a LOCAL TEST SERVER only.
-- This script DROPS and recreates the named database.
-- On MariaDB versions with different InnoDB settings, physical size may vary.

DROP DATABASE IF EXISTS backupagent_test_500mb;
CREATE DATABASE backupagent_test_500mb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE backupagent_test_500mb;

CREATE TABLE patient_records (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    patient_code VARCHAR(24) NOT NULL,
    visit_date DATE NOT NULL,
    record_type VARCHAR(20) NOT NULL,
    note_body TEXT NOT NULL,
    PRIMARY KEY (id),
    KEY idx_visit_date (visit_date),
    KEY idx_patient_code (patient_code)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DELIMITER $$
CREATE PROCEDURE seed_backupagent_test()
BEGIN
    DECLARE i INT UNSIGNED DEFAULT 1;
    DECLARE chunk_start INT UNSIGNED;
    DECLARE payload TEXT;
    -- 3072 ASCII bytes per row; 160,000 records give ~469 MiB of note text.
    -- InnoDB row/page and index overhead generally brings total near 500 MiB.
    WHILE i <= 160000 DO
        SET chunk_start = i;
        START TRANSACTION;
        WHILE i < chunk_start + 500 AND i <= 160000 DO
            SET payload = REPEAT(SHA2(CONCAT('BackupAgent-testing-patient-',i,'-medical-note'),256),48);
            INSERT INTO patient_records (patient_code, visit_date, record_type, note_body)
            VALUES (CONCAT('PAT-',LPAD(i MOD 12000,6,'0')),
                    DATE_ADD('2020-01-01', INTERVAL (i MOD 2000) DAY),
                    CASE (i MOD 4) WHEN 0 THEN 'appointment' WHEN 1 THEN 'procedure'
                                   WHEN 2 THEN 'clinical_note' ELSE 'transaction' END,
                    payload);
            SET i = i + 1;
        END WHILE;
        COMMIT;
    END WHILE;
END$$
DELIMITER ;

CALL seed_backupagent_test();
DROP PROCEDURE seed_backupagent_test;

SELECT table_schema AS database_name,
       ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS estimated_mb
FROM information_schema.tables
WHERE table_schema = 'backupagent_test_500mb'
GROUP BY table_schema;
SELECT COUNT(*) AS rows_inserted FROM patient_records;
