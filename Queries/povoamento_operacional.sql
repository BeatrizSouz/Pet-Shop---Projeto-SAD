GO

SELECT * FROM oltp.quadro_clinico

/* ============================================================
   5. DADOS INICIAIS DO AMBIENTE OPERACIONAL (5 REGISTROS)
   ============================================================ */

-- 1. Endere�os
INSERT INTO oltp.endereco (cep, estado, cidade, rua, numero, complemento) VALUES 
('49001000', 'SE', 'Aracaju', 'Av. Hermes Fontes', 100, 'Apto 101'),
('49001001', 'SE', 'Aracaju', 'Rua Bahia', 205, NULL),
('49001002', 'SE', 'Aracaju', 'Av. Ivo do Prado', 50, 'Loja B'),
('49001003', 'SE', 'Aracaju', 'Rua Itabaiana', 800, 'Edif�cio Comercial'),
('49001004', 'SE', 'Aracaju', 'Av. Augusto Franco', 120, 'Casa');

-- 2. Tipos de Servi�o

INSERT INTO oltp.tipo_servico (nome_tipo_servico,valor_servico) VALUES 
('Banho e Tosa',90.00),
('Consulta Veterin�ria',60.00),
('Vacina��o',40.00),
('Aplica��o de Medicamento',50.00),
('Cirurgia',30.00);
-- 3. Filiais
INSERT INTO oltp.filial (cod_endereco, nome_filial) VALUES 
(1, 'Filial Centro'), (2, 'Filial Sul'), (3, 'Filial Norte'), (4, 'Filial Leste'), (5, 'Filial Jardins');

-- 4. Funcion�rios
INSERT INTO oltp.funcionario (cod_endereco, matricula, nome_funcionario, CRMV) VALUES 
(1, 101, 'Ana Paula', NULL),
(2, 102, 'Ricardo Silva', 'CRM-SE 111'),
(3, 103, 'Fernanda Lima', 'CRM-SE 222'),
(4, 104, 'Marcos Oliveira', NULL),
(5, 105, 'Patr�cia Rocha', 'CRM-SE 333');

-- 5. Fun��es
INSERT INTO oltp.funcao (cod_funcionario, funcao) VALUES 
(1, 'Atendente'), (2, 'Veterin�rio'), (3, 'Veterin�rio'), (4, 'Auxiliar'), (5, 'Veterin�rio');

-- 6. Tutores
INSERT INTO oltp.tutor (cpf, cod_endereco, nome_tutor, email, telefone) VALUES 
('11111111111', 1, 'Paulo', 't1@email.com', '79999990001'),
('22222222222', 2, 'Maria', 't2@email.com', '79999990002'),
('33333333333', 3, 'Carlos', 't3@email.com', '79999990003'),
('44444444444', 4, 'Pedro', 't4@email.com', '79999990004'),
('55555555555', 5, 'Bianca', 't5@email.com', '79999990005');

-- 7. Pets
INSERT INTO oltp.pet (cod_tutor, nome, especie, raca, porte, sexo) VALUES 
(1, 'Rex', 'Cachorro', 'Vira-lata', 'Grande', 'M'),
(2, 'Luna', 'Gato', 'Siamês', 'Pequeno', 'F'),
(3, 'Thor', 'Cachorro', 'Pitbull', 'Médio', 'M'),
(4, 'Mia', 'Gato', 'Persa', 'Pequeno', 'F'),
(5, 'Bob', 'Cachorro', 'Poodle', 'Pequeno', 'M');

-- 8. Quadros Cl�nicos
INSERT INTO oltp.quadro_clinico (situacao_inicial, situacao_final) VALUES 
('Checkup anual', 'Vacinas em dia'),
('V�mitos constantes', 'Intoler�ncia alimentar'),
('Ferimento na pata', 'Curativo realizado'),
('Apatia', 'Vitaminas prescritas'),
('Limpeza de ouvidos', 'Procedimento conclu�do');

-- 9. Atendimentos
INSERT INTO oltp.atendimento (cod_tipo_servico, cod_filial, cod_funcionario, cod_tutor, cod_pet, cod_quadro_clinico, data_inicio, data_fim, prioridade) VALUES 
(1, 1, 1, 1, 1, 1, '2026-07-16 08:00:00', '2026-07-16 09:00:00', 'Baixa'),
(2, 2, 2, 2, 2, 2, '2026-07-16 09:00:00', '2026-07-16 10:00:00', 'Alta'),
(5, 3, 3, 3, 3, 3, '2026-07-16 10:00:00', '2026-07-16 12:00:00', 'Alta'),
(3, 4, 5, 4, 4, 4, '2026-07-16 14:00:00', '2026-07-16 14:30:00', 'M�dia'),
(1, 5, 1, 5, 5, 5, '2026-07-16 15:00:00', '2026-07-16 16:00:00', 'Baixa');
GO