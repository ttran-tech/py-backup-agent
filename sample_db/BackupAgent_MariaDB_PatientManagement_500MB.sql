-- BackupAgent | Synthetic Dental Patient Management MariaDB benchmark
-- Based on *concepts and selected table names* in Open Dental 26.2 docs:
-- https://www.opendental.com/OpenDentalDocumentation26-2.html
-- NOT the official Open Dental schema; NOT suitable for importing into Open Dental.
-- Synthetic, non-identifying data; no actual patient information.
-- WARNING: DESTRUCTIVE only to the named test database below.
-- Expected InnoDB logical table size: approximately 500 MB, depending on MariaDB,
-- page allocation, character sets, indexes, compression and server settings.
-- The SQL file is compact because it generates hundreds of thousands of rows at import.
-- Client import: cmd /c "mariadb -u root -p < BackupAgent_MariaDB_PatientManagement_500MB.sql"
-- The importer must allow DELIMITER commands (MariaDB/mysql CLI, many SQL GUIs do).
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS backupagent_dental_500mb;
CREATE DATABASE backupagent_dental_500mb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE backupagent_dental_500mb;
SET SESSION foreign_key_checks=1;


CREATE TABLE `clinic` (ClinicNum INT PRIMARY KEY, Description VARCHAR(80) NOT NULL, City VARCHAR(50), State VARCHAR(2)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `provider` (ProvNum INT PRIMARY KEY, Abbr VARCHAR(12), FName VARCHAR(40), LName VARCHAR(40), ClinicNum INT, INDEX(ClinicNum), FOREIGN KEY (ClinicNum) REFERENCES clinic(ClinicNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `patient` (PatNum INT PRIMARY KEY, LName VARCHAR(70), FName VARCHAR(70), Birthdate DATE, Gender CHAR(1), HmPhone VARCHAR(18), Email VARCHAR(110), Address VARCHAR(110), City VARCHAR(55), State VARCHAR(2), Zip VARCHAR(12), ClinicNum INT NOT NULL, DateFirstVisit DATE, PatStatus VARCHAR(12), INDEX(LName,FName), INDEX(ClinicNum), FOREIGN KEY(ClinicNum) REFERENCES clinic(ClinicNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `operatory` (OperatoryNum INT PRIMARY KEY, OpName VARCHAR(45), ClinicNum INT, FOREIGN KEY (ClinicNum) REFERENCES clinic(ClinicNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `procedurecode` (CodeNum INT PRIMARY KEY, ProcCode VARCHAR(10), Descript VARCHAR(180), DefaultFee DECIMAL(10,2)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `insplan` (PlanNum INT PRIMARY KEY, CarrierName VARCHAR(75), GroupName VARCHAR(80), GroupNum VARCHAR(30)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `patplan` (PatPlanNum INT PRIMARY KEY, PatNum INT NOT NULL, PlanNum INT NOT NULL, OrdinalNo TINYINT, INDEX(PatNum), INDEX(PlanNum), FOREIGN KEY(PatNum) REFERENCES patient(PatNum), FOREIGN KEY(PlanNum) REFERENCES insplan(PlanNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `appointment` (AptNum INT PRIMARY KEY, PatNum INT NOT NULL, ProvNum INT NOT NULL, ClinicNum INT NOT NULL, OperatoryNum INT NOT NULL, AptDateTime DATETIME, AptStatus VARCHAR(20), Note VARCHAR(255), INDEX(PatNum), INDEX(AptDateTime), FOREIGN KEY(PatNum) REFERENCES patient(PatNum), FOREIGN KEY(ProvNum) REFERENCES provider(ProvNum), FOREIGN KEY(ClinicNum) REFERENCES clinic(ClinicNum), FOREIGN KEY(OperatoryNum) REFERENCES operatory(OperatoryNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `procedurelog` (ProcNum INT PRIMARY KEY, PatNum INT NOT NULL, AptNum INT NOT NULL, CodeNum INT NOT NULL, ProvNum INT NOT NULL, ProcDate DATE, ProcStatus VARCHAR(10), ProcFee DECIMAL(10,2), ToothNum VARCHAR(4), INDEX(PatNum), INDEX(AptNum), INDEX(ProcDate), FOREIGN KEY(PatNum) REFERENCES patient(PatNum), FOREIGN KEY(AptNum) REFERENCES appointment(AptNum), FOREIGN KEY(CodeNum) REFERENCES procedurecode(CodeNum), FOREIGN KEY(ProvNum) REFERENCES provider(ProvNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `procnote` (ProcNoteNum INT PRIMARY KEY, ProcNum INT NOT NULL, EntryDateTime DATETIME, Note LONGTEXT NOT NULL, INDEX(ProcNum), FOREIGN KEY(ProcNum) REFERENCES procedurelog(ProcNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `claim` (ClaimNum INT PRIMARY KEY, PatNum INT NOT NULL, PlanNum INT NOT NULL, DateService DATE, ClaimStatus CHAR(1), ClaimFee DECIMAL(10,2), InsPayEst DECIMAL(10,2), INDEX(PatNum), FOREIGN KEY(PatNum) REFERENCES patient(PatNum), FOREIGN KEY(PlanNum) REFERENCES insplan(PlanNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `claimproc` (ClaimProcNum INT PRIMARY KEY, ClaimNum INT NOT NULL, ProcNum INT NOT NULL, PatNum INT NOT NULL, FeeBilled DECIMAL(10,2), InsPayAmt DECIMAL(10,2), INDEX(ClaimNum), INDEX(ProcNum), FOREIGN KEY(ClaimNum) REFERENCES claim(ClaimNum), FOREIGN KEY(ProcNum) REFERENCES procedurelog(ProcNum), FOREIGN KEY(PatNum) REFERENCES patient(PatNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `payment` (PayNum INT PRIMARY KEY, PatNum INT NOT NULL, PayDate DATE, PayAmt DECIMAL(10,2), PayType VARCHAR(15), PayNote VARCHAR(160), INDEX(PatNum), FOREIGN KEY(PatNum) REFERENCES patient(PatNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `paysplit` (SplitNum INT PRIMARY KEY, PayNum INT NOT NULL, PatNum INT NOT NULL, ProcNum INT NOT NULL, SplitAmt DECIMAL(10,2), INDEX(PayNum), INDEX(ProcNum), FOREIGN KEY(PayNum) REFERENCES payment(PayNum), FOREIGN KEY(PatNum) REFERENCES patient(PatNum), FOREIGN KEY(ProcNum) REFERENCES procedurelog(ProcNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `document` (DocNum INT PRIMARY KEY, PatNum INT NOT NULL, FileName VARCHAR(140), DocCategory VARCHAR(25), DateCreated DATETIME, Description TEXT, INDEX(PatNum), FOREIGN KEY(PatNum) REFERENCES patient(PatNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `commlog` (CommlogNum INT PRIMARY KEY, PatNum INT NOT NULL, CommDateTime DATETIME, CommType VARCHAR(18), Note LONGTEXT NOT NULL, INDEX(PatNum), INDEX(CommDateTime), FOREIGN KEY(PatNum) REFERENCES patient(PatNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


CREATE TABLE `securitylog` (SecurityLogNum INT PRIMARY KEY, PatNum INT NOT NULL, LogDateTime DATETIME, LogSource VARCHAR(30), LogText LONGTEXT NOT NULL, INDEX(PatNum), INDEX(LogDateTime), FOREIGN KEY(PatNum) REFERENCES patient(PatNum)) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;


INSERT INTO clinic VALUES (1,'North Test Clinic','Testville','CA'),(2,'South Test Clinic','Testville','CA'),(3,'East Test Clinic','Sampleton','CA'),(4,'West Test Clinic','Sampleton','CA');
INSERT INTO provider VALUES (1,'DOC01','Alex','Morgan',1),(2,'DOC02','Taylor','Reed',2),(3,'DOC03','Casey','Quinn',3),(4,'DOC04','Jordan','Lane',4),(5,'HYG01','Robin','Hayes',1),(6,'HYG02','Jamie','Blake',2),(7,'HYG03','Avery','Chen',3),(8,'HYG04','Riley','Lee',4);
INSERT INTO operatory VALUES (1,'Chair 1',1),(2,'Chair 2',1),(3,'Chair 3',2),(4,'Chair 4',2),(5,'Chair 5',3),(6,'Chair 6',3),(7,'Chair 7',4),(8,'Chair 8',4);
INSERT INTO procedurecode VALUES (1,'D0120','Periodic oral evaluation',95.00),(2,'D0150','Comprehensive oral evaluation',160.00),(3,'D1110','Adult prophylaxis',140.00),(4,'D0274','Bitewing radiographs four images',110.00),(5,'D2391','Composite restoration one surface',220.00),(6,'D2740','Crown porcelain ceramic',1250.00),(7,'D4341','Periodontal scaling and root planing',290.00),(8,'D7140','Extraction erupted tooth',220.00);
INSERT INTO insplan VALUES (1,'Synthetic Dental Carrier A','Group A','TEST-001'),(2,'Synthetic Dental Carrier B','Group B','TEST-002'),(3,'Synthetic Dental Carrier C','Group C','TEST-003'),(4,'Self Pay Plan','Self Pay','TEST-004');
CREATE TABLE `_gen_sequence` (n INT NOT NULL PRIMARY KEY) ENGINE=MEMORY;
INSERT INTO `_gen_sequence` (n)
SELECT a.n + 10*b.n + 100*c.n FROM
(SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
CROSS JOIN
(SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
CROSS JOIN
(SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c;


DELIMITER $$
CREATE PROCEDURE `_seed_test_data`()
BEGIN
  DECLARE batch INT DEFAULT 0;
  DECLARE phase INT DEFAULT 1;
  DECLARE batches INT DEFAULT 0;
  WHILE phase <= 12 DO
    SET batch = 0;
    SET batches = CASE phase WHEN 1 THEN 20 WHEN 2 THEN 20 WHEN 3 THEN 60 WHEN 4 THEN 120 WHEN 5 THEN 80 WHEN 6 THEN 40 WHEN 7 THEN 60 WHEN 8 THEN 45 WHEN 9 THEN 45 WHEN 10 THEN 25 WHEN 11 THEN 55 WHEN 12 THEN 50 ELSE 0 END;
    WHILE batch < batches DO
      START TRANSACTION;
      CASE phase
      WHEN 1 THEN INSERT INTO patient SELECT n, CONCAT('PatientLast',LPAD(n,6,'0')), CONCAT('PatientFirst',LPAD(n,6,'0')), DATE_ADD('1950-01-01',INTERVAL MOD(n*37,25000) DAY), IF(MOD(n,2)=0,'F','M'), CONCAT('555-01',LPAD(MOD(n,10000),4,'0')), CONCAT('patient',n,'@example.invalid'), CONCAT(MOD(n,800),' Synthetic Street'), 'Testville','CA',LPAD(90000+MOD(n,9999),5,'0'),1+MOD(n,4),DATE_ADD('2018-01-01',INTERVAL MOD(n*11,3100) DAY),'Active' FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 2 THEN INSERT INTO patplan SELECT n, n, 1+MOD(n,4), 1 FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 3 THEN INSERT INTO appointment SELECT n,1+MOD(n*13,20000),1+MOD(n,8),1+MOD(n,4),1+MOD(n,8),DATE_ADD('2021-01-01 08:00:00',INTERVAL MOD(n*17,2000000) MINUTE),ELT(1+MOD(n,4),'Complete','Scheduled','Broken','Planned'),CONCAT('Generated scheduling record ',n) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 4 THEN INSERT INTO procedurelog SELECT n,1+MOD((1+MOD(n*7,60000))*13,20000),1+MOD(n*7,60000),1+MOD(n,8),1+MOD(n,8),DATE_ADD('2021-01-01', INTERVAL MOD(n*3,1800) DAY),IF(MOD(n,9)=0,'TP','C'),75+MOD(n*17,1500),CAST(1+MOD(n,32) AS CHAR) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 5 THEN INSERT INTO procnote SELECT n,1+MOD(n*7,120000),DATE_ADD('2022-01-01 08:00:00',INTERVAL MOD(n*29,1500000) MINUTE),LEFT(REPEAT(CONCAT('Synthetic clinical progress note. Patient evaluated and treatment details documented for backup benchmarking only. Medical history reviewed; diagnostic findings assessed; options, consent and follow-up instructions discussed. ',' Reference=',LPAD(n,9,'0'),'/',SUBSTRING(SHA2(CONCAT(n,'benchmark'),256),1,24),'. '),25),2550) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 6 THEN INSERT INTO claim SELECT n,1+MOD(n*19,20000),1+MOD(n,4),DATE_ADD('2022-01-01',INTERVAL MOD(n*7,1400) DAY),ELT(1+MOD(n,3),'R','S','W'),120+MOD(n*29,1800),80+MOD(n*13,900) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 7 THEN INSERT INTO claimproc SELECT n,1+MOD(n*7,40000),1+MOD(n*11,120000),1+MOD(n*19,20000),100+MOD(n*23,1200),70+MOD(n*17,700) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 8 THEN INSERT INTO payment SELECT n,1+MOD(n*17,20000),DATE_ADD('2022-01-01',INTERVAL MOD(n*5,1400) DAY),25+MOD(n*37,850),ELT(1+MOD(n,3),'Cash','Card','Check'),CONCAT('Synthetic payment transaction ',n) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 9 THEN INSERT INTO paysplit SELECT n,n,1+MOD(n*17,20000),1+MOD(n*11,120000),25+MOD(n*37,850) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 10 THEN INSERT INTO document SELECT n,1+MOD(n*13,20000),CONCAT('synthetic_',LPAD(n,8,'0'),'.pdf'),ELT(1+MOD(n,3),'Consent','Radiograph','Intake'),DATE_ADD('2021-01-01 08:00:00',INTERVAL MOD(n*47,2500000) MINUTE),LEFT(REPEAT(CONCAT('Synthetic document index. This references a pretend scanned form or radiographic image; actual binary imaging files would normally be handled separately. ',' Reference=',LPAD(n,9,'0'),'/',SUBSTRING(SHA2(CONCAT(n,'benchmark'),256),1,24),'. '),25),1800) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 11 THEN INSERT INTO commlog SELECT n,1+MOD(n*23,20000),DATE_ADD('2021-01-01 08:00:00',INTERVAL MOD(n*31,2600000) MINUTE),ELT(1+MOD(n,4),'Phone','Email','Text','Portal'),LEFT(REPEAT(CONCAT('Synthetic communication log. Appointment outreach and patient response recorded for testing. Contact preference, follow-up action and office scheduling notes captured. No real patient communications are represented. ',' Reference=',LPAD(n,9,'0'),'/',SUBSTRING(SHA2(CONCAT(n,'benchmark'),256),1,24),'. '),25),1800) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      WHEN 12 THEN INSERT INTO securitylog SELECT n,1+MOD(n*31,20000),DATE_ADD('2021-01-01 08:00:00',INTERVAL MOD(n*41,2600000) MINUTE),ELT(1+MOD(n,4),'Patient','Appointment','Billing','Document'),LEFT(REPEAT(CONCAT('Synthetic audit event. User action recorded; prior value and updated value were reviewed. Session origin, module, permission context and transaction reference are included for test purposes only. ',' Reference=',LPAD(n,9,'0'),'/',SUBSTRING(SHA2(CONCAT(n,'benchmark'),256),1,24),'. '),25),1300) FROM (SELECT batch*1000+s.n+1 AS n FROM _gen_sequence s) x;
      ELSE SET batch = batch;
      END CASE;
      COMMIT;
      SET batch = batch + 1;
    END WHILE;
    SET phase = phase + 1;
  END WHILE;
END$$
DELIMITER ;
CALL `_seed_test_data`();
DROP PROCEDURE `_seed_test_data`;
DROP TABLE `_gen_sequence`;


-- Per-table diagnostics. DATA_LENGTH+INDEX_LENGTH are InnoDB estimates (not dump size).
SELECT TABLE_NAME, TABLE_ROWS AS estimated_rows,
 ROUND((DATA_LENGTH+INDEX_LENGTH)/1024/1024,2) AS estimated_mb
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='backupagent_dental_500mb' ORDER BY (DATA_LENGTH+INDEX_LENGTH) DESC;
SELECT ROUND(SUM(DATA_LENGTH+INDEX_LENGTH)/1024/1024,2) AS estimated_database_mb
FROM information_schema.TABLES WHERE TABLE_SCHEMA='backupagent_dental_500mb';
SELECT 'patient' AS table_name, COUNT(*) AS exact_rows FROM patient
UNION ALL SELECT 'appointment',COUNT(*) FROM appointment
UNION ALL SELECT 'procedurelog',COUNT(*) FROM procedurelog
UNION ALL SELECT 'procnote',COUNT(*) FROM procnote
UNION ALL SELECT 'claim',COUNT(*) FROM claim
UNION ALL SELECT 'claimproc',COUNT(*) FROM claimproc
UNION ALL SELECT 'payment',COUNT(*) FROM payment
UNION ALL SELECT 'document',COUNT(*) FROM document
UNION ALL SELECT 'commlog',COUNT(*) FROM commlog
UNION ALL SELECT 'securitylog',COUNT(*) FROM securitylog;

