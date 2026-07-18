
/* ============================================================
   8. PROCEDIMENTO DE CARGA DA STAGING

   Recebe a data da carga por par�metro.

   Etapas:
   1. remove os registros da mesma data;
   2. mant�m os registros das outras cargas;
   3. extrai novamente os dados do OLTP.
   ============================================================ */

   
CREATE OR ALTER PROCEDURE staging.sp_carregar_staging
    @data_carga DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;

 /* Remove somente os registros da carga que ser� reprocessada. */

    DELETE FROM staging.stg_tipo_servico WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_filial WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_funcionario WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_tutor WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_pet WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_quadro_clinico WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_atendimento WHERE data_carga = @data_carga;

     /* Extrai os tipos de servi�o do ambiente operacional. */

    INSERT INTO staging.stg_tipo_servico (cod_tipo_servico,nome_tipo_servico,data_carga)
    SELECT cod_tipo_servico, nome_tipo_servico,@data_carga
    FROM oltp.tipo_servico;

     /* Extrai a filial do ambiente operacional. */
    
    INSERT INTO staging.stg_filial (cod_filial,cidade,estado,nome_filial,data_carga)
    SELECT f.cod_filial,e.cidade,e.estado,f.nome_filial,@data_carga
    FROM oltp.filial f
    INNER JOIN oltp.endereco e
    ON f.cod_endereco = e.cod_endereco;

    /* Extrai os funcion�rio do ambiente operacional. */

    INSERT INTO staging.stg_funcionario (cod_funcionario,cidade,estado,matricula,nome_funcionario,CRMV,data_carga)
    SELECT f.cod_funcionario,e.cidade,e.estado,f.matricula,f.nome_funcionario,f.CRMV, @data_carga
    FROM oltp.funcionario f
    INNER JOIN oltp.endereco e
    ON f.cod_endereco = e.cod_endereco;

     /* Extrai as fun��es do ambiente operacional. */

    INSERT INTO staging.stg_funcao (cod_funcao,nome_tipo_servico,data_carga)
    SELECT cod_tipo_servico, nome_tipo_servico,@data_carga
    FROM oltp.tipo_servico;
    
END;
GO