-- =====================================================================
-- Desafio DIO: Integrando Dados com MySQL Azure e Transformando com Power BI
-- Script 1/3 — Criação do schema (DDL)
-- Baseado no banco COMPANY (Elmasri & Navathe), adaptado para MySQL/Azure.
-- =====================================================================

CREATE SCHEMA IF NOT EXISTS azure_company;
USE azure_company;

-- ---------------------------------------------------------------------
-- EMPLOYEE
-- ---------------------------------------------------------------------
CREATE TABLE employee (
    Fname      VARCHAR(15) NOT NULL,
    Minit      CHAR,
    Lname      VARCHAR(15) NOT NULL,
    Ssn        CHAR(9)     NOT NULL,
    Bdate      DATE,
    Address    VARCHAR(30),
    Sex        CHAR,
    Salary     DECIMAL(10,2),
    Super_ssn  CHAR(9),
    Dno        INT NOT NULL,
    CONSTRAINT pk_employee PRIMARY KEY (Ssn),
    CONSTRAINT chk_salary_employee CHECK (Salary > 2000.0)
);

-- Auto-relacionamento: cada funcionário pode ter outro funcionário como gerente.
ALTER TABLE employee
    ADD CONSTRAINT fk_employee_super
    FOREIGN KEY (Super_ssn) REFERENCES employee (Ssn)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

ALTER TABLE employee MODIFY Dno INT NOT NULL DEFAULT 1;

-- ---------------------------------------------------------------------
-- DEPARTAMENT
-- (mantido o nome "departament", igual à base original do desafio,
-- para não quebrar compatibilidade com o restante do material do curso)
-- ---------------------------------------------------------------------
CREATE TABLE departament (
    Dname             VARCHAR(15) NOT NULL,
    Dnumber           INT         NOT NULL,
    Mgr_ssn           CHAR(9)     NOT NULL,
    Mgr_start_date    DATE,
    Dept_create_date  DATE,
    CONSTRAINT pk_dept PRIMARY KEY (Dnumber),
    CONSTRAINT unique_name_dept UNIQUE (Dname),
    CONSTRAINT chk_date_dept CHECK (Dept_create_date < Mgr_start_date),
    CONSTRAINT fk_dept_mgr FOREIGN KEY (Mgr_ssn) REFERENCES employee (Ssn)
        ON UPDATE CASCADE
);
-- FIX: no script original a FK de Mgr_ssn nascia sem nome (auto-gerada
-- pelo MySQL, ex. "departament_ibfk_1") e depois era removida com
--   ALTER TABLE departament DROP departament_ibfk_1;
-- que é sintaxe inválida no MySQL para chave estrangeira (falta
-- "FOREIGN KEY" antes do nome da constraint). Aqui ela já nasce nomeada
-- (fk_dept_mgr) com ON UPDATE CASCADE, então o DROP/ADD deixou de ser necessário.

-- FIX: faltava a FK entre employee.Dno e departament.Dnumber. Só dá para
-- criá-la agora, depois que a tabela departament existe — por isso o
-- ALTER TABLE em vez de declará-la dentro do CREATE TABLE employee.
ALTER TABLE employee
    ADD CONSTRAINT fk_employee_dept
    FOREIGN KEY (Dno) REFERENCES departament (Dnumber)
    ON UPDATE CASCADE;

-- ---------------------------------------------------------------------
-- DEPT_LOCATIONS
-- ---------------------------------------------------------------------
CREATE TABLE dept_locations (
    Dnumber    INT         NOT NULL,
    Dlocation  VARCHAR(15) NOT NULL,
    CONSTRAINT pk_dept_locations PRIMARY KEY (Dnumber, Dlocation),
    CONSTRAINT fk_dept_locations FOREIGN KEY (Dnumber) REFERENCES departament (Dnumber)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
-- FIX: mesmo problema de sintaxe do DROP acima foi evitado aqui —
-- a constraint já nasce com nome e com ON DELETE/UPDATE CASCADE.

-- ---------------------------------------------------------------------
-- PROJECT
-- ---------------------------------------------------------------------
CREATE TABLE project (
    Pname      VARCHAR(15) NOT NULL,
    Pnumber    INT         NOT NULL,
    Plocation  VARCHAR(15),
    Dnum       INT         NOT NULL,
    CONSTRAINT pk_project PRIMARY KEY (Pnumber),
    CONSTRAINT unique_project UNIQUE (Pname),
    CONSTRAINT fk_project FOREIGN KEY (Dnum) REFERENCES departament (Dnumber)
);

-- ---------------------------------------------------------------------
-- WORKS_ON
-- ---------------------------------------------------------------------
CREATE TABLE works_on (
    Essn   CHAR(9)      NOT NULL,
    Pno    INT          NOT NULL,
    Hours  DECIMAL(3,1) NOT NULL,
    CONSTRAINT pk_works_on PRIMARY KEY (Essn, Pno),
    CONSTRAINT fk_employee_works_on FOREIGN KEY (Essn) REFERENCES employee (Ssn),
    CONSTRAINT fk_project_works_on FOREIGN KEY (Pno) REFERENCES project (Pnumber)
);

-- ---------------------------------------------------------------------
-- DEPENDENT
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS dependent;
-- FIX: o script original tinha "DROP TABLE dependent;" sem "IF EXISTS",
-- o que quebra com erro "Unknown table" na primeira execução em um
-- schema novo (a tabela nunca existiu para ser removida).
CREATE TABLE dependent (
    Essn            CHAR(9)     NOT NULL,
    Dependent_name  VARCHAR(15) NOT NULL,
    Sex             CHAR,
    Bdate           DATE,
    Relationship    VARCHAR(8),
    CONSTRAINT pk_dependent PRIMARY KEY (Essn, Dependent_name),
    CONSTRAINT fk_dependent FOREIGN KEY (Essn) REFERENCES employee (Ssn)
);

SHOW TABLES;
DESC employee;
DESC departament;
DESC dependent;
