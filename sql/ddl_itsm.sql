-- DDL das tabelas do banco de destino (schema itsm). Apenas criação, sem carga de dados.
-- Ajustes em relação ao script exportado: índices sem o prefixo [db-univille] (hífen exige colchetes)
-- e sem as opções que já são o padrão do SQL Server (inclusive "ON [PRIMARY ]", com espaço, inválido).

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'itsm')
    EXEC('CREATE SCHEMA itsm');
GO

CREATE TABLE itsm.categoria (
    id_categoria int IDENTITY(1,1) NOT NULL,
    cd_categoria nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    nm_categoria nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    ds_descricao nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    fl_ativo bit DEFAULT 1 NOT NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT UQ_itsm_categoria_cd UNIQUE (cd_categoria)
);
GO

CREATE TABLE itsm.cliente_organizacao (
    id_cliente_organizacao int IDENTITY(1,1) NOT NULL,
    cd_cliente_organizacao nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    nm_cliente_organizacao nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    nr_cnpj nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    fl_ativo bit DEFAULT 1 NOT NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_cliente_organizacao PRIMARY KEY (id_cliente_organizacao),
    CONSTRAINT UQ_itsm_cliente_organizacao_cd UNIQUE (cd_cliente_organizacao)
);
GO

CREATE TABLE itsm.csat (
    Id int NOT NULL,
    Column1 nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    Column2 int NULL,
    CONSTRAINT PK__csat__3214EC074D91B16F PRIMARY KEY (Id)
);
GO

CREATE TABLE itsm.fila (
    id_fila int IDENTITY(1,1) NOT NULL,
    cd_fila nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    nm_fila nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    ds_descricao nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    fl_ativo bit DEFAULT 1 NOT NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_fila PRIMARY KEY (id_fila),
    CONSTRAINT UQ_itsm_fila_cd UNIQUE (cd_fila)
);
GO

CREATE TABLE itsm.sla (
    id_sla int IDENTITY(1,1) NOT NULL,
    cd_sla nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    nm_sla nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    qt_meta_minutos int NOT NULL,
    ds_descricao nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    fl_ativo bit DEFAULT 1 NOT NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_sla PRIMARY KEY (id_sla),
    CONSTRAINT UQ_itsm_sla_cd UNIQUE (cd_sla)
);
GO

CREATE TABLE itsm.analista (
    id_analista int IDENTITY(1,1) NOT NULL,
    cd_analista nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    nm_analista nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    ds_email nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ds_nivel nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    id_fila_atual int NULL,
    fl_ativo bit DEFAULT 1 NOT NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_analista PRIMARY KEY (id_analista),
    CONSTRAINT UQ_itsm_analista_cd UNIQUE (cd_analista),
    CONSTRAINT FK_itsm_analista_fila FOREIGN KEY (id_fila_atual) REFERENCES itsm.fila(id_fila)
);
CREATE NONCLUSTERED INDEX IX_itsm_analista_fila ON itsm.analista (id_fila_atual ASC);
ALTER TABLE itsm.analista WITH NOCHECK ADD CONSTRAINT CK_itsm_analista_nivel CHECK (([ds_nivel]='N3' OR [ds_nivel]='N2' OR [ds_nivel]='N1'));
GO

CREATE TABLE itsm.solicitante (
    id_solicitante int IDENTITY(1,1) NOT NULL,
    cd_solicitante nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    id_cliente_organizacao int NOT NULL,
    nm_solicitante nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    ds_email nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ds_telefone nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    fl_ativo bit DEFAULT 1 NOT NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_solicitante PRIMARY KEY (id_solicitante),
    CONSTRAINT UQ_itsm_solicitante_cd UNIQUE (cd_solicitante),
    CONSTRAINT FK_itsm_solicitante_cliente_org FOREIGN KEY (id_cliente_organizacao) REFERENCES itsm.cliente_organizacao(id_cliente_organizacao)
);
CREATE NONCLUSTERED INDEX IX_itsm_solicitante_cliente_org ON itsm.solicitante (id_cliente_organizacao ASC);
GO

CREATE TABLE itsm.chamado (
    id_chamado bigint IDENTITY(1,1) NOT NULL,
    nr_chamado nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    ds_tipo_chamado nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    ds_status_chamado nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    ds_prioridade nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    dt_criacao datetime2(0) NOT NULL,
    dt_resolucao datetime2(0) NULL,
    dt_ultima_atualizacao datetime2(0) NOT NULL,
    id_analista_atual int NULL,
    id_reporter int NOT NULL,
    id_categoria int NULL,
    id_cliente_organizacao int NOT NULL,
    id_fila_atual int NULL,
    ds_titulo nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ds_descricao nvarchar(MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_chamado PRIMARY KEY (id_chamado),
    CONSTRAINT UQ_itsm_chamado_nr UNIQUE (nr_chamado),
    CONSTRAINT FK_itsm_chamado_analista FOREIGN KEY (id_analista_atual) REFERENCES itsm.analista(id_analista),
    CONSTRAINT FK_itsm_chamado_categoria FOREIGN KEY (id_categoria) REFERENCES itsm.categoria(id_categoria),
    CONSTRAINT FK_itsm_chamado_cliente_org FOREIGN KEY (id_cliente_organizacao) REFERENCES itsm.cliente_organizacao(id_cliente_organizacao),
    CONSTRAINT FK_itsm_chamado_fila FOREIGN KEY (id_fila_atual) REFERENCES itsm.fila(id_fila),
    CONSTRAINT FK_itsm_chamado_reporter FOREIGN KEY (id_reporter) REFERENCES itsm.solicitante(id_solicitante)
);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_analista ON itsm.chamado (id_analista_atual ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_categoria ON itsm.chamado (id_categoria ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_cliente_org ON itsm.chamado (id_cliente_organizacao ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_criacao ON itsm.chamado (dt_criacao ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_fila ON itsm.chamado (id_fila_atual ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_prioridade ON itsm.chamado (ds_prioridade ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_reporter ON itsm.chamado (id_reporter ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_resolucao ON itsm.chamado (dt_resolucao ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_status ON itsm.chamado (ds_status_chamado ASC);
ALTER TABLE itsm.chamado WITH NOCHECK ADD CONSTRAINT CK_itsm_chamado_tipo CHECK (([ds_tipo_chamado]='TASK' OR [ds_tipo_chamado]='CHANGE' OR [ds_tipo_chamado]='PROBLEM' OR [ds_tipo_chamado]='REQUEST' OR [ds_tipo_chamado]='INCIDENT'));
ALTER TABLE itsm.chamado WITH NOCHECK ADD CONSTRAINT CK_itsm_chamado_status CHECK (([ds_status_chamado]='CANCELLED' OR [ds_status_chamado]='CLOSED' OR [ds_status_chamado]='RESOLVED' OR [ds_status_chamado]='PENDING' OR [ds_status_chamado]='IN_PROGRESS' OR [ds_status_chamado]='OPEN'));
ALTER TABLE itsm.chamado WITH NOCHECK ADD CONSTRAINT CK_itsm_chamado_prioridade CHECK (([ds_prioridade]='CRITICAL' OR [ds_prioridade]='HIGH' OR [ds_prioridade]='MEDIUM' OR [ds_prioridade]='LOW'));
GO

CREATE TABLE itsm.chamado_sla (
    id_chamado_sla bigint IDENTITY(1,1) NOT NULL,
    id_chamado bigint NOT NULL,
    id_sla int NOT NULL,
    fl_breach bit NOT NULL,
    qt_tempo_restante_minutos int NULL,
    qt_tempo_decorrido_minutos int NULL,
    qt_meta_minutos int NOT NULL,
    dt_referencia datetime2(0) NOT NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_chamado_sla PRIMARY KEY (id_chamado_sla),
    CONSTRAINT FK_itsm_chamado_sla_chamado FOREIGN KEY (id_chamado) REFERENCES itsm.chamado(id_chamado),
    CONSTRAINT FK_itsm_chamado_sla_sla FOREIGN KEY (id_sla) REFERENCES itsm.sla(id_sla)
);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_sla_breach ON itsm.chamado_sla (fl_breach ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_sla_chamado ON itsm.chamado_sla (id_chamado ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_sla_sla ON itsm.chamado_sla (id_sla ASC);
GO

CREATE TABLE itsm.chamado_status_historico (
    id_chamado_status_historico bigint IDENTITY(1,1) NOT NULL,
    id_chamado bigint NOT NULL,
    ds_status_chamado nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    dt_inicio_status datetime2(0) NOT NULL,
    dt_fim_status datetime2(0) NULL,
    qt_tempo_status_minutos int NULL,
    id_analista_responsavel int NULL,
    id_fila int NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_chamado_status_historico PRIMARY KEY (id_chamado_status_historico),
    CONSTRAINT FK_itsm_chamado_status_hist_analista FOREIGN KEY (id_analista_responsavel) REFERENCES itsm.analista(id_analista),
    CONSTRAINT FK_itsm_chamado_status_hist_chamado FOREIGN KEY (id_chamado) REFERENCES itsm.chamado(id_chamado),
    CONSTRAINT FK_itsm_chamado_status_hist_fila FOREIGN KEY (id_fila) REFERENCES itsm.fila(id_fila)
);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_status_hist_chamado ON itsm.chamado_status_historico (id_chamado ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_status_hist_inicio ON itsm.chamado_status_historico (dt_inicio_status ASC);
CREATE NONCLUSTERED INDEX IX_itsm_chamado_status_hist_status ON itsm.chamado_status_historico (ds_status_chamado ASC);
ALTER TABLE itsm.chamado_status_historico WITH NOCHECK ADD CONSTRAINT CK_itsm_chamado_status_hist_status CHECK (([ds_status_chamado]='CANCELLED' OR [ds_status_chamado]='CLOSED' OR [ds_status_chamado]='RESOLVED' OR [ds_status_chamado]='PENDING' OR [ds_status_chamado]='IN_PROGRESS' OR [ds_status_chamado]='OPEN'));
GO

CREATE TABLE itsm.csat_avaliacao (
    id_csat_avaliacao bigint IDENTITY(1,1) NOT NULL,
    id_chamado bigint NOT NULL,
    id_analista int NULL,
    nr_score int NOT NULL,
    ds_comentario nvarchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    dt_avaliacao datetime2(0) NOT NULL,
    dt_inclusao datetime2(0) DEFAULT sysutcdatetime() NOT NULL,
    dt_atualizacao datetime2(0) NULL,
    nm_sistema_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    cd_registro_origem nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_itsm_csat_avaliacao PRIMARY KEY (id_csat_avaliacao),
    CONSTRAINT FK_itsm_csat_analista FOREIGN KEY (id_analista) REFERENCES itsm.analista(id_analista),
    CONSTRAINT FK_itsm_csat_chamado FOREIGN KEY (id_chamado) REFERENCES itsm.chamado(id_chamado)
);
CREATE NONCLUSTERED INDEX IX_itsm_csat_analista ON itsm.csat_avaliacao (id_analista ASC);
CREATE NONCLUSTERED INDEX IX_itsm_csat_chamado ON itsm.csat_avaliacao (id_chamado ASC);
CREATE NONCLUSTERED INDEX IX_itsm_csat_data ON itsm.csat_avaliacao (dt_avaliacao ASC);
ALTER TABLE itsm.csat_avaliacao WITH NOCHECK ADD CONSTRAINT CK_itsm_csat_score CHECK (([nr_score]>=(1) AND [nr_score]<=(5)));
GO
