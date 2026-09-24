# Criando-um-Dashboard-corporativo-com-integra-o-com-MySQL-e-Azure
Projeto do desafio de código da DIO: provisionar um banco MySQL no Azure, carregar a base COMPANY (Elmasri &amp; Navathe) e tratar os dados no Power BI antes de modelá-los em esquema estrela.
Estrutura do repositório
Arquivo	Conteúdo
01_schema.sql	DDL — criação do schema e das 6 tabelas, com chaves primárias, estrangeiras e checks
02_insercao_dados.sql	Carga inicial dos dados de exemplo
03_consultas.sql	Consultas de análise/transformação, mapeadas às diretrizes do desafio, + consultas exploratórias do material de apoio
README.md	Este arquivo

Os três scripts SQL corrigem uma série de bugs presentes nos arquivos originais do curso (aspas tipográficas, DROP de foreign key com sintaxe inválida, schema inconsistente entre os scripts, GROUP BY faltando, ordem de carga incompatível com as FKs). Cada correção está comentada no próprio script com uma marcação -- FIX:.

1–3. Provisionando o banco no Azure

Estes passos são feitos no portal do Azure e não podem ser reproduzidos aqui — resumo do fluxo para referência do README.

Criar o recurso: no portal do Azure, crie um Azure Database for MySQL – Flexible Server (o Single Server foi oficialmente aposentado pela Microsoft em setembro de 2024, então use Flexible Server mesmo que o vídeo do curso mostre o produto antigo).
Regra de firewall: em Networking, libere o IP público da sua máquina (e, se for testar do Cloud Shell, habilite "Allow public access from any Azure service" ou adicione a faixa de IPs do Cloud Shell).
Conectar:
Via Azure Cloud Shell: mysql -h <servidor>.mysql.database.azure.com -u <usuario> -p
Via MySQL Workbench: nova conexão com host, porta 3306, usuário e senha do servidor.
Rode 01_schema.sql, depois 02_insercao_dados.sql nessa conexão.
4. Integração com o Power BI

No Power BI Desktop: Página Inicial → Obter Dados → Banco de Dados MySQL, informe o host (<servidor>.mysql.database.azure.com) e porta 3306, escolha o modo de conectividade (Import ou DirectQuery) e selecione as tabelas employee, departament, dept_locations, project, works_on, dependent. Abra em Editor do Power Query antes de carregar, para aplicar as transformações abaixo.

Diretrizes de transformação — o que fazer e onde

O desafio permite resolver os itens 9, 11, 12 e 13 tanto em SQL quanto por mesclagem no Power Query — usei SQL nesses casos, com a query documentada abaixo, como o próprio enunciado sugere. Os demais itens são passos de limpeza que fazem mais sentido dentro do Power Query (eles dependem da interface do Power BI, não têm uma "query" única correspondente).

#	Diretriz	Onde resolver	Como
1	Verificar cabeçalhos e tipos de dados	Power Query	Ao importar, confira se o Power BI detectou Salary como número, as datas (Bdate, Mgr_start_date, Dept_create_date) como Date, e Ssn/Super_ssn/Essn como texto (são identificadores, não devem virar número — evita perda do zero à esquerda e somas sem sentido).
2	Monetários para double preciso	Power Query	Selecione a coluna Salary → Transformar → Tipo de Dados → Número Decimal Fixo (ou Decimal Number). Em M: Table.TransformColumnTypes(#"Origem", {{"Salary", type number}}).
3	Verificar nulos e avaliar remoção	Power Query / SQL	SELECT * FROM employee WHERE Super_ssn IS NULL; (script 03_consultas.sql) mostra que o único nulo em Super_ssn é o presidente — não remova essa linha, é um nulo válido (topo da hierarquia), não dado ausente.
4	Funcionários com Super_ssn nulo podem ser gerentes	SQL	Mesma query do item 3 — confirma que só James Borg não tem gerente.
5	Departamentos sem gerente	SQL	SELECT * FROM departament WHERE Mgr_ssn IS NULL; — retorna vazio, pois Mgr_ssn é NOT NULL no schema.
6	Preencher lacunas se houver depto sem gerente	—	Não se aplica a esta base (ver item 5); documentado para o caso de uma carga real apresentar esse cenário.
7	Verificar número de horas dos projetos	SQL	Duas queries em 03_consultas.sql: horas fora de 0–40 por linha, e soma de horas por funcionário acima de 40.
8	Separar colunas complexas	Power Query	Address vem como "731-Fondren-Houston-TX". Selecione a coluna → Dividir Coluna → Por Delimitador → "-" para obter Rua, Bairro, Cidade, Estado.
9	Mesclar employee + departament (nome do depto)	SQL	LEFT JOIN com base em employee (ver 03_consultas.sql) — precisa ser left e não inner porque a base é employee: todo funcionário deve aparecer no resultado, mesmo que (hipoteticamente) o Dno dele não bata com nenhum Dnumber.
10	Eliminar colunas desnecessárias nesse processo	SQL / Power Query	Na query do item 9, Dno já não aparece no SELECT — foi substituído por Department_Name.
11	Nome do gerente de cada funcionário	SQL	Auto-junção (self join) de employee com employee via Super_ssn = Ssn (ver 03_consultas.sql).
12	Mesclar Fname + Lname em uma coluna	SQL	CONCAT(Fname, ' ', Lname) AS Employee_Name.
13	Mesclar Dname + Dlocation (torna único)	SQL	JOIN entre departament e dept_locations, concatenando as duas colunas — cada linha resultante representa uma combinação departamento-local única, que vira a chave da futura dimensão no modelo estrela.
14	Por que mesclar e não anexar?	Conceitual	Anexar (Append) empilha linhas de tabelas com o mesmo conjunto de colunas (união vertical). Mesclar (Merge) combina colunas de duas tabelas diferentes casando linhas por uma chave em comum (junção horizontal, tipo JOIN). Aqui queremos trazer Dlocation para dentro de departament a partir de uma chave (Dnumber) — é um join, não uma união de linhas — por isso é mesclagem.
15	Agrupar para contar colaboradores por gerente	SQL	GROUP BY sobre a auto-junção do item 11, contando Ssn (ver 03_consultas.sql). Equivale a Agrupar Por no Power Query.
16	Eliminar colunas desnecessárias de cada tabela	Power Query	Depois das mesclagens, remova as colunas técnicas que sobraram (ex.: Dno, Super_ssn, Dnumber duplicados) em cada tabela antes de fechar o modelo — mantenha só o que alimenta os relatórios.
Observações sobre a base original

Durante a correção encontrei os seguintes problemas nos scripts fornecidos pelo curso (detalhes nos comentários -- FIX: de cada arquivo):

insercao_de_dados_e_queries_sql.sql fazia USE company_constraints;, um schema nunca criado — o 01_schema.sql cria azure_company, e os demais scripts foram ajustados para usar o mesmo nome.
A carga de employee falha com as FKs ativas: a coluna Super_ssn é auto-referenciada e alguns funcionários citam um gerente que só aparece em uma linha posterior do mesmo INSERT (ex.: John Smith cita Franklin Wong, inserido depois dele). A solução usada é a prática padrão para dados hierárquicos: SET FOREIGN_KEY_CHECKS = 0 só durante essa carga, reativando logo em seguida.
ALTER TABLE ... DROP departament_ibfk_1 (e o equivalente em dept_locations) usa sintaxe inválida para remover uma foreign key no MySQL — falta a palavra-chave FOREIGN KEY. No script corrigido, as constraints já nascem nomeadas, então esse DROP/ADD nem é mais necessário.
DROP TABLE dependent; sem IF EXISTS quebra em um schema novo.
Duas consultas no arquivo de queries usavam aspas tipográficas ('…', coladas de Word/PowerPoint) em vez de aspas retas, e uma delas referenciava a tabela DEPARTMENT (o nome real da tabela é departament) — ambas foram removidas por serem duplicatas quebradas de consultas já corretas no mesmo arquivo.
A consulta SELECT Ssn, COUNT(Essn) FROM employee e, dependent d WHERE e.Ssn = d.Essn não tinha GROUP BY; o MySQL 8 rejeita isso por padrão (ONLY_FULL_GROUP_BY).
Faltava a foreign key entre employee.Dno e departament.Dnumber — presente no modelo original de Elmasri & Navathe, mas ausente do script do curso. Foi adicionada via ALTER TABLE (só pode ser criada depois que departament existe).
Modelo de dados
employee (Ssn PK) ──┬── Super_ssn → employee.Ssn      (auto-relacionamento: gerente)
                     └── Dno → departament.Dnumber

departament (Dnumber PK) ── Mgr_ssn → employee.Ssn

dept_locations (Dnumber, Dlocation PK) ── Dnumber → departament.Dnumber

project (Pnumber PK) ── Dnum → departament.Dnumber

works_on (Essn, Pno PK) ──┬── Essn → employee.Ssn
                          └── Pno → project.Pnumber

dependent (Essn, Dependent_name PK) ── Essn → employee.Ssn
Próximos passos (modelo estrela)

Com as mesclagens dos itens 9, 11 e 13 aplicadas, a base fica pronta para um esquema estrela simples:

Fato: works_on (horas por funcionário/projeto)
Dimensões: employee (já com nome do departamento e do gerente), project, departament + dept_locations (mesclada)
