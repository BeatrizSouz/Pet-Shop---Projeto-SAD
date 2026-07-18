USE DW_Atendimentos

GO

CREATE or Alter Procedure dw.sp_procedimento_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
    DELETE FROM DW_Atendimentos.dw.dim_funcionario;
    DELETE FROM dw.dim_funcao; 
    DELETE FROM dw.dim_filial; 
    DELETE FROM dw.dim_tipo_servico;
    DELETE FROM dw.dim_tutor; 
    DELETE FROM dw.dim_turno; 
    DELETE FROM dw.dim_quadro_clinico;
    DELETE FROM dw.dim_pet; 
    DELETE FROM dw.fato_atendimento;
    
    /* Funcionario - Tipo 2*/
    
    Update df
    Set 
    	df.data_fim = @data_carga,
    	df.registro_atual = 0
    From DW_Atendimentos.dw.dim_funcionario df  
    Inner join staging.stg_funcionario stg ON  df.cod_funcionario = stg.cod_funcionario
    Where df.registro_atual = 1
    	and stg.data_carga = @data_carga
    	and (df.nome_funcionario <> stg.nome_funcionario
    		OR df.cidade <> stg.cidade
    		OR df.estado <> stg.estado
    		OR ISNULL(df.CRMV, '') <> ISNULL(stg.CRMV, ''));
    
    INSERT INTO DW_Atendimentos.dw.dim_funcionario (cod_funcionario, matricula, nome_funcionario, CRMV, cidade, estado, data_inicio, data_fim, registro_atual)
   	Select 
   		stg.cod_funcionario, stg.matricula, stg.nome_funcionario, stg.CRMV, stg.cidade, stg.estado,
    @data_carga AS data_inicio, NULL AS data_fim, 1 AS registro_atual
    FROM DW_Atendimentos.staging.stg_funcionario stg
    WHERE stg.data_carga = @data_carga
    	And NOT Exists (
    	Select 1 From dw.dim_funcionario df2
    	WHERE df2.cod_funcionario = stg.cod_funcionario AND df2.registro_atual = 1
    	);
    
    /* Serviço - Tipo 1 */
    
   	Merge dw.dim_tipo_servico as destino
   	Using (
   		Select cod_tipo_servico, nome_tipo_servico 
   		From staging.stg_tipo_servico 
   		WHERE data_carga = @data_carga
   	) AS origem
   	ON (destino.cod_tipo_servico = origem.cod_tipo_servico)
   	
   	When Matched and destino.nome_tipo_servico <> origem.nome_tipo_servico Then
   		Update set
   			destino.nome_tipo_servico = origem.nome_tipo_servico,
   			destino.data_atualizacao = @data_carga
   	
   	When Not Matched Then
   		Insert (cod_tipo_servico, nome_tipo_servico, data_atualizacao)
   		VALUES (origem.cod_tipo_servico, origem.nome_tipo_servico, @data_carga);
   	
END
Go

EXEC dw.sp_procedimento_dw '2026-07-18'

Select * from dw.dim_funcionario
