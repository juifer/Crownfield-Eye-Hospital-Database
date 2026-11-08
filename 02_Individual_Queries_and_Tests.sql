-- Crownfield Eye Hospital | Individual Queries and Tests
-- MySQL 8.4 | Fictional training data | Student 1
-- Prerequisite: run Crownfield_Eye_Hospital_Complete.sql first.
-- Run this file in MySQL Workbench. Test updates below are rolled back.
-- The main script also defines the procedure, trigger, and security roles;
-- this script recreates the procedure/trigger safely for independent review.
USE `crownfield_ro_pl_demo`;

-- Q1. GROUP BY + HAVING: Which clinicians have more than one appointment?
SELECT c.Clinician_ID,
       CONCAT(c.First_Name, ' ', c.Last_Name) AS Clinician,
       COUNT(a.Appointment_ID) AS Appointment_Count
FROM clinician AS c
JOIN appointment AS a ON a.Clinician_ID = c.Clinician_ID
GROUP BY c.Clinician_ID, c.First_Name, c.Last_Name
HAVING COUNT(a.Appointment_ID) > 1
ORDER BY Appointment_Count DESC, Clinician;

-- Q2. INNER JOIN across four tables: Which patients are booked with whom and where?
SELECT a.Appointment_ID,
       CONCAT(p.First_Name, ' ', p.Last_Name) AS Patient,
       CONCAT(c.First_Name, ' ', c.Last_Name) AS Clinician,
       cl.Clinic_Name, a.Appointment_Date
FROM appointment AS a
INNER JOIN patient AS p ON p.Patient_ID = a.Patient_ID
INNER JOIN clinician AS c ON c.Clinician_ID = a.Clinician_ID
INNER JOIN clinic AS cl ON cl.Clinic_ID = a.Clinic_ID
ORDER BY a.Appointment_Date, a.Appointment_ID;

-- Q3. LEFT JOIN: Which appointments have no follow-up record?
-- The IS NULL filter explicitly exposes optional/missing related data.
SELECT a.Appointment_ID, a.Appointment_Date, f.Follow_Up_ID
FROM appointment AS a
LEFT JOIN follow_up AS f ON f.Appointment_ID = a.Appointment_ID
WHERE f.Follow_Up_ID IS NULL
ORDER BY a.Appointment_ID;

-- Q4. Subquery: Which appointments have more prescription items than
-- the average number of items per prescription?
SELECT a.Appointment_ID, COUNT(pi.Prescription_Item_ID) AS Item_Count
FROM appointment AS a
JOIN prescription AS p ON p.Appointment_ID = a.Appointment_ID
JOIN prescription_item AS pi ON pi.Prescription_ID = p.Prescription_ID
GROUP BY a.Appointment_ID
HAVING COUNT(pi.Prescription_Item_ID) > (
    SELECT AVG(item_count)
    FROM (
        SELECT COUNT(pi2.Prescription_Item_ID) AS item_count
        FROM prescription AS p2
        JOIN prescription_item AS pi2 ON pi2.Prescription_ID = p2.Prescription_ID
        GROUP BY p2.Prescription_ID
    ) AS prescription_counts
)
ORDER BY Item_Count DESC, a.Appointment_ID;

-- Q5. Stored procedure with an input parameter: appointments for one patient.
DROP PROCEDURE IF EXISTS GetPatientAppointments;
DELIMITER $$
CREATE PROCEDURE GetPatientAppointments(IN p_patient_id VARCHAR(10))
BEGIN
    SELECT a.Appointment_ID, a.Appointment_Date, a.Appointment_Time,
           a.Status, cl.Clinic_Name
    FROM appointment AS a
    JOIN clinic AS cl ON cl.Clinic_ID = a.Clinic_ID
    WHERE a.Patient_ID = p_patient_id
    ORDER BY a.Appointment_Date, a.Appointment_Time;
END$$
DELIMITER ;
CALL GetPatientAppointments('OP001');

-- Q6. Trigger: audit appointment status changes.
-- The audit table is created in the main script; this guard makes the
-- individual script usable if the main script's audit extension was skipped.
CREATE TABLE IF NOT EXISTS appointment_status_audit (
    Audit_ID BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    Appointment_ID INT NOT NULL,
    Old_Status VARCHAR(20) NOT NULL,
    New_Status VARCHAR(20) NOT NULL,
    Changed_At TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_appointment FOREIGN KEY (Appointment_ID)
        REFERENCES appointment(Appointment_ID)
) ENGINE=InnoDB;

DROP TRIGGER IF EXISTS trg_appointment_status_audit;
DELIMITER $$
CREATE TRIGGER trg_appointment_status_audit
AFTER UPDATE ON appointment
FOR EACH ROW
BEGIN
    IF NOT (OLD.Status <=> NEW.Status) THEN
        INSERT INTO appointment_status_audit
            (Appointment_ID, Old_Status, New_Status)
        VALUES (NEW.Appointment_ID, OLD.Status, NEW.Status);
    END IF;
END$$
DELIMITER ;

-- Test the trigger without permanently changing the appointment or audit data.
START TRANSACTION;
SELECT Appointment_ID, Status AS Before_Status
FROM appointment WHERE Appointment_ID = 1;
UPDATE appointment
SET Status = CASE WHEN Status = 'Completed' THEN 'Scheduled'
                  ELSE 'Completed' END
WHERE Appointment_ID = 1;
SELECT Audit_ID, Appointment_ID, Old_Status, New_Status, Changed_At
FROM appointment_status_audit
WHERE Appointment_ID = 1
ORDER BY Audit_ID DESC;
ROLLBACK;
SELECT Appointment_ID, Status AS Restored_Status
FROM appointment WHERE Appointment_ID = 1;

-- T1. Transaction and rollback demonstration.
START TRANSACTION;
UPDATE appointment SET Status = 'Cancelled' WHERE Appointment_ID = 1;
SELECT Appointment_ID, Status AS Temporary_Status
FROM appointment WHERE Appointment_ID = 1;
ROLLBACK;
SELECT Appointment_ID, Status AS Restored_Status
FROM appointment WHERE Appointment_ID = 1;

-- T2. Foreign key verification: appointment 1 references an existing patient.
SELECT a.Appointment_ID, a.Patient_ID, p.Patient_ID AS Matching_Patient_ID
FROM appointment AS a
INNER JOIN patient AS p ON p.Patient_ID = a.Patient_ID
WHERE a.Appointment_ID = 1;

-- T3. Check current appointment status values (non-destructive).
SELECT Status, COUNT(*) AS Appointment_Count
FROM appointment
GROUP BY Status ORDER BY Status;

-- OPTIONAL NEGATIVE TESTS: run ONE statement at a time in Workbench.
-- They are intentionally commented out because each should raise an error.
-- Expected CHECK constraint error (3819):
-- UPDATE appointment SET Status = 'NotAValidStatus' WHERE Appointment_ID = 1;
-- Expected foreign key error (1452):
-- UPDATE appointment SET Patient_ID = 'INVALID999' WHERE Appointment_ID = 1;

-- Security inspection: SHOW GRANTS requires suitable privileges.
-- Run individually if permitted by your MySQL account:
-- SHOW GRANTS FOR 'crownfield_admin';
-- SHOW GRANTS FOR 'crownfield_doctor';
-- SHOW GRANTS FOR 'crownfield_receptionist';
-- SHOW GRANTS FOR 'crownfield_patient';
-- The role definitions and synthetic token-hashing demonstration are in
-- Crownfield_Eye_Hospital_Complete.sql and are not duplicated here.
