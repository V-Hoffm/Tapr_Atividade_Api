import csv
import io
import logging
import os
from datetime import datetime, timezone
from functools import lru_cache

import azure.functions as func
from azure.storage.blob import BlobServiceClient, ContentSettings
from sqlalchemy import MetaData, Table, and_, bindparam, create_engine, insert, select, update
from sqlalchemy.engine import URL, Engine

app = func.FunctionApp()


TABELAS = [
    "categoria",
    "cliente_organizacao",
    "fila",
    "sla",
    "analista",
    "solicitante",
    "chamado",
    "chamado_sla",
    "chamado_status_historico",
    "csat_avaliacao",
]

TAMANHO_LOTE = 1000


def criar_engine(prefixo: str) -> Engine:
    url = URL.create(
        "mssql+pymssql",
        username=os.environ[f"{prefixo}_USER"],
        password=os.environ[f"{prefixo}_PASSWORD"],
        host=os.environ[f"{prefixo}_HOST"],
        port=int(os.environ.get(f"{prefixo}_PORT", "1433")),
        database=os.environ[f"{prefixo}_NAME"],
    )
    return create_engine(url, pool_pre_ping=True)


@lru_cache(maxsize=1)
def get_engine() -> Engine:
    """Banco de origem (variáveis DB_*)."""
    return criar_engine("DB")


@lru_cache(maxsize=1)
def get_engine_destino() -> Engine:
    """Banco de destino (variáveis DEST_DB_*)."""
    return criar_engine("DEST_DB")


@lru_cache(maxsize=1)
def get_container():
    servico = BlobServiceClient.from_connection_string(os.environ["STORAGE_CONNECTION_STRING"])
    return servico.get_container_client(os.environ.get("BRONZE_CONTAINER", "bronze"))


def montar_caminho(nome_tabela: str, momento: datetime) -> str:
    return (
        f"itsm/{nome_tabela}/"
        f"ano={momento:%Y}/mes={momento:%m}/dia={momento:%d}/"
        f"{nome_tabela}_{momento:%Y%m%dT%H%M%SZ}.csv"
    )


def gerar_csv(colunas: list[str], linhas) -> str:
    buffer = io.StringIO()
    escritor = csv.writer(buffer)
    escritor.writerow(colunas)
    for linha in linhas:
        escritor.writerow([linha[c] for c in colunas])
    return buffer.getvalue()


def ler_origem(nome_tabela: str) -> tuple[list[str], list]:
    engine = get_engine()
    tabela = Table(
        nome_tabela,
        MetaData(),
        schema=os.environ.get("DB_SCHEMA"),
        autoload_with=engine,
    )
    with engine.connect() as conn:
        linhas = conn.execute(select(tabela)).mappings().all()
    return [c.name for c in tabela.columns], linhas


def salvar_bronze(nome_tabela: str, colunas: list[str], linhas: list, momento: datetime) -> None:
    caminho = montar_caminho(nome_tabela, momento)
    get_container().upload_blob(
        name=caminho,
        data=gerar_csv(colunas, linhas).encode("utf-8"),
        overwrite=True,
        content_settings=ContentSettings(content_type="text/csv"),
    )
    logging.info("[%s] %d todos os registros salvos em %s", nome_tabela, len(linhas), caminho)


def em_lotes(itens: list, tamanho: int = TAMANHO_LOTE):
    for i in range(0, len(itens), tamanho):
        yield itens[i : i + tamanho]


def sincronizar_tabela(
    engine: Engine,
    nome_tabela: str,
    schema: str | None,
    colunas_origem: list[str],
    linhas: list,
) -> tuple[int, int]:
    tabela = Table(nome_tabela, MetaData(), schema=schema, autoload_with=engine)
    colunas = [c.name for c in tabela.columns if c.name in colunas_origem]
    chaves = [c.name for c in tabela.primary_key.columns]
    if not chaves or any(k not in colunas for k in chaves):
        raise RuntimeError(f"[{nome_tabela}] chave primária ausente na origem ou no destino.")

    posicao_chaves = [colunas.index(k) for k in chaves]
    novos: list[dict] = []
    alterados: list[dict] = []

    with engine.begin() as conn:
        existentes = {
            tuple(linha[i] for i in posicao_chaves): tuple(linha)
            for linha in conn.execute(select(*[tabela.c[c] for c in colunas]))
        }

        for linha in linhas:
            valores = tuple(linha[c] for c in colunas)
            chave = tuple(linha[k] for k in chaves)
            atual = existentes.get(chave)
            if atual is None:
                novos.append(dict(zip(colunas, valores, strict=True)))
            elif atual != valores:
                alterados.append({f"b_{c}": v for c, v in zip(colunas, valores, strict=True)})

        for lote in em_lotes(novos):
            conn.execute(insert(tabela), lote)

        colunas_dados = [c for c in colunas if c not in chaves]
        if alterados and colunas_dados:
            comando = (
                update(tabela)
                .where(and_(*[tabela.c[k] == bindparam(f"b_{k}") for k in chaves]))
                .values({c: bindparam(f"b_{c}") for c in colunas_dados})
            )
            for lote in em_lotes(alterados):
                conn.execute(comando, lote)

    logging.info(
        "[%s] destino: %d inseridos, %d atualizados, %d sem alteração",
        nome_tabela,
        len(novos),
        len(alterados),
        len(linhas) - len(novos) - len(alterados),
    )
    return len(novos), len(alterados)


@app.timer_trigger(
    schedule="0 0 3 * * *", arg_name="timer", run_on_startup=False, use_monitor=False
)
def ler_tabelas(timer: func.TimerRequest) -> None:
    momento = datetime.now(timezone.utc)
    falhas = []
    carga_ok = True

    for nome_tabela in TABELAS:
        try:
            colunas, linhas = ler_origem(nome_tabela)
        except Exception:
            logging.exception("[%s] falha na leitura da origem", nome_tabela)
            falhas.append(nome_tabela)
            carga_ok = False
            continue

        try:
            salvar_bronze(nome_tabela, colunas, linhas, momento)
        except Exception:
            logging.exception("[%s] falha ao salvar no bronze", nome_tabela)
            falhas.append(f"{nome_tabela} (bronze)")

        if not carga_ok:
            logging.warning("[%s] carga no destino ignorada por falha anterior", nome_tabela)
            continue
        try:
            sincronizar_tabela(
                get_engine_destino(),
                nome_tabela,
                os.environ.get("DEST_DB_SCHEMA", "itsm"),
                colunas,
                linhas,
            )
        except Exception:
            logging.exception("[%s] falha na carga do destino", nome_tabela)
            falhas.append(f"{nome_tabela} (destino)")
            carga_ok = False

    if falhas:
        raise RuntimeError(f"Falhas: {', '.join(falhas)}")
