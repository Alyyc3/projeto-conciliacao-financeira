-- 1) Taxa de conciliação
SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE status_conciliacao <> 'Sem extrato') / COUNT(*), 1) AS taxa_conciliacao_pct
FROM v_lancamentos_status;

-- 2) Pendências por mês (lançamentos sem extrato)
SELECT DATE_TRUNC('month', data)::date AS mes, COUNT(*) AS qtd, SUM(valor) AS valor_pendente
FROM v_lancamentos_status
WHERE status_conciliacao = 'Sem extrato'
GROUP BY 1
ORDER BY 1;

-- 3) Pendências por categoria
SELECT categoria, COUNT(*) AS qtd, SUM(valor) AS valor_pendente
FROM v_lancamentos_status
WHERE status_conciliacao = 'Sem extrato'
GROUP BY categoria
ORDER BY valor_pendente DESC;

-- 4) Extrato sem lançamento (tarifas, duplicidades, divergências)
SELECT descricao, COUNT(*) AS qtd, SUM(valor) AS total
FROM v_extrato_status
WHERE status_conciliacao = 'Sem lançamento'
GROUP BY descricao
ORDER BY total DESC;

-- 5) Divergências de valor: lançamento sem extrato x extrato sem lançamento,
--    mesma contraparte, até 3 dias e diferença de até R$ 50
SELECT l.id_lancamento, e.id_extrato, l.contraparte,
       l.valor AS valor_lancamento, e.valor AS valor_extrato,
       l.valor - e.valor AS diferenca
FROM v_lancamentos_status l
JOIN v_extrato_status e
  ON e.tipo = CASE l.tipo WHEN 'Receita' THEN 'Crédito' ELSE 'Débito' END
 AND e.data BETWEEN l.data AND l.data + 3
 AND ABS(e.valor - l.valor) BETWEEN 0.01 AND 50
 AND e.descricao LIKE '%' || UPPER(l.contraparte)
WHERE l.status_conciliacao = 'Sem extrato'
  AND e.status_conciliacao = 'Sem lançamento'
ORDER BY diferenca DESC;

-- 6) Fluxo de caixa diário com saldo acumulado
SELECT data,
       SUM(CASE WHEN tipo = 'Crédito' THEN valor ELSE -valor END) AS fluxo_dia,
       SUM(SUM(CASE WHEN tipo = 'Crédito' THEN valor ELSE -valor END)) OVER (ORDER BY data) AS saldo_acumulado
FROM extrato
GROUP BY data
ORDER BY data;

-- 7) Tempo médio de compensação por categoria (em dias)
SELECT categoria, ROUND(AVG(dias_diferenca), 2) AS media_dias
FROM v_lancamentos_status
WHERE dias_diferenca IS NOT NULL
GROUP BY categoria
ORDER BY media_dias DESC;