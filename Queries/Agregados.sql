USE DW_Atendimentos;
GO


DROP PROCEDURE IF EXISTS ag.sp_carregar_agregado_dimensao_filial

DROP PROCEDURE IF EXISTS ag.sp_carregar_agregado_fato_filial

DROP PROCEDURE IF EXISTS ag.sp_carregar_agregado_dimensao_servico

DROP PROCEDURE IF EXISTS ag.sp_carregar_agregado_fato_servico

GO


DROP TABLE  IF EXISTS ag.agregado_fato_filial;

DROP TABLE IF EXISTS ag.agregado_fato_tipo_sevico;

DROP TABLE IF EXISTS ag.agregado_dim_filial;

DROP TABLE IF EXISTS ag.agregado_dim_tipo_servico;

GO


GO


Select * FROM dw.fato_atendimento
SELECT * FROM oltp.filial
SELECT * FROM staging.stg_filial
SELECT * FROM dw.dim_filial
SELECT * FROM dw.dim_funcao

EXEC ag.sp_carregar_agregado_dimensao_filial
EXEC ag.sp_carregar_agregado_dimensao_tempo
EXEC ag.sp_carregar_agregado_fato_filial
select * from ag.agregado_dim_tempo
select * from ag.agregado_dim_filial
select * from ag.agregado_fato_filial

SELECT * FROM dw.fato_atendimento
SELECT * FROM oltp.atendimento
SELECT * FROM staging.stg_atendimento