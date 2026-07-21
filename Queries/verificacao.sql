/* ============================================================
JUSTIFICATIVA 1: REDUÇÃO DE VOLUME DE DADOS (I/O)
Comparando a quantidade de linhas armazenadas.
============================================================ */

SELECT 
    'Fato Detalhada' AS Tabela, 
    COUNT(*) AS Quantidade_Linhas,
    'Processa 1 linha por CADA atendimento realizado' AS Observacao
FROM dw.fato_atendimento

UNION ALL

SELECT 
    'Fato Agregada Espécie' AS Tabela, 
    COUNT(*) AS Quantidade_Linhas,
    'Processa apenas 1 linha por dia para cada Espécie' AS Observacao
FROM ag.agregado_fato_tipo_servico;


SELECT 
    'Fato Agregada Espécie' AS Tabela, 
    COUNT(*) AS Quantidade_Linhas,
    'Processa apenas 1 linha por dia para cada Espécie' AS Observacao
FROM ag.agregado_fato_filial;


/* 
O banco precisa ler MILHÕES de linhas, fazer join com a dimensão pet inteira 
e agrupar tudo em tempo de execução. 
*/
SELECT 
    t.ano,
    t.nome_mes,
    p.especie,
    SUM(f.quantidade) AS total_atendimentos
FROM dw.fato_atendimento f
INNER JOIN dw.dim_tempo t ON f.id_tempo_inicio = t.id_tempo
INNER JOIN dw.dim_pet p ON f.id_pet = p.id_pet
GROUP BY 
    t.ano,
    t.nome_mes,
    p.especie
ORDER BY 
    t.ano, t.nome_mes;

SELECT 
    t.ano,
    t.nome_mes,
    e.nome_especie,
    SUM(fa.quantidade) AS total_atendimentos
FROM ag.agregado_fato_especie fa
INNER JOIN ag.agregado_dim_tempo t ON fa.id_data = t.id_tempo_ag
INNER JOIN ag.agregado_dim_especie e ON fa.id_pet_especie = e.id_especie
GROUP BY 
    t.ano,
    t.nome_mes,
    e.nome_especie
ORDER BY 
    t.ano, t.nome_mes;