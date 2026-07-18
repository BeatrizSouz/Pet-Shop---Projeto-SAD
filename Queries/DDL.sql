/* ============================================================
DEMONSTRA��O DE UM AMBIENTE DE DATA WAREHOUSE

Cen�rio: Gest�o de Atendimentos de Redes de Petshop

Camadas:
- OLTP: ambiente operacional;
- STAGING: �rea intermedi�ria;
- DW: ambiente dimensional.

Conven��es:
- cod_: chave operacional ou chave natural;
- id_: chave substituta, surrogate key;
- data_carga: data de execu��o do processo ETL.

Dimens�es:
- dim_tempo: dimens�es est�tica carregadas por intervalos
- dim_filial:SCD Tipo 2;
- dim_tipo_servico:SCD Tipo 1;
- dim_funcionario:SCD Tipo 2;
- dim_funcao:SCD Tipo 1;
- dim_tutor:SCD Tipo 2;
- dim_pet:SCD Tipo 2;
- dim_quadro_clinico:SCD Tipo 2;

Granularidade da fato:
- uma linha para cada atendimento.
============================================================ */
/* ============================================================
1. CRIA��O DO BANCO DE DADOS
============================================================ 
 */
USE master 
GO

IF NOT EXISTS (
    SELECT
        name
    FROM
        sys.databases
    WHERE
        name = 'DW_Atendimentos'
) BEGIN CREATE DATABASE DW_Atendimentos;

END
GO 

USE DW_Atendimentos;

GO
/* ============================================================
2. CRIA��O DOS SCHEMAS
============================================================ */
IF NOT EXISTS (
    SELECT
        1
    FROM
        sys.schemas
    WHERE
        name = 'oltp'
) EXEC ('CREATE SCHEMA oltp');

GO 

IF NOT EXISTS (
    SELECT
        1
    FROM
        sys.schemas
    WHERE
        name = 'staging'
) EXEC ('CREATE SCHEMA staging');

GO 

IF NOT EXISTS (
    SELECT
        1
    FROM
        sys.schemas
    WHERE
        name = 'dw'
) EXEC ('CREATE SCHEMA dw');

GO
/* ============================================================
3. REMO��O DOS OBJETOS ANTERIORES

Essa etapa permite executar novamente todo o script.
Os procedimentos s�o removidos antes das tabelas.
============================================================ */
DROP PROCEDURE IF EXISTS dw.sp_executar_etl;

DROP PROCEDURE IF EXISTS dw.sp_carregar_fato_atendimento;

DROP PROCEDURE IF EXISTS dw.sp_carregar_quadro_clinico;

DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_tempo;

DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_filial;

DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_tipo_servico;

DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_funcionario;

DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_tutor;

DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_pet;

DROP PROCEDURE IF EXISTS staging.sp_carregar_staging;

GO
DROP TABLE IF EXISTS dw.fato_atendimento;

DROP TABLE IF EXISTS dw.dim_quadro_clinico;

DROP TABLE IF EXISTS dw.dim_tempo;

DROP TABLE IF EXISTS dw.dim_turno;

DROP TABLE IF EXISTS dw.dim_filial;

DROP TABLE IF EXISTS dw.dim_tipo_servico;

DROP TABLE IF EXISTS dw.dim_funcao;

DROP TABLE IF EXISTS dw.dim_funcionario;

DROP TABLE IF EXISTS dw.dim_tutor;

DROP TABLE IF EXISTS dw.dim_pet;

DROP TABLE IF EXISTS staging.stg_atendimento;

DROP TABLE IF EXISTS staging.stg_quadro_clinico;

DROP TABLE IF EXISTS staging.stg_filial;

DROP TABLE IF EXISTS staging.stg_tipo_servico;

DROP TABLE IF EXISTS staging.stg_funcao;

DROP TABLE IF EXISTS staging.stg_funcionario;

DROP TABLE IF EXISTS staging.stg_tutor;

DROP TABLE IF EXISTS staging.stg_pet;

DROP TABLE IF EXISTS oltp.atendimento;

DROP TABLE IF EXISTS oltp.quadro_clinico;

DROP TABLE IF EXISTS oltp.pet;

DROP TABLE IF EXISTS oltp.tutor;

DROP TABLE IF EXISTS oltp.funcionario;

DROP TABLE IF EXISTS oltp.funcao;

DROP TABLE IF EXISTS oltp.filial;

DROP TABLE IF EXISTS oltp.endereco;

DROP TABLE IF EXISTS oltp.tipo_servico;

GO
/* ============================================================
4. AMBIENTE OPERACIONAL - OLTP
============================================================ */
/* Tipos de servi�o oferecidos. */
CREATE TABLE
    oltp.tipo_servico (
        cod_tipo_servico INT IDENTITY (1, 1) PRIMARY KEY,
        nome_tipo_servico VARCHAR(100) NOT NULL,
        valor_servico DECIMAL(10, 2) DEFAULT 0.00
    );

/* Endere�os*/
CREATE TABLE
    oltp.endereco (
        cod_endereco INT IDENTITY (1, 1) PRIMARY KEY,
        cep VARCHAR(8) NOT NULL,
        estado VARCHAR(100) NOT NULL,
        cidade VARCHAR(100) NOT NULL,
        rua VARCHAR(100) NOT NULL,
        numero INT NOT NULL,
        complemento VARCHAR(100)
    );

/* Filiais da Rede. */
CREATE TABLE
    oltp.filial (
        cod_filial INT IDENTITY (1, 1) PRIMARY KEY,
        cod_endereco INT NOT NULL,
        nome_filial VARCHAR(100) NOT NULL,
        CONSTRAINT fk_endereco FOREIGN KEY (cod_endereco) REFERENCES oltp.endereco (cod_endereco)
    );

/* Func�es de cada funcin�rio*/
CREATE TABLE
    oltp.funcao (
        cod_funcao INT IDENTITY (1, 1) PRIMARY KEY,
        funcao VARCHAR(100) NOT NULL,
    );

    /* Funcion�rios da Rede*/
CREATE TABLE
    oltp.funcionario (
        cod_funcionario INT IDENTITY (1, 1) PRIMARY KEY,
        cod_endereco INT,
        cod_funcao INT,
        matricula INT NOT NULL,
        nome_funcionario VARCHAR(100) NOT NULL,
        CRMV VARCHAR(100) NULL,
        CONSTRAINT fk_endereco_funcionario FOREIGN KEY (cod_endereco) REFERENCES oltp.endereco (cod_endereco),
        CONSTRAINT fk_funca_funcionario FOREIGN KEY (cod_funcao) REFERENCES oltp.funcao (cod_funcao)
    );

/* Os clientes */
CREATE TABLE
    oltp.tutor (
        cod_tutor INT IDENTITY (1, 1) PRIMARY KEY,
        cpf VARCHAR(11) NOT NULL,
        cod_endereco INT NOT NULL,
        nome_tutor VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL,
        telefone VARCHAR(100) NOT NULL,
        CONSTRAINT fk_endereco_tutor FOREIGN KEY (cod_endereco) REFERENCES oltp.endereco (cod_endereco)
    );

/* Os animais de cada tutor*/
CREATE TABLE
    oltp.pet (
        cod_pet INT IDENTITY (1, 1) PRIMARY KEY,
        cod_tutor INT NOT NULL,
        nome VARCHAR(100) NOT NULL,
        especie VARCHAR(100) NOT NULL,
        raca VARCHAR(100) NULL,
        porte VARCHAR(100) NOT NULL,
        sexo CHAR(1) NOT NULL CHECK (Sexo IN ('F', 'M', 'f', 'm')),
        CONSTRAINT fk_pet_tutor FOREIGN KEY (cod_tutor) REFERENCES oltp.tutor (cod_tutor)
    );

/* Descri��o da situa��o inicial*/
CREATE TABLE
    oltp.quadro_clinico (
        cod_quadro_clinico INT IDENTITY (1, 1) PRIMARY KEY,
        situacao_inicial VARCHAR(500) NOT NULL,
        situacao_final VARCHAR(500)
    );

/*Atendimentos registrados no sistema operacional*/
CREATE TABLE
    oltp.atendimento (
        cod_atendimento INT IDENTITY (1, 1) PRIMARY KEY,
        cod_tipo_servico INT NOT NULL,
        cod_filial INT NOT NULL,
        cod_funcionario INT NOT NULL,
        cod_tutor INT NOT NULL,
        cod_pet INT NOT NULL,
        cod_quadro_clinico INT NOT NULL,
        data_inicio DATETIME2 NOT NULL,
        data_fim DATETIME2 NULL,
        prioridade VARCHAR(20) NOT NULL,
        CONSTRAINT fk_atendimento_tipo_servico FOREIGN KEY (cod_tipo_servico) REFERENCES oltp.tipo_servico (cod_tipo_servico),
        CONSTRAINT fk_atendimento_filial FOREIGN KEY (cod_filial) REFERENCES oltp.filial (cod_filial),
        CONSTRAINT fk_atendimento_funcionario FOREIGN KEY (cod_funcionario) REFERENCES oltp.funcionario (cod_funcionario),
        CONSTRAINT fk_atendimento_tutor FOREIGN KEY (cod_tutor) REFERENCES oltp.tutor (cod_tutor),
        CONSTRAINT fk_atendimento_pet FOREIGN KEY (cod_pet) REFERENCES oltp.pet (cod_pet),
        CONSTRAINT fk_atendimento_quadro_clinico FOREIGN KEY (cod_quadro_clinico) REFERENCES oltp.quadro_clinico (cod_quadro_clinico)
    );

    /* ============================================================
    6. �REA DE STAGING
    
    A staging armazena uma fotografia dos dados operacionais
    para cada data de carga.
    
    Ao reprocessar uma data:
    - somente os registros daquela data s�o removidos;
    - as demais cargas s�o preservadas.
    ============================================================ */
CREATE TABLE
    staging.stg_tipo_servico (
        cod_tipo_servico INT NOT NULL,
        nome_tipo_servico VARCHAR(100) NOT NULL,
        data_carga DATE NOT NULL
    );

CREATE TABLE
    staging.stg_filial (
        cod_filial INT NOT NULL,
        cidade VARCHAR(100) NOT NULL,
        estado VARCHAR(100) NOT NULL,
        nome_filial VARCHAR(100) NOT NULL,
        data_carga DATE NOT NULL
    );

CREATE TABLE
    staging.stg_funcionario (
        cod_funcionario INT NOT NULL,
        cidade VARCHAR(100) NOT NULL,
        estado VARCHAR(100) NOT NULL,
        matricula INT NOT NULL,
        nome_funcionario VARCHAR(100) NOT NULL,
        CRMV VARCHAR(100) NULL,
        data_carga DATE NOT NULL
    );

CREATE TABLE
    staging.stg_funcao (
        cod_funcao INT NOT NULL,
        funcao VARCHAR(100) NOT NULL,
        data_carga DATE NOT NULL
    );

CREATE TABLE
    staging.stg_tutor (
        cod_tutor INT NOT NULL,
        cpf VARCHAR(11) NOT NULL,
        cidade VARCHAR(100) NOT NULL,
        estado VARCHAR(100) NOT NULL,
        nome_tutor VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL,
        telefone VARCHAR(100) NOT NULL,
        data_carga DATE NOT NULL
    );

CREATE TABLE
    staging.stg_pet (
        cod_pet INT NOT NULL,
        cod_tutor INT NOT NULL,
        nome VARCHAR(100) NOT NULL,
        especie VARCHAR(100) NOT NULL,
        raca VARCHAR(100) NULL,
        porte VARCHAR(100) NOT NULL,
        sexo CHAR(1) NOT NULL CHECK (Sexo IN ('F', 'M', 'f', 'm')),
        data_carga DATE NOT NULL
    );

CREATE TABLE
    staging.stg_quadro_clinico (
        cod_quadro_clinico INT NOT NULL,
        situacao_inicial VARCHAR(500) NOT NULL,
        situacao_final VARCHAR(500),
        data_carga DATE NOT NULL
    );

CREATE TABLE
    staging.stg_atendimento (
        cod_atendimento INT NOT NULL,
        cod_tipo_servico INT NOT NULL,
        cod_filial INT NOT NULL,
        cod_funcionario INT NOT NULL,
        cod_tutor INT NOT NULL,
        cod_pet INT NOT NULL,
        cod_quadro_clinico INT NOT NULL,
        data_inicio DATETIME2 NOT NULL,
        data_fim DATETIME2 NULL,
        prioridade VARCHAR(20) NOT NULL,
        valor DECIMAL(10, 2) DEFAULT 0.00,
        data_carga DATE NOT NULL
    );

GO
/* �ndices para facilitar a localiza��o dos dados de uma carga. */
CREATE INDEX ix_stg_atendimento_data_carga ON staging.stg_atendimento (data_carga);

CREATE INDEX ix_stg_quadro_clinico_data_carga ON staging.stg_quadro_clinico (data_carga);

CREATE INDEX ix_stg_filial_data_carga ON staging.stg_filial (data_carga);

CREATE INDEX ix_stg_tipo_servico_data_carga ON staging.stg_tipo_servico (data_carga);

CREATE INDEX ix_stg_funcionario_data_carga ON staging.stg_funcionario (data_carga);

CREATE INDEX ix_stg_tutor_data_carga ON staging.stg_tutor (data_carga);

CREATE INDEX ix_stg_pet_data_carga ON staging.stg_pet (data_carga);

GO
/* ============================================================
7. AMBIENTE DIMENSIONAL
============================================================ */
/* ============================================================
7.1 DIMENS�O FUNCION�RIO e DIMENS�O TUTOR 

Estrat�gia SCD Tipo 2.

Quando um atributo hist�rico for alterado:
- a vers�o atual ser� encerrada;
- uma nova vers�o ser� criada;
- o hist�rico ser� preservado.
============================================================ */
CREATE TABLE
    dw.dim_funcionario (
        id_funcionario INT IDENTITY (1, 1) PRIMARY KEY,
        cod_funcionario INT NOT NULL,
        matricula INT NOT NULL,
        nome_funcionario VARCHAR(100) NOT NULL,
        CRMV VARCHAR(100) NULL,
        cidade VARCHAR(100) NOT NULL,
        estado VARCHAR(100) NOT NULL,
        data_inicio DATE NOT NULL,
        data_fim DATE NULL,
        registro_atual BIT NOT NULL
    );

CREATE TABLE
    dw.dim_tutor (
        id_tutor INT IDENTITY (1, 1) PRIMARY KEY,
        cod_tutor INT NOT NULL,
        cpf VARCHAR(11) NOT NULL,
        cidade VARCHAR(100) NOT NULL,
        estado VARCHAR(100) NOT NULL,
        nome_tutor VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL,
        telefone VARCHAR(100) NOT NULL,
        data_inicio DATE NOT NULL,
        data_fim DATE NULL,
        registro_atual BIT NOT NULL
    );

/* ============================================================
7.3 DIMENS�O TEMPO

A dimens�o tempo � carregada separadamente.

id_tempo:
- chave substituta;
- valor gerado automaticamente por IDENTITY.

data_completa:
- representa a chave natural da dimens�o.
============================================================ */
CREATE TABLE
    dw.dim_tempo (
        id_tempo INT IDENTITY (1, 1) PRIMARY KEY,
        data_completa DATE NOT NULL,
        dia INT NOT NULL,
        mes INT NOT NULL,
        nome_mes VARCHAR(20) NOT NULL,
        trimestre INT NOT NULL,
        ano INT NOT NULL,
        numero_dia_semana INT NOT NULL,
        nome_dia_semana VARCHAR(20) NOT NULL,
        CONSTRAINT uq_dim_tempo_data_completa UNIQUE (data_completa)
    );

/* ============================================================
7.4 DIMENS�O SERVI�O

Implementa��o da estrat�gia SCD Tipo 1.

Etapas:
1. atualiza os registros existentes;
2. insere os novos registros.
============================================================ */
CREATE TABLE
    dw.dim_tipo_servico (
        id_tipo_servico INT IDENTITY (1, 1) PRIMARY KEY,
        cod_tipo_servico INT NOT NULL,
        nome_tipo_servico VARCHAR(100) NOT NULL,
        data_atualizacao DATE NOT NULL,
        CONSTRAINT uq_dim_tipo_servico_cod_tipo_servico UNIQUE (cod_tipo_servico)
    );

/* ============================================================
7.5 DIMENS�O FILIAL

Estrat�gia SCD Tipo 2.

Quando um atributo hist�rico for alterado:
- a vers�o atual ser� encerrada;
- uma nova vers�o ser� criada;
- o hist�rico ser� preservado.
============================================================ */
CREATE TABLE
    dw.dim_filial (
        id_filial INT IDENTITY (1, 1) PRIMARY KEY,
        cod_filial INT NOT NULL,
        cidade VARCHAR(100) NOT NULL,
        estado VARCHAR(100) NOT NULL,
        nome_filial VARCHAR(100) NOT NULL,
        data_inicio DATE NOT NULL,
        data_fim DATE NULL,
        registro_atual BIT NOT NULL
    );

/* ============================================================
7.6 DIMENS�O PET

Implementa��o da estrat�gia SCD Tipo 2.

Etapas:
1. atualiza os registros existentes;
2. insere os novos registros.
============================================================ */
CREATE TABLE
    dw.dim_pet (
        id_pet INT IDENTITY (1, 1) PRIMARY KEY,
        cod_pet INT NOT NULL,
        nome VARCHAR(100) NOT NULL,
        especie VARCHAR(100) NOT NULL,
        raca VARCHAR(100) NULL,
        porte VARCHAR(100) NOT NULL,
        sexo CHAR(1) NOT NULL CHECK (Sexo IN ('F', 'M', 'f', 'm')),
        data_inicio DATE NOT NULL,
        data_fim DATE NULL,
        registro_atual BIT NOT NULL
    );

/* ============================================================
7.7 DIMENS�O TURNO

A dimens�o tempo � carregada separadamente.

Turno:
- Manh�
- Tarde
- Noite
============================================================ */
CREATE TABLE
    dw.dim_turno (
        id_turno INT IDENTITY (1, 1) PRIMARY KEY,
        turno VARCHAR(5) NOT NULL
    );

/* ============================================================
7.8 DIMENS�O QUADRO CLINICO

Implementa��o da estrat�gia SCD Tipo 2.

Etapas:
1. atualiza os registros existentes;
2. insere os novos registros.
============================================================ */
CREATE TABLE
    dw.dim_quadro_clinico (
        id_quadro_clinico INT IDENTITY (1, 1) PRIMARY KEY,
        cod_quadro_clinico INT NOT NULL,
        situacao_inicial VARCHAR(500) NOT NULL,
        situacao_final VARCHAR(500),
        data_inicio DATE NOT NULL,
        data_fim DATE NULL,
        registro_atual BIT NOT NULL
    );

/* ============================================================
7.9 DIMENS�O FUN��O

Implementa��o da estrat�gia SCD Tipo 1.

Etapas:
1. atualiza os registros existentes;
2. insere os novos registros.
============================================================ */
CREATE TABLE
    dw.dim_funcao (
        id_funcao INT IDENTITY (1, 1) PRIMARY KEY,
        cod_funcao INT NOT NULL,
        funcao VARCHAR(100) NOT NULL,
        data_atualizacao DATE NOT NULL,
    );

/* ============================================================
7.10 TABELA FATO


Granularidade:
- uma linha para cada atendimento.

- quantidade;
- tempo_resolucao_horas.

Dimens�o tempo:
- id_tempo_abertura;
- id_tempo_fechamento.
============================================================ */
CREATE TABLE
    dw.fato_atendimento (
        id_atendimento BIGINT IDENTITY (1, 1) PRIMARY KEY,
        cod_atendimento INT NOT NULL,
        id_tipo_servico INT NOT NULL,
        id_filial INT NOT NULL,
        id_funcionario INT NOT NULL,
        id_tutor INT NOT NULL,
        id_pet INT NOT NULL,
        id_turno INT NOT NULL,
        id_quadro_clinico INT NOT NULL,
        id_funcao_principal INT NOT NULL,
        id_funcao_secundaria INT NULL,
        id_tempo_inicio INT NOT NULL,
        id_tempo_fim INT NULL,
        quantidade INT DEFAULT 1,
        valor_atendimento DECIMAL(10, 2) DEFAULT 0.00,
        data_carga DATE NOT NULL,
        CONSTRAINT uq_fato_atendimento_cod_atendimento UNIQUE (cod_atendimento),
        CONSTRAINT fk_atendimento_tipo_servico FOREIGN KEY (id_tipo_servico) REFERENCES dw.dim_tipo_servico (id_tipo_servico),
        CONSTRAINT fk_atendimento_filial FOREIGN KEY (id_filial) REFERENCES dw.dim_filial (id_filial),
        CONSTRAINT fk_atendimento_funcionario FOREIGN KEY (id_funcionario) REFERENCES dw.dim_funcionario (id_funcionario),
        CONSTRAINT fk_atendimento_tutor FOREIGN KEY (id_tutor) REFERENCES dw.dim_tutor (id_tutor),
        CONSTRAINT fk_atendimento_pet FOREIGN KEY (id_pet) REFERENCES dw.dim_pet (id_pet),
        CONSTRAINT fk_atendimento_turno FOREIGN KEY (id_turno) REFERENCES dw.dim_turno (id_turno),
        CONSTRAINT fk_atendimento_quadro_clinico FOREIGN KEY (id_quadro_clinico) REFERENCES dw.dim_quadro_clinico (id_quadro_clinico),
        CONSTRAINT fk_atendimento_funcao_principal FOREIGN KEY (id_funcao_principal) REFERENCES dw.dim_funcao (id_funcao),
        CONSTRAINT fk_atendimento_funcao_secundaria FOREIGN KEY (id_funcao_secundaria) REFERENCES dw.dim_funcao (id_funcao),
        CONSTRAINT fk_atendimento_tempo_inicio FOREIGN KEY (id_tempo_inicio) REFERENCES dw.dim_tempo (id_tempo),
        CONSTRAINT fk_atendimento_tempo_fim FOREIGN KEY (id_tempo_fim) REFERENCES dw.dim_tempo (id_tempo)
    );