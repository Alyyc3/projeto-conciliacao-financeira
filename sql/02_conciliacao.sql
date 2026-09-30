-- Limpa versões anteriores (permite rodar o arquivo várias vezes)
DROP VIEW IF EXISTS v_lancamentos_status;
DROP VIEW IF EXISTS v_extrato_status;
DROP TABLE IF EXISTS conciliados;

-- 1) Pares conciliados: valor igual, tipo compatível, extrato até 3 dias depois
CREATE TABLE conciliados AS
WITH candidatos AS (
    SELECT
        l.id_lancamento,
        e.id_extrato,
        (e.data - l.data) AS dias_diferenca,
        ROW_NUMBER() OVER (
            PARTITION BY l.id_lancamento
            ORDER BY (e.data - l.data), e.id_extrato
        ) AS rn
    FROM lancamentos l
    JOIN extrato e
      ON e.valor = l.valor
     AND e.tipo = CASE l.tipo WHEN 'Receita' THEN 'Crédito' ELSE 'Débito' END
     AND e.data BETWEEN l.data AND l.data + 3
)
SELECT id_lancamento, id_extrato, dias_diferenca
FROM candidatos
WHERE rn = 1;

-- 2) Status de cada lançamento
CREATE VIEW v_lancamentos_status AS
SELECT
    l.*,
    c.id_extrato,
    c.dias_diferenca,
    CASE
        WHEN c.id_lancamento IS NULL THEN 'Sem extrato'
        WHEN c.dias_diferenca = 0    THEN 'Conciliado'
        ELSE 'Conciliado com defasagem'
    END AS status_conciliacao
FROM lancamentos l
LEFT JOIN conciliados c ON c.id_lancamento = l.id_lancamento;

-- 3) Status de cada linha do extrato
CREATE VIEW v_extrato_status AS
SELECT
    e.*,
    CASE WHEN c.id_extrato IS NULL THEN 'Sem lançamento' ELSE 'Conciliado' END AS status_conciliacao
FROM extrato e
LEFT JOIN (SELECT DISTINCT id_extrato FROM conciliados) c ON c.id_extrato = e.id_extrato;