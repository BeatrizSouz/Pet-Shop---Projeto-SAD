/* ============================================================
   11. PROCEDIMENTO DA DIMENSÃO TEMPO

   A dimensão tempo não recebe a data da carga.

   Ela recebe:
   - data inicial;
   - data final.

   Exemplo:
   - 01/01/2026 até 31/12/2027.

   O procedimento:
   1. gera uma linha para cada dia do intervalo;
   2. insere apenas as datas ainda inexistentes;
   3. utiliza IDENTITY para gerar id_tempo.
   ============================================================ */

CREATE OR ALTER PROCEDURE dw.sp_carregar_dimensao_tempo
    @data_inicial DATE,
    @data_final DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_inicial IS NULL OR @data_final IS NULL
        THROW 50001, 'A data inicial e a data final devem ser informadas.', 1;

    IF @data_inicial > @data_final
        THROW 50002, 'A data inicial não pode ser maior que a data final.', 1;

    ;
    WITH
        cte_datas
        AS
        (
         SELECT @data_inicial AS data_atual
            UNION ALL
                SELECT DATEADD(DAY, 1, data_atual)
                FROM cte_datas
                WHERE data_atual < @data_final
        )
    INSERT INTO dw.dim_tempo
        (data_completa, dia, mes, nome_mes, trimestre, ano, numero_dia_semana, nome_dia_semana)
    SELECT
        datas.data_completa,
        DAY(datas.data_completa),
        MONTH(datas.data_completa),
        CASE MONTH(datas.data_completa)
            WHEN 1 THEN 'Janeiro'
            WHEN 2 THEN 'Fevereiro'
            WHEN 3 THEN 'Março'
            WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Maio'
            WHEN 6 THEN 'Junho'
            WHEN 7 THEN 'Julho'
            WHEN 8 THEN 'Agosto'
            WHEN 9 THEN 'Setembro'
            WHEN 10 THEN 'Outubro'
            WHEN 11 THEN 'Novembro'
            WHEN 12 THEN 'Dezembro'
        END,
        DATEPART(QUARTER, datas.data_completa),
        YEAR(datas.data_completa),
        DATEDIFF(DAY, '19000101', datas.data_completa) % 7 + 1,
        CASE DATEDIFF(DAY, '19000101', datas.data_completa) % 7
            WHEN 0 THEN 'Segunda-feira'
            WHEN 1 THEN 'Terça-feira'
            WHEN 2 THEN 'Quarta-feira'
            WHEN 3 THEN 'Quinta-feira'
            WHEN 4 THEN 'Sexta-feira'
            WHEN 5 THEN 'Sábado'
            WHEN 6 THEN 'Domingo'
        END
    FROM datas
    WHERE NOT EXISTS (
        SELECT 1
    FROM dw.dim_tempo destino
    WHERE destino.data_completa = datas.data_completa
    )
    OPTION
    (MAXRECURSION
    0);
END;