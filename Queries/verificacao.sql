/*Qual o número de atendimentos por Filial, por período?*/
SELECT 
    af.nome_filial,
    at.ano,
    at.nome_mes,
    SUM(ag_f.quantidade) AS total_atendimentos
FROM ag.agregado_fato_filial ag_f
INNER JOIN ag.agregado_dim_filial af ON ag_f.id_filial = af.id_filial
INNER JOIN ag.agregado_dim_tempo at ON ag_f.id_data = at.id_tempo_ag
GROUP BY af.nome_filial, at.ano, at.nome_mes
ORDER BY af.nome_filial, at.ano, at.nome_mes;

/*Qual o número de atendimentos por Tipo de Serviço?*/
SELECT 
    ads.nome_tipo_servico,
    SUM(ag_s.quantidade) AS total_atendimentos
FROM ag.agregado_fato_tipo_servico ag_s
INNER JOIN ag.agregado_dim_tipo_servico ads ON ag_s.id_servico = ads.id_servico
GROUP BY ads.nome_tipo_servico
ORDER BY total_atendimentos DESC;

/*Qual a distribuição de pets por Espécie (Cão, Gato, etc.)?*/
SELECT 
    ae.nome_especie,
    SUM(af_e.quantidade) AS total_atendimentos
FROM ag.agregado_fato_especie af_e
INNER JOIN ag.agregado_dim_especie ae ON af_e.id_pet_especie = ae.id_especie
GROUP BY ae.nome_especie
ORDER BY total_atendimentos DESC;

/*Quais são as top dez filiais com a maior quantidade de atendimento?*/
SELECT TOP 10
    af.nome_filial,
    SUM(ag_f.quantidade) AS total_atendimentos
FROM ag.agregado_fato_filial ag_f
INNER JOIN ag.agregado_dim_filial af ON ag_f.id_filial = af.id_filial
GROUP BY af.nome_filial
ORDER BY total_atendimentos DESC;

/*Qual o número de atendimentos por Turno (Manhã, Tarde, Noite)?*/
SELECT 
    dturno.turno,
    SUM(fa.quantidade) AS total_atendimentos
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_turno dturno ON fa.id_turno = dturno.id_turno
GROUP BY dturno.turno
ORDER BY total_atendimentos DESC;

/*Qual o número de atendimentos por Funcionário?*/
SELECT 
    dfunc.nome_funcionario,
    SUM(fa.quantidade) AS total_atendimentos
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_funcionario dfunc ON fa.id_funcionario = dfunc.id_funcionario
GROUP BY dfunc.nome_funcionario
ORDER BY total_atendimentos DESC;

/*Quais os tipos de serviços mais requisitados por Filial?*/
SELECT 
    df.nome_filial,
    ds.nome_tipo_servico,
    SUM(fa.quantidade) AS total_atendimentos
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_filial df ON fa.id_filial = df.id_filial
INNER JOIN dw.dim_tipo_servico ds ON fa.id_tipo_servico = ds.id_tipo_servico
GROUP BY df.nome_filial, ds.nome_tipo_servico
ORDER BY df.nome_filial, total_atendimentos DESC;

/*Qual filial possui mais atendimentos para cada serviço?*/
WITH RankFilialPorServico AS (
    SELECT 
        ds.nome_tipo_servico,
        df.nome_filial,
        SUM(fa.quantidade) AS total_atendimentos,
        ROW_NUMBER() OVER(PARTITION BY ds.nome_tipo_servico ORDER BY SUM(fa.quantidade) DESC) as ranking
    FROM dw.fato_atendimento fa
    INNER JOIN dw.dim_tipo_servico ds ON fa.id_tipo_servico = ds.id_tipo_servico
    INNER JOIN dw.dim_filial df ON fa.id_filial = df.id_filial
    GROUP BY ds.nome_tipo_servico, df.nome_filial
)
SELECT nome_tipo_servico, nome_filial, total_atendimentos
FROM RankFilialPorServico
WHERE ranking = 1;

/*Quais são os cinco clientes mais atendidos por período?*/
SELECT TOP 5
    dtutor.nome_tutor,
    dt.ano,
    dt.nome_mes,
    SUM(fa.quantidade) AS total_atendimentos
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_tutor dtutor ON fa.id_tutor = dtutor.id_tutor
INNER JOIN dw.dim_tempo dt ON fa.id_tempo_inicio = dt.id_tempo
GROUP BY dtutor.nome_tutor, dt.ano, dt.nome_mes
ORDER BY total_atendimentos DESC;

/*Quais são os cinco clientes mais atendidos por filial? Por qual período?*/
SELECT TOP 5
    df.nome_filial,
    dtutor.nome_tutor,
    dt.ano,
    dt.nome_mes,
    SUM(fa.quantidade) AS total_atendimentos
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_filial df ON fa.id_filial = df.id_filial
INNER JOIN dw.dim_tutor dtutor ON fa.id_tutor = dtutor.id_tutor
INNER JOIN dw.dim_tempo dt ON fa.id_tempo_inicio = dt.id_tempo
GROUP BY df.nome_filial, dtutor.nome_tutor, dt.ano, dt.nome_mes
ORDER BY total_atendimentos DESC;

/*Qual a distribuição de atendimentos por Porte do animal?*/
SELECT 
    dp.porte,
    SUM(fa.quantidade) AS total_atendimentos
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_pet dp ON fa.id_pet = dp.id_pet
GROUP BY dp.porte
ORDER BY total_atendimentos DESC;

/*Qual é o quadro clínico de um animal específico por período? (E sua evolução)*/
SELECT 
    dp.nome AS nome_pet,
    dp.especie,
    dt.data_completa,
    qc.situacao_inicial,
    qc.situacao_final
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_pet dp ON fa.id_pet = dp.id_pet
INNER JOIN dw.dim_quadro_clinico qc ON fa.id_quadro_clinico = qc.id_quadro_clinico
INNER JOIN dw.dim_tempo dt ON fa.id_tempo_inicio = dt.id_tempo
WHERE 
    dp.nome = 'Pudim' -- Substitua 'Pudim' pelo nome exato do pet
    AND dt.ano = 2026 -- Especifique o ano desejado
    -- AND dt.mes = 5 -- Descomente esta linha se quiser filtrar um mês específico
ORDER BY 
    dt.data_completa ASC;

/*Quantas vezes um animal voltou com o mesmo quadro clínico?*/
SELECT 
    dp.nome AS nome_pet,
    qc.situacao_inicial,
    COUNT(fa.id_atendimento) AS recorrencias
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_pet dp ON fa.id_pet = dp.id_pet
INNER JOIN dw.dim_quadro_clinico qc ON fa.id_quadro_clinico = qc.id_quadro_clinico
GROUP BY dp.nome, qc.situacao_inicial
HAVING COUNT(fa.id_atendimento) > 1
ORDER BY recorrencias DESC;

/*Quais doenças (quadros clínicos) são as mais recorrentes?*/
SELECT 
    qc.situacao_inicial,
    SUM(fa.quantidade) AS total_ocorrencias
FROM dw.fato_atendimento fa
INNER JOIN dw.dim_quadro_clinico qc ON fa.id_quadro_clinico = qc.id_quadro_clinico
GROUP BY qc.situacao_inicial
ORDER BY total_ocorrencias DESC;