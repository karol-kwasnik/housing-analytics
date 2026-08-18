CREATE SCHEMA ref;
GO

CREATE TABLE ref.variable (
    variable_id     INT           NOT NULL PRIMARY KEY,
    name            NVARCHAR(400) NOT NULL,
    subject_id      VARCHAR(20)   NOT NULL,
    category        VARCHAR(50)   NULL,
    measure         VARCHAR(50)   NULL,
    unit_of_measure NVARCHAR(50)  NULL,
    unit_level      INT           NOT NULL,
    dimension_1     NVARCHAR(200) NULL,
    dimension_2     NVARCHAR(200) NULL,
    is_active       BIT           NOT NULL DEFAULT 1,
    modified_at     DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE ref.ingestion_config (
    config_id      INT IDENTITY(1,1) PRIMARY KEY,
    variable_id    INT       NOT NULL,
    unit_level     INT       NOT NULL,
    year_from      INT       NULL,
    year_to        INT       NULL,
    is_active      BIT       NOT NULL DEFAULT 1,
    last_loaded_at DATETIME2 NULL,
    CONSTRAINT fk_config_variable FOREIGN KEY (variable_id)
        REFERENCES ref.variable(variable_id),
    CONSTRAINT uq_config_variable_level UNIQUE (variable_id, unit_level)
);

CREATE TABLE ref.quality_attribute (
    attribute_id INT           NOT NULL PRIMARY KEY,
    name         NVARCHAR(50)  NULL,
    symbol       NVARCHAR(10)  NULL,
    description  NVARCHAR(500) NULL,
    is_value     BIT           NOT NULL
);

CREATE TABLE ref.ingestion_log (
    log_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
    batch_id    VARCHAR(50)   NOT NULL,
    variable_id INT           NULL,
    status      VARCHAR(20)   NOT NULL,
    row_count   INT           NULL,
    started_at  DATETIME2     NOT NULL,
    finished_at DATETIME2     NULL,
    message     NVARCHAR(MAX) NULL
);

CREATE INDEX ix_ingestion_log_batch ON ref.ingestion_log (batch_id);

CREATE TABLE ref.county_classification (
    teryt_code    VARCHAR(12)   NOT NULL PRIMARY KEY,
    name          NVARCHAR(200) NOT NULL,
    voivodeship   NVARCHAR(100) NULL,
    county_type   VARCHAR(30)   NULL,
    agglomeration NVARCHAR(100) NULL,
    geo_name      NVARCHAR(300) NULL,
    latitude      DECIMAL(9,6)  NULL,
    longitude     DECIMAL(9,6)  NULL
);

CREATE TABLE ref.credit_parameter (
    parameter_name  VARCHAR(50)   NOT NULL PRIMARY KEY,
    parameter_value DECIMAL(10,4) NOT NULL,
    description     NVARCHAR(200) NULL
);

INSERT INTO ref.credit_parameter VALUES
('bank_margin',        0.0200, 'Margin over reference rate'),
('min_down_payment',   0.2000, 'Minimum down payment share'),
('loan_years',        25,      'Default loan period'),
('base_floor_area',   50,      'Floor area used in simulation'),
('net_to_gross',       0.7200, 'Net to gross salary ratio');
GO
