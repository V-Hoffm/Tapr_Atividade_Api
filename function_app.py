import logging
import os
from functools import lru_cache

import azure.functions as func
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


def extrair_tabela(nome_tabela: str) -> int:
    """Captura todos os dados de uma tabela e retorna a quantidade de registros."""
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
    for linha in linhas:
        logging.debug("[%s] %s", nome_tabela, dict(linha))
    return len(linhas)


@app.timer_trigger(
    schedule="0 */1 * * * *", arg_name="timer", run_on_startup=True, use_monitor=False
)
def ler_tabelas(timer: func.TimerRequest) -> None:
    """Uma única function que extrai todas as tabelas do banco itsm."""
    falhas = []
    for nome_tabela in TABELAS:
        try:
            extrair_tabela(nome_tabela)
        except Exception:
            logging.exception("[%s] falha na extração", nome_tabela)
            falhas.append(nome_tabela)

    if falhas:
        raise RuntimeError(f"Falha ao extrair: {', '.join(falhas)}")
