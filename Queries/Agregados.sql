USE DW_Atendimentos

GO

CREATE OR ALTER PROCEDURE ag.sp_carregar_dimensao_tempo
AS
BEGIN 
SET NOCOUNT ON; 
    INSERT INTO ag.dim_tempo(
        id_tempo, 
        data_completa, 
        dia, 
        mes, 
        nome_mes, 
        trimestre, 
        ano, 
        numero_dia_semana, 
        nome_dia_semana
    )
    SELECT 
        t.id_tempo, 
        t.data_completa, 
        t.dia, 
        t.mes, 
        t.nome_mes, 
        t.trimestre, 
        t.ano, 
        t.numero_dia_semana, 
        t.nome_dia_semana 
    FROM dw.dim_tempo t
   
    WHERE NOT EXISTS (
        SELECT 1 
        FROM ag.dim_tempo destino 
        WHERE destino.data_completa = t.data_completa
    );
END;
GO

CREATE OR ALTER PROCEDURE ag.sp_carregar_dimensao_especie
AS
BEGIN 
SET NOCOUNT ON; 

    INSERT INTO ag.agregado_dim_especie(
        id_especie, 
        nome_especie
    )
    SELECT 
        esp.id_pet, 
        esp.especie
    FROM dw.dim_pet esp
END;
GO

CREATE OR ALTER PROCEDURE ag.sp_carregar_fato_especie
AS
BEGIN 
SET NOCOUNT ON; 

    INSERT INTO ag.agregado_fato_especie(
        id_data, 
        id_pet_especie,
        quantidade
    )
    SELECT 
        t.id_tempo,
        p.id_pet,
        sum(f.quantidade)
    FROM dw.fato_atendimento f
    JOIN dw.dim_tempo t on (f.id_tempo_inicio = t.id_tempo)
    JOIN dw.dim_pet p on (f.id_pet = p.id_pet)
    GROUP BY t.id_tempo, p.id_pet
END;
GO

EXEC ag.sp_carregar_fato_especie
select * from dw.fato_atendimento;

SELECT DISTINCT
    p.id_pet
FROM dw.fato_atendimento f
JOIN dw.dim_pet p
    ON f.id_pet = p.id_pet
EXCEPT
SELECT
    id_especie
FROM ag.agregado_dim_especie;