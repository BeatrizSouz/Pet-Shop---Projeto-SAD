   /* ============================================================
   DEMONSTRAÇÃO DE UM AMBIENTE DE DATA WAREHOUSE
   
   Cenário: Gestão de Atendimentos de Redes de Petshop

   Camadas:
   - OLTP: ambiente operacional;
   - STAGING: área intermediária;
   - DW: ambiente dimensional.

   Convenções:
   - cod_: chave operacional ou chave natural;
   - id_: chave substituta, surrogate key;
   - data_carga: data de execução do processo ETL.

   Dimensões:
   - dim_tempo: dimensões estática carregadas por intervalos
   - dim_filial:SCD Tipo 2;
   - dim_servico:SCD Tipo 1;
   - dim_funcionario:SCD Tipo 2;
   - dim_tutor:SCD Tipo 2;
   - dim_pet:SCD Tipo 2;
   - dim_quadro_clinico:SCD Tipo 2;

   Granularidade da fato:
   - uma linha para cada atendimento.
   ============================================================ */


/* ============================================================
   1. CRIAÇÃO DO BANCO DE DADOS
   ============================================================ 
   */

   USE master 
   GO

   IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DW_Atendimentos')
    BEGIN
        CREATE DATABASE DW_Atendimentos;
    END
   GO

   USE DW_Atendimentos;
   GO

    /* ============================================================
   2. CRIAÇÃO DOS SCHEMAS
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'oltp')
    EXEC('CREATE SCHEMA oltp');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dw')
    EXEC('CREATE SCHEMA dw');
GO

/* ============================================================
   3. REMOÇÃO DOS OBJETOS ANTERIORES

   Essa etapa permite executar novamente todo o script.
   Os procedimentos são removidos antes das tabelas.
   ============================================================ */

DROP PROCEDURE IF EXISTS dw.sp_executar_etl;
DROP PROCEDURE IF EXISTS dw.sp_carregar_fato_atendimento;
DROP PROCEDURE IF EXISTS dw.sp_carregar_quadro_clinico;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_tempo;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_filial;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_servico;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_funcionario;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_tutor;
DROP PROCEDURE IF EXISTS dw.sp_carregar_dim_pet;
DROP PROCEDURE IF EXISTS staging.sp_carregar_staging;
GO

DROP TABLE IF EXISTS dw.fato_atendimento;
DROP TABLE IF EXISTS dw.quadro_clinico;
DROP TABLE IF EXISTS dw.dim_tempo;
DROP TABLE IF EXISTS dw.dim_filial;
DROP TABLE IF EXISTS dw.dim_servico;
DROP TABLE IF EXISTS dw.dim_funcionario;
DROP TABLE IF EXISTS dw.dim_tutor;
DROP TABLE IF EXISTS dw.dim_pet;

DROP TABLE IF EXISTS staging.stg_atendimento;
DROP TABLE IF EXISTS staging.stg_quadro_clinico;
DROP TABLE IF EXISTS staging.stg_filial;
DROP TABLE IF EXISTS staging.stg_tipo_servico;
DROP TABLE IF EXISTS staging.stg_funcionario;
DROP TABLE IF EXISTS staging.stg_tutor;
DROP TABLE IF EXISTS staging.stg_pet;


DROP TABLE IF EXISTS oltp.atendimento;
DROP TABLE IF EXISTS oltp.quadro_clinico;
DROP TABLE IF EXISTS oltp.funcao;
DROP TABLE IF EXISTS oltp.pet;
DROP TABLE IF EXISTS oltp.tutor;
DROP TABLE IF EXISTS oltp.funcionario;
DROP TABLE IF EXISTS oltp.filial;
DROP TABLE IF EXISTS oltp.endereco;
DROP TABLE IF EXISTS oltp.tipo_servico;



GO
/* ============================================================
   4. AMBIENTE OPERACIONAL - OLTP
   ============================================================ */


/* Tipos de serviço oferecidos. */

CREATE TABLE oltp.tipo_servico (
    cod_tipo_servico INT IDENTITY(1,1) PRIMARY KEY,
    nome_tipo_servico VARCHAR(100) NOT NULL,
    valor_servico DECIMAL(10,2) DEFAULT 0.00
);



/* Endereços*/
CREATE TABLE oltp.endereco(
    cod_endereco INT IDENTITY(1,1) PRIMARY KEY,
    cep VARCHAR(8) NOT NULL,
    estado VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    rua VARCHAR(100) NOT NULL,
    numero INT NOT NULL,
    complemento VARCHAR(100)
    
);
/* Filiais da Rede. */

CREATE TABLE oltp.filial (
    cod_filial INT IDENTITY(1,1) PRIMARY KEY,
    cod_endereco INT NOT NULL,
    nome_filial VARCHAR(100) NOT NULL,
    CONSTRAINT fk_endereco FOREIGN KEY (cod_endereco) REFERENCES oltp.endereco(cod_endereco)
);

/* Funcionários da Rede*/

CREATE TABLE oltp.funcionario (
    cod_funcionario INT IDENTITY(1,1) PRIMARY KEY,
    cod_endereco INT,
    matricula INT NOT NULL,
    nome_funcionario VARCHAR(100) NOT NULL,
    CRMV VARCHAR(100) NULL
    CONSTRAINT fk_endereco_funcionario FOREIGN KEY (cod_endereco) REFERENCES oltp.endereco(cod_endereco)
);

/* Funcões de cada funcinário*/
CREATE TABLE oltp.funcao (
    cod_funcao INT IDENTITY(1,1) PRIMARY KEY,
    cod_funcionario INT NOT NULL,
    funcao  VARCHAR(100) NOT NULL,
    CONSTRAINT fk_funcao_funcionario FOREIGN KEY (cod_funcionario) REFERENCES oltp.funcionario(cod_funcionario)
);


/* Os clientes */
CREATE TABLE oltp.tutor(
    cod_tutor INT IDENTITY(1,1) PRIMARY KEY,
    cpf VARCHAR(11) NOT NULL,
    cod_endereco INT NOT NULL,
    nome_tutor VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefone VARCHAR(100) NOT NULL,
    CONSTRAINT fk_endereco_tutor FOREIGN KEY (cod_endereco) REFERENCES oltp.endereco(cod_endereco)
);

/* Os animais de cada tutor*/
CREATE TABLE oltp.pet(
    cod_pet INT IDENTITY(1,1) PRIMARY KEY,
    cod_tutor INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    especie VARCHAR(100) NOT NULL,
    porte VARCHAR(100) NOT NULL,
    sexo CHAR(1) NOT NULL 
    CHECK (Sexo IN ('F', 'M', 'f', 'm')),
    CONSTRAINT fk_pet_tutor FOREIGN KEY (cod_tutor) REFERENCES oltp.tutor(cod_tutor)
);

/* Descrição da situação inicial*/
CREATE TABLE oltp.quadro_clinico(
    cod_quadro_clinico INT IDENTITY(1,1) PRIMARY KEY,
    situacao_inicial VARCHAR(500) NOT NULL, 
    situacao_final VARCHAR(500)
);

/*Atendimentos registrados no sistema operacional*/
CREATE TABLE oltp.atendimento (
    cod_atendimento INT IDENTITY(1,1) PRIMARY KEY,
    cod_tipo_servico INT NOT NULL,
    cod_filial INT NOT NULL,
    cod_funcionario INT NOT NULL,
    cod_tutor INT NOT NULL,
    cod_pet INT NOT NULL,
    cod_quadro_clinico INT NOT NULL,
    data_inicio DATETIME2 NOT NULL,
    data_fim DATETIME2 NULL,
    prioridade VARCHAR(20) NOT NULL,
    CONSTRAINT fk_atendimento_tipo_servico FOREIGN KEY (cod_tipo_servico) REFERENCES oltp.tipo_servico(cod_tipo_servico),
    CONSTRAINT fk_atendimento_filial FOREIGN KEY (cod_filial) REFERENCES oltp.filial(cod_filial),
    CONSTRAINT fk_atendimento_funcionario FOREIGN KEY (cod_funcionario) REFERENCES oltp.funcionario(cod_funcionario),
    CONSTRAINT fk_atendimento_tutor FOREIGN KEY (cod_tutor) REFERENCES oltp.tutor(cod_tutor),
    CONSTRAINT fk_atendimento_pet FOREIGN KEY (cod_pet) REFERENCES oltp.pet(cod_pet),
    CONSTRAINT fk_atendimento_quadro_clinico FOREIGN KEY (cod_quadro_clinico) REFERENCES oltp.quadro_clinico(cod_quadro_clinico)
);

GO

SELECT * FROM oltp.quadro_clinico

/* ============================================================
   5. DADOS INICIAIS DO AMBIENTE OPERACIONAL (5 REGISTROS)
   ============================================================ */

-- 1. Endereços
INSERT INTO oltp.endereco (cep, estado, cidade, rua, numero, complemento) VALUES 
('49001000', 'SE', 'Aracaju', 'Av. Hermes Fontes', 100, 'Apto 101'),
('49001001', 'SE', 'Aracaju', 'Rua Bahia', 205, NULL),
('49001002', 'SE', 'Aracaju', 'Av. Ivo do Prado', 50, 'Loja B'),
('49001003', 'SE', 'Aracaju', 'Rua Itabaiana', 800, 'Edifício Comercial'),
('49001004', 'SE', 'Aracaju', 'Av. Augusto Franco', 120, 'Casa');

-- 2. Tipos de Serviço

INSERT INTO oltp.tipo_servico (nome_tipo_servico,valor_servico) VALUES 
('Banho e Tosa',90.00),
('Consulta Veterinária',60.00),
('Vacinação',40.00),
('Aplicação de Medicamento',50.00),
('Cirurgia',30.00);
-- 3. Filiais
INSERT INTO oltp.filial (cod_endereco, nome_filial) VALUES 
(1, 'Filial Centro'), (2, 'Filial Sul'), (3, 'Filial Norte'), (4, 'Filial Leste'), (5, 'Filial Jardins');

-- 4. Funcionários
INSERT INTO oltp.funcionario (cod_endereco, matricula, nome_funcionario, CRMV) VALUES 
(1, 101, 'Ana Paula', NULL),
(2, 102, 'Ricardo Silva', 'CRM-SE 111'),
(3, 103, 'Fernanda Lima', 'CRM-SE 222'),
(4, 104, 'Marcos Oliveira', NULL),
(5, 105, 'Patrícia Rocha', 'CRM-SE 333');

-- 5. Funções
INSERT INTO oltp.funcao (cod_funcionario, funcao) VALUES 
(1, 'Atendente'), (2, 'Veterinário'), (3, 'Veterinário'), (4, 'Auxiliar'), (5, 'Veterinário');

-- 6. Tutores
INSERT INTO oltp.tutor (cpf, cod_endereco, nome_tutor, email, telefone) VALUES 
('11111111111', 1, 'Paulo', 't1@email.com', '79999990001'),
('22222222222', 2, 'Maria', 't2@email.com', '79999990002'),
('33333333333', 3, 'Carlos', 't3@email.com', '79999990003'),
('44444444444', 4, 'Pedro', 't4@email.com', '79999990004'),
('55555555555', 5, 'Bianca', 't5@email.com', '79999990005');

-- 7. Pets
INSERT INTO oltp.pet (cod_tutor, nome, especie, porte, sexo) VALUES 
(1, 'Rex', 'Cachorro', 'Grande', 'M'),
(2, 'Luna', 'Gato', 'Pequeno', 'F'),
(3, 'Thor', 'Cachorro', 'Médio', 'M'),
(4, 'Mia', 'Gato', 'Pequeno', 'F'),
(5, 'Bob', 'Cachorro', 'Pequeno', 'M');

-- 8. Quadros Clínicos
INSERT INTO oltp.quadro_clinico (situacao_inicial, situacao_final) VALUES 
('Checkup anual', 'Vacinas em dia'),
('Vômitos constantes', 'Intolerância alimentar'),
('Ferimento na pata', 'Curativo realizado'),
('Apatia', 'Vitaminas prescritas'),
('Limpeza de ouvidos', 'Procedimento concluído');

-- 9. Atendimentos
INSERT INTO oltp.atendimento (cod_tipo_servico, cod_filial, cod_funcionario, cod_tutor, cod_pet, cod_quadro_clinico, data_inicio, data_fim, prioridade) VALUES 
(1, 1, 1, 1, 1, 1, '2026-07-16 08:00:00', '2026-07-16 09:00:00', 'Baixa'),
(2, 2, 2, 2, 2, 2, '2026-07-16 09:00:00', '2026-07-16 10:00:00', 'Alta'),
(5, 3, 3, 3, 3, 3, '2026-07-16 10:00:00', '2026-07-16 12:00:00', 'Alta'),
(3, 4, 5, 4, 4, 4, '2026-07-16 14:00:00', '2026-07-16 14:30:00', 'Média'),
(1, 5, 1, 5, 5, 5, '2026-07-16 15:00:00', '2026-07-16 16:00:00', 'Baixa');
GO

SELECT * FROM oltp.quadro_clinico
SELECT * FROM oltp.tipo_servico
SELECT * FROM oltp.endereco
SELECT * FROM oltp.filial
SELECT * FROM oltp.funcionario
SELECT * FROM oltp.funcao
SELECT * FROM oltp.tutor
SELECT * FROM oltp.pet
SELECT * FROM oltp.atendimento

/* ============================================================
   6. ÁREA DE STAGING

   A staging armazena uma fotografia dos dados operacionais
   para cada data de carga.

   Ao reprocessar uma data:
   - somente os registros daquela data são removidos;
   - as demais cargas são preservadas.
   ============================================================ */

   CREATE TABLE staging.stg_tipo_servico (
       cod_tipo_servico INT NOT NULL,
       nome_tipo_servico VARCHAR(100) NOT NULL,
       data_carga DATE NOT NULL
   );

   CREATE TABLE staging.stg_filial (
        cod_filial INT NOT NULL,
        cod_endereco INT NOT NULL,
        nome_filial VARCHAR(100) NOT NULL,
        data_carga DATE NOT NULL
   );

   CREATE TABLE staging.stg_funcionario (
        cod_funcionario INT NOT NULL,
        cod_endereco INT,
        matricula INT NOT NULL,
        nome_funcionario VARCHAR(100) NOT NULL,
        CRMV VARCHAR(100) NULL,
        data_carga DATE NOT NULL
    );

   CREATE TABLE staging.stg_tutor(
     cod_tutor INT NOT NULL,
     cpf VARCHAR(11) NOT NULL,
     cod_endereco INT NOT NULL,
     nome_tutor VARCHAR(100) NOT NULL,
     email VARCHAR(100) NOT NULL,
     telefone VARCHAR(100) NOT NULL,
     data_carga DATE NOT NULL    
    );

  CREATE TABLE staging.stg_pet(
    cod_pet INT NOT NULL,
    cod_tutor INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    especie VARCHAR(100) NOT NULL,
    porte VARCHAR(100) NOT NULL,
    sexo CHAR(1) NOT NULL,
    data_carga DATE NOT NULL   
);


 CREATE TABLE staging.stg_quadro_clinico(
    cod_quadro_clinico INT NOT NULL,
    cod_pet INT NOT NULL,
    situacao_inicial VARCHAR(500) NOT NULL, 
    situacao_final VARCHAR(500),
    data_carga DATE NOT NULL 
);

CREATE TABLE staging.stg_atendimento (
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
    valor DECIMAL(10,2) DEFAULT 0.00,
    data_carga DATE NOT NULL     
);
GO

/* Índices para facilitar a localização dos dados de uma carga. */

CREATE INDEX ix_stg_atendimento_data_carga ON  staging.stg_atendimento(data_carga);
CREATE INDEX ix_stg_quadro_clinico_data_carga ON staging.stg_quadro_clinico(data_carga);
CREATE INDEX ix_stg_filial_data_carga ON staging.stg_filial(data_carga);
CREATE INDEX ix_stg_tipo_servico_data_carga ON staging.stg_tipo_servico(data_carga);
CREATE INDEX ix_stg_funcionario_data_carga ON staging.stg_funcionario(data_carga);
CREATE INDEX ix_stg_tutor_data_carga ON staging.stg_tutor(data_carga);
CREATE INDEX ix_stg_pet_data_carga ON staging.stg_pet(data_carga);
GO
   
/* ============================================================
   7. AMBIENTE DIMENSIONAL
   ============================================================ */

   /* ============================================================
   7.1 DIMENSÃO FUNCIONÁRIO e DIMENSÃO TUTOR 

   Estratégia SCD Tipo 2.

   Quando um atributo histórico for alterado:
   - a versão atual será encerrada;
   - uma nova versão será criada;
   - o histórico será preservado.
   ============================================================ */
   CREATE TABLE dw.dim_funcionario (
        id_funcionario INT IDENTITY(1,1) PRIMARY KEY,
        cod_funcionario INT NOT NULL,
        matricula INT NOT NULL,
        nome_funcionario VARCHAR(100) NOT NULL,
        CRMV VARCHAR(100) NULL,
        cidade VARCHAR(100) NOT NULL,
        data_inicio DATE NOT NULL,
        data_fim DATE NULL,
        registro_atual BIT NOT NULL
    );

   CREATE TABLE dw.dim_tutor(
     id_tutor INT IDENTITY(1,1) PRIMARY KEY,
     cod_tutor INT NOT NULL,
     cpf VARCHAR(11) NOT NULL,
     cod_endereco INT NOT NULL,
     nome_tutor VARCHAR(100) NOT NULL,
     email VARCHAR(100) NOT NULL,
     telefone VARCHAR(100) NOT NULL,
     cidade VARCHAR(100) NOT NULL,
     data_inicio DATE NOT NULL,
     data_fim DATE NULL,
     registro_atual BIT NOT NULL
  );


   /* ============================================================
   7.3 DIMENSÃO TEMPO

   A dimensão tempo é carregada separadamente.

   id_tempo:
   - chave substituta;
   - valor gerado automaticamente por IDENTITY.

   data_completa:
   - representa a chave natural da dimensão.
   ============================================================ */

CREATE TABLE dw.dim_tempo (
    id_tempo INT IDENTITY(1,1) PRIMARY KEY,
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
   7.4 DIMENSÃO SERVIÇO

   Implementação da estratégia SCD Tipo 1.

   Etapas:
   1. atualiza os registros existentes;
   2. insere os novos registros.
   ============================================================ */

   CREATE TABLE dw.dim_tipo_servico (
       id_servico INT IDENTITY(1,1) PRIMARY KEY,
       cod_tipo_servico INT NOT NULL,
       nome_tipo_servico VARCHAR(100) NOT NULL,
       data_atualizacao DATE NOT NULL,
       CONSTRAINT uq_dim_servico_cod_tipo_servico UNIQUE (cod_tipo_servico)
   );

<<<<<<< Updated upstream
 /* ============================================================
   7.5 DIMENSÃO FILIAL
=======

   /* ============================================================
   7.6 DIMENSÃO PET

   Implementação da estratégia SCD Tipo 2.

   Etapas:
   1. atualiza os registros existentes;
   2. insere os novos registros.
   ============================================================ */
  CREATE TABLE dw.dim_pet(
    id_pet INT IDENTITY(1,1) PRIMARY KEY,
    cod_pet INT,
    nome VARCHAR(100) NOT NULL,
    especie VARCHAR(100) NOT NULL,
    porte VARCHAR(100) NOT NULL,
    sexo CHAR(1) NOT NULL,
    data_inicio DATE NOT NULL,
    data_fim DATE NULL,
    registro_atual BIT NOT NULL
    CHECK (Sexo IN ('F', 'M', 'f', 'm'))
);


>>>>>>> Stashed changes

     Estratégia SCD Tipo 2.

   Quando um atributo histórico for alterado:
   - a versão atual será encerrada;
   - uma nova versão será criada;
   - o histórico será preservado.
   ============================================================ */  
  
  CREATE TABLE dw.dim_filial (
        id_filial INT IDENTITY(1,1) PRIMARY KEY,
        cod_filial INT NOT NULL,
        cod_endereco INT NOT NULL,
        nome_filial VARCHAR(100) NOT NULL,
        data_inicio DATE NOT NULL,
        data_fim DATE NULL,
        registro_atual BIT NOT NULL
   );

/* ============================================================
   7.8 TABELA FATO

   Granularidade:
   - uma linha para cada atendimento.

   Medidas:
   - 
   - .

   Dimensão tempo:
   - 
   - .
   ============================================================ */
   CREATE TABLE dw.fato_atendimento (
    id_atendimento BIGINT IDENTITY(1,1) PRIMARY KEY,
    cod_tipo_servico INT NOT NULL,
    id_filial INT NOT NULL,
    id_funcionario INT NOT NULL,
    id_tutor INT NOT NULL,
    id_pet INT NOT NULL,
    id_quadro_clinico INT NOT NULL,
    id_tempo_abertura INT NOT NULL,
    id_tempo_fechamento INT NOT NULL,
    prioridade VARCHAR(20) NOT NULL,
    quantidade INT NOT NULL,
    valor DECIMAL(10,2) DEFAULT 0.00,
    data_carga DATE NOT NULL,

    CONSTRAINT uq_fato_atendimento_cod_incidente UNIQUE (cod_incidente),
    CONSTRAINT fk_atendimento_tipo_servico FOREIGN KEY (cod_tipo_servico) REFERENCES oltp.tipo_servico(cod_tipo_servico),
    CONSTRAINT fk_atendimento_filial FOREIGN KEY (cod_filial) REFERENCES oltp.filial(cod_filial),
    CONSTRAINT fk_atendimento_funcionario FOREIGN KEY (cod_funcionario) REFERENCES oltp.funcionario(cod_funcionario),
    CONSTRAINT fk_atendimento_tutor FOREIGN KEY (cod_tutor) REFERENCES oltp.tutor(cod_tutor),
    CONSTRAINT fk_atendimento_pet FOREIGN KEY (cod_pet) REFERENCES oltp.pet(cod_pet),
    CONSTRAINT fk_atendimento_quadro_clinico FOREIGN KEY (cod_quadro_clinico) REFERENCES oltp.quadro_clinico(cod_quadro_clinico)
);





