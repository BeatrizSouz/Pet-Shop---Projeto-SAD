
/* ============================================================
   8. PROCEDIMENTO DE CARGA DA STAGING

   Recebe a data da carga por par�metro.

   Etapas:
   1. remove os registros da mesma data;
   2. mant�m os registros das outras cargas;
   3. extrai novamente os dados do OLTP.
   ============================================================ */

USE DW_Atendimentos;

GO

CREATE OR ALTER PROCEDURE staging.sp_carregar_staging
    @data_carga DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;

    DELETE FROM staging.stg_tipo_servico WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_filial WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_funcionario WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_tutor WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_pet WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_quadro_clinico WHERE data_carga = @data_carga;
    DELETE FROM staging.stg_atendimento WHERE data_carga = @data_carga;

    INSERT INTO staging.stg_tipo_servico (cod_tipo_servico, nome_tipo_servico, data_carga)
    SELECT cod_tipo_servico, nome_tipo_servico, @data_carga
    FROM oltp.tipo_servico;
    
    INSERT INTO staging.stg_filial (cod_filial,cidade,estado,nome_filial,data_carga)
    SELECT f.cod_filial, e.cidade, e.estado, f.nome_filial, @data_carga
    FROM oltp.filial f
    INNER JOIN oltp.endereco e
    ON f.cod_endereco = e.cod_endereco;

    INSERT INTO staging.stg_funcionario (cod_funcionario, cidade, estado,matricula, nome_funcionario, CRMV, data_carga)
    SELECT f.cod_funcionario, e.cidade, e.estado, f.matricula, f.nome_funcionario, f.CRMV,  @data_carga
    FROM oltp.funcionario f
    INNER JOIN oltp.endereco e
    ON f.cod_endereco = e.cod_endereco;

    INSERT INTO staging.stg_funcao (cod_funcao, cod_funcionario, funcao, data_carga)
    SELECT cod_funcao, cod_funcionario, funcao, @data_carga
    FROM oltp.funcao;

    Insert into staging.stg_tutor (cod_tutor, cpf, cidade,estado, nome_tutor, email, telefone, data_carga)
    SELECT t.cod_tutor, t.cpf, e.cidade, e.estado, t.nome_tutor, t.email, t.telefone, @data_carga
    FROM oltp.tutor t
    INNER JOIN oltp.endereco e
    ON t.cod_endereco = e.cod_endereco;

    Insert into staging.stg_pet (cod_pet, cod_tutor, nome, especie, raca, porte, sexo, data_carga)
    SELECT p.cod_pet, p.cod_tutor, p.nome, p.especie, p.raca, p.porte, p.sexo, @data_carga
    FROM oltp.pet p;

    Insert into staging.stg_quadro_clinico (cod_quadro_clinico, situacao_inicial, situacao_final, data_carga)
    SELECT cod_quadro_clinico, situacao_inicial, situacao_final, @data_carga
    FROM oltp.quadro_clinico;

    Insert into staging.stg_atendimento (cod_atendimento, cod_tipo_servico, cod_filial, cod_funcionario, cod_tutor, cod_pet, cod_quadro_clinico, data_inicio, data_fim, prioridade, valor, data_carga)
    SELECT a.cod_atendimento, a.cod_tipo_servico, a.cod_filial, a.cod_funcionario, a.cod_tutor, a.cod_pet, a.cod_quadro_clinico, a.data_inicio, a.data_fim, a.prioridade, ts.valor_servico, @data_carga
    FROM oltp.atendimento a
    INNER JOIN oltp.tipo_servico ts
    ON a.cod_tipo_servico = ts.cod_tipo_servico;
END;
GO

Exec staging.sp_carregar_staging '2026-07-18'

SELECT * from staging.stg_filial