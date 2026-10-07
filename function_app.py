import logging
import os
import azure.functions as func
from sqlalchemy import MetaData, Table, create_engine, select
from sqlalchemy.engine import URL

app = func.FunctionApp()

@app.timer_trigger(schedule="0 */1 * * * *", arg_name="timer", run_on_startup=True, use_monitor=False)
def ler_tabela(timer: func.TimerRequest) -> None:
    url = URL.create(
        "mssql+pymssql",
        username=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        host=os.environ.get("DB_HOST", "sv-univille-ca.database.windows.net"),
        port=1433,
        database=os.environ.get("DB_NAME", "db-univille"),
    )
    engine = create_engine(url)
    tabela = Table(os.environ.get("DB_TABLE", "categoria"), MetaData(), schema=os.environ.get("DB_SCHEMA"), autoload_with=engine)

    with engine.connect() as conn:
        linhas = conn.execute(select(tabela)).mappings().all()

    logging.info("%d registros capturados", len(linhas))
    for linha in linhas:
        logging.info(dict(linha))