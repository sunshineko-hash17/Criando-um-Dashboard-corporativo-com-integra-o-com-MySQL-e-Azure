-- =====================================================================
-- Desafio DIO: Integrando Dados com MySQL Azure e Transformando com Power BI
-- Script 3/3 — Consultas de transformação e análise
-- Numeração conforme as "Diretrizes para transformação dos dados" do
-- documento de instruções do desafio.
-- =====================================================================

USE azure_company;

-- ---- Diretriz 3 e 4: nulos e funcionários sem gerente ------------------
-- Super_ssn nulo é um nulo semântico, não um dado ausente: é quem está no
-- topo da hierarquia (o presidente). Esta consulta identifica quem é.
SELECT * FROM employee WHERE Super_ssn IS NULL;

-- ---- Diretriz 5 e 6: departamentos sem gerente --------------------------
-- Checagem de sanidade: com "Mgr_ssn NOT NULL" no schema, isso já é
-- impedido na origem; a query serve para validar cargas futuras.
SELECT * FROM departament WHERE Mgr_ssn IS NULL;

-- ---- Diretriz 7: número de horas dos projetos ---------------------------
-- Aloca fora do intervalo plausível de uma jornada (0 a 40h/semana no projeto)
SELECT * FROM works_on WHERE Hours < 0 OR Hours > 40;

-- Soma de horas por funcionário, para achar quem está sobrealocado no total
SELECT Essn, SUM(Hours) AS total_hours
FROM works_on
GROUP BY Essn
HAVING SUM(Hours) > 40;

-- ---- Diretriz 9 e 10: mesclar employee + departament, sem colunas extras
-- Base = employee -> LEFT JOIN (equivalente ao "Left Outer" no Power BI),
-- para preservar todo funcionário mesmo que o Dno não bata com nenhum
-- Dnumber. Dno é descartado do resultado porque Department_Name o substitui.
SELECT
    e.Ssn,
    e.Fname,
    e.Minit,
    e.Lname,
    e.Bdate,
    e.Address,
    e.Sex,
    e.Salary,
    e.Super_ssn,
    d.Dname AS Department_Name
FROM employee e
LEFT JOIN departament d ON e.Dno = d.Dnumber;

-- ---- Diretriz 11: nome do gerente de cada funcionário --------------------
-- Auto-junção (self join) de employee com employee via Super_ssn.
SELECT
    e.Ssn,
    e.Fname,
    e.Lname,
    s.Fname AS Manager_Fname,
    s.Lname AS Manager_Lname
FROM employee e
LEFT JOIN employee s ON e.Super_ssn = s.Ssn;

-- ---- Diretriz 12: mesclar Fname + Lname em uma única coluna ---------------
SELECT
    Ssn,
    CONCAT(Fname, ' ', Lname) AS Employee_Name
FROM employee;

-- ---- Diretriz 13: mesclar Dname + Dlocation (torna a combinação única) ---
SELECT
    d.Dnumber,
    CONCAT(d.Dname, ' - ', dl.Dlocation) AS Department_Location
FROM departament d
JOIN dept_locations dl ON d.Dnumber = dl.Dnumber;

-- ---- Diretriz 15: quantos colaboradores existem por gerente ---------------
SELECT
    s.Ssn AS Manager_Ssn,
    CONCAT(s.Fname, ' ', s.Lname) AS Manager_Name,
    COUNT(e.Ssn) AS Number_Of_Employees
FROM employee e
JOIN employee s ON e.Super_ssn = s.Ssn
GROUP BY s.Ssn, s.Fname, s.Lname;


-- =====================================================================
-- Consultas exploratórias originais do material de apoio (revisadas)
-- =====================================================================

SELECT * FROM employee;

SELECT Ssn, COUNT(Essn)
FROM employee e, dependent d
WHERE e.Ssn = d.Essn
GROUP BY Ssn;
-- FIX: faltava o GROUP BY. Sem ele, o MySQL 8 (modo ONLY_FULL_GROUP_BY,
-- ligado por padrão) rejeita misturar uma coluna não agregada (Ssn) com
-- uma função de agregação (COUNT) na mesma consulta.

SELECT * FROM dependent;

SELECT Bdate, Address FROM employee
WHERE Fname = 'John' AND Minit = 'B' AND Lname = 'Smith';

SELECT * FROM departament WHERE Dname = 'Research';

SELECT Fname, Lname, Address
FROM employee, departament
WHERE Dname = 'Research' AND Dnumber = Dno;

SELECT * FROM project;

-- Departamentos por localização
SELECT d.Dname AS Department, l.Dlocation, d.Mgr_ssn AS Manager
FROM departament d, dept_locations l
WHERE d.Dnumber = l.Dnumber;

-- Padrão SQL usaria || para concatenar; no MySQL usa-se CONCAT()
SELECT d.Dname AS Department, CONCAT(e.Fname, ' ', e.Lname) AS Manager
FROM departament d, dept_locations l, employee e
WHERE d.Dnumber = l.Dnumber AND d.Mgr_ssn = e.Ssn;

-- Projetos localizados em Stafford
SELECT * FROM project, departament WHERE Dnum = Dnumber AND Plocation = 'Stafford';

SELECT p.Pnumber, p.Dnum, e.Lname, e.Address, e.Bdate
FROM project p, departament d, employee e
WHERE p.Dnum = d.Dnumber AND d.Mgr_ssn = e.Ssn AND p.Plocation = 'Stafford';

SELECT * FROM employee WHERE Dno IN (3, 6, 9);
-- Nesta base os departamentos existentes são 1, 4 e 5 — é só um exemplo
-- de sintaxe do IN; com os dados atuais o retorno vem vazio.

-- Cálculo do INSS (1,1%) sobre o salário
SELECT Fname, Lname, Salary, ROUND(Salary * 0.011, 2) AS INSS FROM employee;

-- Aumento de 10% para quem trabalha no ProductX
SELECT e.Fname, e.Lname, 1.1 * e.Salary AS increased_sal
FROM employee e, works_on w, project p
WHERE e.Ssn = w.Essn AND w.Pno = p.Pnumber AND p.Pname = 'ProductX';

SELECT e.Fname, e.Lname, e.Address
FROM employee e, departament d
WHERE d.Dname = 'Research' AND d.Dnumber = e.Dno;

-- FIX: removidas duas consultas duplicadas do material original que
-- usavam aspas tipográficas (' ' em vez de ' ') coladas do Word/PowerPoint
-- e o nome de tabela "DEPARTMENT" (a tabela real chama-se "departament").
-- Ambas causavam erro de sintaxe / tabela inexistente no MySQL; o conteúdo
-- já está coberto pelas duas consultas equivalentes e corretas acima.
