CREATE TABLE lancamentos (
    id_lancamento INT PRIMARY KEY,
    data          DATE,
    tipo          VARCHAR(10),
    categoria     VARCHAR(50),
    contraparte   VARCHAR(150),
    valor         NUMERIC(12,2)
);

CREATE TABLE extrato (
    id_extrato           INT PRIMARY KEY,
    data                 DATE,
    descricao            VARCHAR(200),
    tipo                 VARCHAR(10),
    valor                NUMERIC(12,2),
    possivel_duplicidade BOOLEAN
);
