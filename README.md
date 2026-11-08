# Crownfield Eye Hospital Database

A MySQL 8.4 relational database project for a **fictional eye hospital**, developed for the *Introduction to Database* assignment. The project models patients, clinicians, clinics, appointments, diagnoses, prescriptions, medicines and follow-up care, with additional demonstrations of database auditing and access control.

> **Educational project:** All records are fictional. Do not use this database for real patient information.

## Repository contents

| File | Purpose |
| --- | --- |
| `Crownfield_Eye_Hospital_Complete.sql` | Main database script: schema, sample records, constraints, queries, stored procedure, trigger, roles and security demonstrations. |
| `02_Individual_Queries_and_Tests.sql` | Student 1's six individual SQL features and additional integrity/transaction tests. |
| `Crownfield_Eye_Hospital_ERD.png` | ER diagram for viewing in the repository or report. |
| `Crownfield_Eye_Hospital_ERD.svg` | Scalable version of the ER diagram. |
| `README.md` | Project overview and execution instructions. |

## Database design

The project uses the schema `crownfield_ro_pl_demo`.

The **10 core hospital tables** are:

- `patient`
- `clinician`
- `specialty`
- `clinic`
- `appointment`
- `diagnosis`
- `follow_up`
- `prescription`
- `prescription_item`
- `medicine`

Two **additional demonstration tables** are created by the main script:

- `appointment_status_audit` — records changes to appointment status through a trigger.
- `demo_protected_token` — stores a SHA-256 hash of a fictional training token to demonstrate one-way hashing.

The complete script defines **12 tables in total** after its extensions run. The ER diagram includes the core tables and both extension tables.

## Requirements

- MySQL Server **8.4** (the version used for the project).
- MySQL Workbench or another compatible MySQL client.
- A MySQL account with sufficient privileges to create databases, tables, routines, triggers and roles, and to grant privileges.

## How to run

**Warning:** The main SQL file is intended for a **dedicated local test environment**. It contains `DROP TABLE` statements and may overwrite existing project data. Back up anything important and do not run it against a production database.

1. Open MySQL Workbench and connect to your local MySQL server.
2. Open `Crownfield_Eye_Hospital_Complete.sql`.
3. Execute the script **first**. It creates and populates the database and defines the supporting objects.
4. Open `02_Individual_Queries_and_Tests.sql`.
5. Execute this script **second**. It selects `crownfield_ro_pl_demo`, runs the individual queries and demonstrates tests.
6. Review the result grids and messages in Workbench. The deliberately invalid constraint tests are commented out; run them separately only if you want to observe the expected errors.

The individual script recreates the stored procedure and trigger using `DROP ... IF EXISTS` so they can be reviewed independently. Its demonstration updates are enclosed in transactions followed by `ROLLBACK`.

## Individual SQL features (Student 1)

| Feature | Demonstration |
| --- | --- |
| `GROUP BY` and `HAVING` | Find clinicians with more than one appointment. |
| Multi-table `INNER JOIN` | Show appointments with patient, clinician and clinic details. |
| `LEFT JOIN` | Find appointments without a follow-up record. |
| Subquery | Compare prescription-item counts against the average per prescription. |
| Stored procedure | `GetPatientAppointments(IN p_patient_id VARCHAR(10))`, demonstrated with `CALL GetPatientAppointments('OP001');`. |
| Trigger | `trg_appointment_status_audit` records changes to appointment status in `appointment_status_audit`. |

### Additional testing

The individual script also demonstrates transaction rollback, foreign-key verification and appointment-status inspection. Optional negative tests illustrate an invalid appointment status (`CHECK` constraint) and a non-existent patient reference (foreign-key constraint). These tests are **commented out by default** because successful constraint enforcement raises an error.

## Security demonstrations

The main script defines four MySQL **roles**: `crownfield_admin`, `crownfield_doctor`, `crownfield_receptionist` and `crownfield_patient`, with different permissions. These are role definitions, **not individual login accounts**. It also demonstrates hashing a fictional token. This is a teaching example, not a complete production authentication or patient-data encryption system.

## Notes on verification

The scripts and ER diagram are intended to be reviewed together. Running the scripts successfully on your own MySQL instance is the final execution check; the presence of code in this repository alone does not prove successful execution.

## Academic submission

The individual report provides the design rationale, SQL results, screenshots, security discussion and evaluation. This repository supplies the supporting SQL scripts and ER diagram.
