USE DW_Atendimentos

GO

CREATE or Alter Procedure dw.sp_procedimento_dimensoes_servico_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
    DELETE FROM dw.dim_tipo_servico;
    
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

GO

CREATE or Alter Procedure dw.sp_procedimento_dimensoes_funcionario_dw
@data_carga Date
AS
BEGIN
	SET NOCOUNT ON;

    IF @data_carga IS NULL
        THROW 50001, 'A data da carga deve ser informada.', 1;
    
    DELETE FROM DW_Atendimentos.dw.dim_funcionario;
    
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
    
    MERGE dw.dim_funcao AS destino
    USING (
        SELECT 
            cod_funcao, 
            funcao
        FROM staging.stg_funcao
        WHERE data_carga = @data_carga
    ) AS origem
    ON (destino.cod_funcao = origem.cod_funcao)
    
    
    WHEN MATCHED AND destino.funcao <> origem.funcao THEN
        UPDATE SET
            destino.funcao = origem.funcao,
            destino.data_atualizacao = @data_carga
    
    
    WHEN NOT MATCHED THEN
        INSERT (cod_funcao, funcao, data_atualizacao)
        VALUES (origem.cod_funcao, origem.funcao, @data_carga);
END;

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
    
CREATE or Alter Procedure dw.sp_procedimento_dimensoes_dw
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
        dfnc2.id_funcao,                   
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

    INNER JOIN dw.dim_funcao dfnc 
        ON stg.cod_funcao_principal = dfnc.cod_funcao
    LEFT JOIN dw.dim_funcao dfnc2 
        ON stg.cod_funcao_secundaria = dfnc2.cod_funcao
        
    WHERE stg.data_carga = @data_carga;

END;
GO
-- Garanta primeiro que a tabela de tempo tem o período coberto
EXEC dw.sp_carregar_dimensao_tempo '2026-07-01', '2026-08-18';

EXEC dw.sp_procedimento_dimensoes_servico_dw '2026-07-18'; 
Select * from DW_Atendimentos.dw.dim_filial;
EXEC dw.sp_procedimento_dimensoes_funcionario_dw '2026-07-18';
Select * from DW_Atendimentos.dw.dim_funcionario;
EXEC dw.sp_procedimento_dimensao_funcao_dw '2026-07-18';
Select * from DW_Atendimentos.dw.dim_funcao;
EXEC dw.sp_procedimento_dimensao_filial_dw '2026-07-18';
Select * from DW_Atendimentos.dw.dim_filial;
EXEC dw.sp_procedimento_dimensoes_pet_dw '2026-07-18';
Select * from DW_Atendimentos.dw.dim_pet;
EXEC dw.sp_procedimento_dimensoes_tutor_dw '2026-07-18';
Select * from DW_Atendimentos.dw.dim_tutor;
EXEC dw.sp_procedimento_dimensoes_dw '2026-07-18';
Select * from dw.dim_turno;
EXEC dw.sp_procedimento_dimensoes_quadro_clinico_dw '2026-07-18';
Select * from DW_Atendimentos.dw.dim_quadro_clinico dqc 

Exec dw.sp_carregar_fato_atendimento '2026-07-18'

Select * FROM dw.fato_atendimento

/*============================================================

       Procedure agregados por espécie 

       Dimensão agregada tempo: Utilizada por todas as tabelas agregadas 
       Dimensão agregada especie: Uma linha para cada espécie
       Fato agregado especie: Contabiliza a quantidade de atendimento por espécie por período 

============================================================*/
GO

CREATE OR ALTER PROCEDURE ag.sp_carregar_agregado_dimensao_tempo
AS
BEGIN 
SET NOCOUNT ON; 
    INSERT INTO ag.agregado_dim_tempo(
        id_tempo_ag, 
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
        FROM ag.agregado_dim_tempo destino 
        WHERE destino.data_completa = t.data_completa
    );
END;
GO

CREATE OR ALTER PROCEDURE ag.sp_carregar_agregado_dimensao_especie
AS
BEGIN 
SET NOCOUNT ON; 

    INSERT INTO ag.agregado_dim_especie(nome_especie)
    SELECT DISTINCT especie
    FROM dw.dim_pet 
    WHERE especie NOT IN (
        SELECT nome_especie FROM ag.agregado_dim_especie
    );
END;
GO

CREATE OR ALTER PROCEDURE ag.sp_carregar_agregado_fato_especie
AS
BEGIN 
SET NOCOUNT ON; 

    TRUNCATE TABLE ag.agregado_fato_especie;

    INSERT INTO ag.agregado_fato_especie( 
        id_data,
        id_pet_especie,
        quantidade
    )
    SELECT 
        t.id_tempo,
        e.id_especie,
        sum(f.quantidade)
    FROM dw.fato_atendimento f
    JOIN dw.dim_tempo t on (f.id_tempo_inicio = t.id_tempo)
    JOIN dw.dim_pet p on (f.id_pet = p.id_pet)
    JOIN ag.agregado_dim_especie e ON p.especie = e.nome_especie 
    GROUP BY 
        t.id_tempo, 
        e.id_especie;
END;
GO

EXEC ag.sp_carregar_agregado_dimensao_especie;
EXEC ag.sp_carregar_agregado_dimensao_tempo;
EXEC ag.sp_carregar_agregado_fato_especie;
select * from ag.agregado_dim_tempo;
select * from ag.agregado_dim_especie;
select * from ag.agregado_fato_especie;

/*============================================================

       Procedure agregados por filial 

       Dimensão agregada tempo: Utilizada por todas as tabelas agregadas 
       Dimensão agregada filial: Uma linha para cada filial
       Fato agregado filial: Contabiliza a quantidade de atendimento por filial por período 
   ============================================================*/    
GO
CREATE OR ALTER PROCEDURE ag.sp_carregar_agregado_dimensao_filial
AS
BEGIN
SET NOCOUNT ON; 

    TRUNCATE TABLE ag.agregado_dimensao_filial;

    INSERT INTO ag.agregado_dim_filial(
        id_filial,
        cidade,
        estado,
        nome_filial
       )SELECT 
            df.id_filial,
            df.cidade,
            df.estado,
            df.nome_filial
       FROM dw.dim_filial df
       WHERE NOT EXISTS (
            SELECT 1 
            FROM ag.agregado_dim_filial destino 
            WHERE destino.id_filial = df.id_filial
       );

END;
GO
CREATE OR ALTER PROCEDURE ag.sp_carregar_agregado_fato_filial
AS
BEGIN 
SET NOCOUNT ON; 

    TRUNCATE TABLE ag.agregado_fato_filial;

    INSERT INTO ag.agregado_fato_filial( 
        id_data,
        id_filial,
        quantidade
    )
    SELECT 
        t.id_tempo,
        fi.id_filial,
        sum(f.quantidade)
    FROM dw.fato_atendimento f
    JOIN dw.dim_tempo t on (f.id_tempo_inicio = t.id_tempo)
    JOIN dw.dim_filial fi on (f.id_filial = fi.id_filial)
    GROUP BY t.id_tempo,fi.id_filial 
     
END;
GO
EXEC ag.sp_carregar_agregado_dimensao_filial;
EXEC ag.sp_carregar_agregado_dimensao_tempo;
EXEC ag.sp_carregar_agregado_fato_filial;
select * from ag.agregado_dim_tempo;
select * from ag.agregado_dim_filial;
select * from ag.agregado_fato_filial;

/*============================================================

       Procedure agregados por tipo serviço 

       Dimensão agregada tempo: Utilizada por todas as tabelas agregadas 
       Dimensão agregada tipo servico: Uma linha para cada tipo serviço
       Fato agregado tipo serviço: Contabiliza a quantidade de atendimento 
       por tipo serviço por período 


*/
