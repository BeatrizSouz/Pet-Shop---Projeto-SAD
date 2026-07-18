/*
Agregado de distribuição de pets por Espécie

*/
IF NOT EXISTS (
    SELECT
        1
    FROM
        sys.schemas
    WHERE
        name = 'ag'
) EXEC ('CREATE SCHEMA ag');

CREATE TABLE
    ag.dim_pet (
        id_pet INT IDENTITY (1, 1) PRIMARY KEY,
        cod_pet INT NOT NULL,
        especie VARCHAR(100) NOT NULL
    );


CREATE TABLE
    ag.dim_tempo (
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

CREATE TABLE 
		ag.fato_especie(
		id_fato_especie BIGINT IDENTITY (1, 1) PRIMARY KEY,
		id_data INT NOT NULL,
        id_pet_especie INT NOT NULL,
        quantidade INT DEFAULT 1
        CONSTRAINT fk_data FOREIGN KEY (id_data) REFERENCES ag.dim_tempo(id_tempo),
        CONSTRAINT fk_especie FOREIGN KEY (id_pet_especie) REFERENCES ag.dim_pet(id_pet)
);