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
    	Select cod_funcao, funcao
    	From staging.stg_funcao
    	Where data_carga = @data_carga
    ) As origem
    ON(destino.cod_funcao = origem.cod_funcao)
    
    When Matched and destino.funcao <> origem.funcao Then
    	Update set
    		destino.funcao = origem.funcao,
    		destino.data_atualizacao = @data_carga
    
	When Not Matched Then
		Insert (cod_funcao, funcao, data_atualizacao)
		Values (origem.cod_funcao,  origem.funcao, @data_carga);
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
        SELECT
        	cod_turno,
            turno
        FROM DW_Atendimentos.staging.stg_turno
        WHERE data_carga = @data_carga
    ) AS origem
    ON (destino.cod_turno= origem.cod_turno)
     
    WHEN NOT MATCHED THEN
        INSERT (cod_turno, turno)
        VALUES (origem.cod_turno, origem.turno);
END;

Go

CREATE or Alter Procedure dw.sp_procedimento_dimensoes_quadro_clinico_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
    DELETE FROM dw.dim_quadro_clinico; 
	
	Update dqc
    Set 
    	dqc.data_fim = @data_carga,
    	dqc.registro_atual = 0
    From DW_Atendimentos.dw.dim_quadro_clinico dqc 
    Inner Join DW_Atendimentos.staging.stg_quadro_clinico sq on sq.cod_quadro_clinico = dqc.cod_quadro_clinico
    Where dqc.registro_atual = 1
    	and sq.data_carga = @data_carga
    	and	(dqc.cod_quadro_clinico <> sq.cod_quadro_clinico
    		or dqc.situacao_inicial <> sq.situacao_inicial
    		or dqc.situacao_final <> sq.situacao_final);
	
	INSERT INTO DW_Atendimentos.dw.dim_quadro_clinico (cod_quadro_clinico, situacao_inicial, situacao_final, data_inicio, data_fim, registro_atual)
	SELECT sq.cod_quadro_clinico, sq.situacao_inicial, sq.situacao_final, @data_carga as data_inicial, NULL as data_final, 1 as registro_atual
	From DW_Atendimentos.staging.stg_quadro_clinico sq
	Where sq.data_carga = @data_carga
		and not Exists (
			Select 1 From DW_Atendimentos.dw.dim_quadro_clinico c
			Where c.cod_quadro_clinico = sq.cod_quadro_clinico and c.registro_atual = 1
		);
End

GO

CREATE OR ALTER PROCEDURE dw.sp_carregar_fato_atendimento
    @data_carga DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;

    DELETE FROM dw.fato_atendimento WHERE data_carga = @data_carga;

    INSERT INTO dw.fato_atendimento (
        cod_atendimento,
        id_tipo_servico,
        id_filial,
        id_funcionario,
        id_tutor,
        id_pet,
        id_turno,
        id_quadro_clinico,
        id_funcao_principal,    
        id_funcao_secundaria,  
        id_tempo_inicio,
        id_tempo_fim,
        quantidade,
        valor_atendimento,
        data_carga
    )
    SELECT 
        stg.cod_atendimento,
        dts.id_tipo_servico,
        dfi.id_filial,
        dfu.id_funcionario,
        dtu.id_tutor,
        dpe.id_pet,
        dtu_turno.id_turno,
        dqc.id_quadro_clinico,
        dfnc.id_funcao,          
        NULL,                   
        dti.id_tempo,           
        dtf.id_tempo,           
        1 AS quantidade,        
        stg.valor AS valor_atendimento,
        @data_carga AS data_carga
    FROM staging.stg_atendimento stg
    
    INNER JOIN dw.dim_tipo_servico dts 
        ON stg.cod_tipo_servico = dts.cod_tipo_servico
        
    INNER JOIN dw.dim_turno dtu_turno 
        ON stg.cod_turno = dtu_turno.cod_turno

    INNER JOIN dw.dim_filial dfi 
        ON stg.cod_filial = dfi.cod_filial AND dfi.registro_atual = 1
        
    INNER JOIN dw.dim_funcionario dfu 
        ON stg.cod_funcionario = dfu.cod_funcionario AND dfu.registro_atual = 1
        
    INNER JOIN dw.dim_tutor dtu 
        ON stg.cod_tutor = dtu.cod_tutor AND dtu.registro_atual = 1
        
    INNER JOIN dw.dim_pet dpe 
        ON stg.cod_pet = dpe.cod_pet AND dpe.registro_atual = 1
        
    INNER JOIN dw.dim_quadro_clinico dqc 
        ON stg.cod_quadro_clinico = dqc.cod_quadro_clinico AND dqc.registro_atual = 1

    INNER JOIN dw.dim_tempo dti 
        ON CAST(stg.data_inicio AS DATE) = dti.data_completa
        
    LEFT JOIN dw.dim_tempo dtf 
        ON CAST(stg.data_fim AS DATE) = dtf.data_completa

    LEFT JOIN dw.dim_funcao dfnc 
        ON dfnc.cod_funcao = stg.cod_turno
        
    WHERE stg.data_carga = @data_carga;

END;
GO

