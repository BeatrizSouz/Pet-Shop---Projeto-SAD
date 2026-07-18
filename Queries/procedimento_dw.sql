USE DW_Atendimentos

GO

CREATE or Alter Procedure dw.sp_procedimento_dimensoes_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
    DELETE FROM DW_Atendimentos.dw.dim_funcionario;
    DELETE FROM dw.dim_tipo_servico;
    
    DELETE FROM dw.dim_quadro_clinico;
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

CREATE or Alter Procedure dw.sp_procedimento_dimensao_funcao_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
    DELETE FROM dw.dim_funcao; 
    
    /* Função - Tipo 1*/
    
    Merge dw.dim_funcao as destino
    Using (
    	Select funcao
    	From staging.stg_funcao
    	Where data_carga = @data_carga
    ) As origem
    ON(destino.funcao= origem.funcao)
    
    When Matched and destino.funcao <> origem.funcao Then
    	Update set
    		destino.funcao = origem.funcao,
    		destino.data_atualizacao = @data_carga
    
	When Not Matched Then
		Insert (funcao, data_atualizacao)
		Values (origem.funcao, @data_carga);
END

Go
CREATE or Alter Procedure dw.sp_procedimento_dimensao_filial_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
    DELETE FROM dw.dim_filial; 
    
    /* Filial - Tipo 2*/
    
    Update df
    Set	
    	df.data_fim = @data_carga,
    	df.registro_atual = 0
    From DW_Atendimentos.dw.dim_filial df 
    Inner JOIN DW_Atendimentos.staging.stg_filial fi on df.cod_filial = fi.cod_filial
    Where df.registro_atual = 1
    	and fi.data_carga = @data_carga
    	and (df.cidade <> fi.cidade
    		or df.estado <> fi.estado
    		or df.nome_filial <> fi.nome_filial);
    
    Insert INTO DW_Atendimentos.dw.dim_filial (cod_filial, cidade, estado, nome_filial, data_inicio, data_fim, registro_atual)
    SELECT	stg.cod_filial, stg.cidade, stg.estado, stg.nome_filial, @data_carga as data_inicio, NULL as data_fim, 1 as registro_atual
    FROM DW_Atendimentos.staging.stg_filial stg
    Where stg.data_carga = @data_carga
    	And Not Exists (
    	Select 1 From DW_Atendimentos.dw.dim_filial df2
    	Where df2.cod_filial = stg.cod_filial and df2.registro_atual = 1
    	);
END

Go

CREATE or Alter Procedure dw.sp_procedimento_dimensoes_pet_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
     
    DELETE FROM dw.dim_pet; 
   	
    /* Pet - Tipo 2*/
    
    Update pet
    Set 
    	pet.data_fim = @data_carga,
    	pet.registro_atual = 0
    From DW_Atendimentos.dw.dim_pet pet
    Inner Join DW_Atendimentos.staging.stg_pet sp on pet.cod_pet = sp.cod_pet 
    WHERE pet.registro_atual = 1
    	and sp.data_carga = @data_carga
    	and (pet.cod_pet <> sp.cod_pet
    		or pet.nome <> sp.nome
    		or pet.especie <> sp.especie
    		or pet.raca <> sp.raca
    		or pet.porte <> sp.porte
    		or pet.sexo <> sp.sexo);
	
    Insert Into DW_Atendimentos.dw.dim_pet (cod_pet, nome, especie, raca, porte, sexo, data_inicio, data_fim, registro_atual)
    SELECT sp.cod_pet, sp.nome, sp.especie, sp.raca, sp.porte, sp.sexo, @data_carga as data_inicio, NULL as data_fim, 1 as registro_atual
    FROM DW_Atendimentos.staging.stg_pet sp 
    where sp.data_carga = @data_carga
    	and not EXISTS (
    		Select 1 From DW_Atendimentos.dw.dim_pet dp 
    		where dp.cod_pet = sp.cod_pet and dp.registro_atual = 1
    	);
End

Go

CREATE or Alter Procedure dw.sp_procedimento_dimensoes_tutor_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
    DELETE FROM dw.dim_tutor;
	
    Update dt
    Set 
    	dt.data_fim = @data_carga,
    	dt.registro_atual = 0
    From DW_Atendimentos.dw.dim_tutor dt 
    Inner Join DW_Atendimentos.staging.stg_tutor st on dt.cod_tutor = st.cod_tutor 
    Where dt.registro_atual = 1
    	And st.data_carga = @data_carga
    	and (dt.cod_tutor = st.cod_tutor
    		or dt.cpf = st.cpf
    		or dt.cidade = st.cidade
    		or dt.estado = st.estado
    		or dt.nome_tutor = st.email
    		or dt.email = st.email
    		or dt.telefone = st.telefone);
   	
    Insert Into DW_Atendimentos.dw.dim_tutor (cod_tutor, cpf, cidade, estado, nome_tutor, email, telefone, data_inicio, data_fim, registro_atual)
    Select stg.cod_tutor, stg.cpf, stg.cidade, stg.estado, stg.nome_tutor, stg.email, stg.telefone, @data_carga as data_inicio, Null as data_fim, 1 as registro_atual
    From DW_Atendimentos.staging.stg_tutor stg
    Where stg.data_carga = @data_carga
    	and not Exists (
    		Select 1 from DW_Atendimentos.dw.dim_tutor dt
    		where dt.cod_tutor = stg.cod_tutor and dt.registro_atual = 1
    	);
End

Go
    
CREATE or Alter Procedure dw.sp_procedimento_dimensoes_turno_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
     DELETE FROM dw.dim_turno;
  		
    MERGE DW_Atendimentos.dw.dim_turno AS destino
    USING (
        SELECT DISTINCT
            turno
        FROM DW_Atendimentos.staging.stg_turno
        WHERE data_carga = @data_carga
    ) AS origem
    ON (destino.turno= origem.turno)
     
    WHEN NOT MATCHED THEN
        INSERT (turno)
        VALUES (origem.turno);
END;
Go
     
     
EXEC dw.sp_procedimento_dw '2026-07-18'
EXEC dw.sp_procedimento_dimensao_funcao_dw '2026-07-18'
EXEC dw.sp_procedimento_dimensao_filial_dw '2026-07-18'
EXEC dw.sp_procedimento_dimensoes_pet_dw '2026-07-18'
EXEC dw.sp_procedimento_dimensoes_tutor_dw '2026-07-18'
EXEC dw.sp_procedimento_dimensoes_turno_dw '2026-07-18'

Select * from dw.dim_turno
