import csv
import io
import logging
import os
from datetime import datetime, timezone
from functools import lru_cache

import azure.functions as func
from azure.storage.blob import BlobServiceClient, ContentSettings
from sqlalchemy import MetaData, Table, create_engine, select
from sqlalchemy.engine import URL, Engine

app = func.FunctionApp()

TABELAS = [
    "analista",
    "categoria",
    "chamado",
    "chamado_sla",
    "chamado_status_historico",
    "cliente_organizacao",
    "csat_avaliacao",
    "fila",
    "sla",
    "solicitante",
]


@lru_cache(maxsize=1)
def get_engine() -> Engine:
    """Cria o engine uma única vez, usando apenas variáveis de ambiente."""
    url = URL.create(
        "mssql+pymssql",
        username=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "1433")),
        database=os.environ["DB_NAME"],
    )
    return create_engine(url, pool_pre_ping=True)


@lru_cache(maxsize=1)
def get_container():
    """Cliente do container Bronze, configurado só por variáveis de ambiente."""
    servico = BlobServiceClient.from_connection_string(os.environ["STORAGE_CONNECTION_STRING"])
    return servico.get_container_client(os.environ.get("BRONZE_CONTAINER", "bronze"))


def montar_caminho(nome_tabela: str, momento: datetime) -> str:
    """itsm/<entidade>/ano=AAAA/mes=MM/dia=DD/<entidade>_AAAAMMDDTHHMMSSZ.csv

    As "pastas" são criadas automaticamente pelo nome do blob: quando a data da
    extração muda, o novo caminho (ano/mes/dia) passa a existir sozinho.
    """
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


def extrair_tabela(nome_tabela: str, momento: datetime) -> int:
    """Captura todos os dados de uma tabela, grava o CSV no Bronze e retorna a quantidade."""
    engine = get_engine()
    tabela = Table(
        nome_tabela,
        MetaData(),
        schema=os.environ.get("DB_SCHEMA"),
        autoload_with=engine,
    )

    with engine.connect() as conn:
        linhas = conn.execute(select(tabela)).mappings().all()

    logging.info("[%s] %d registros capturados", nome_tabela, len(linhas))

    caminho = montar_caminho(nome_tabela, momento)
    conteudo = gerar_csv([c.name for c in tabela.columns], linhas)
    get_container().upload_blob(
        name=caminho,
        data=conteudo.encode("utf-8"),
        overwrite=True,
        content_settings=ContentSettings(content_type="text/csv"),
    )
    logging.info("[%s] salvo em %s", nome_tabela, caminho)
    return len(linhas)


@app.timer_trigger(
    schedule="0 */1 * * * *", arg_name="timer", run_on_startup=True, use_monitor=False
)
def ler_tabelas(timer: func.TimerRequest) -> None:
    """Uma única function que extrai todas as tabelas do banco itsm."""
    momento = datetime.now(timezone.utc)
    falhas = []
    for nome_tabela in TABELAS:
        try:
            extrair_tabela(nome_tabela, momento)
        except Exception:
            logging.exception("[%s] falha na extração", nome_tabela)
            falhas.append(nome_tabela)

    if falhas:
        raise RuntimeError(f"Falha ao extrair: {', '.join(falhas)}")