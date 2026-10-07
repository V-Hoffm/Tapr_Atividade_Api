import logging
import os
import azure.functions as func
from sqlalchemy import MetaData, Table, create_engine, select
from sqlalchemy.engine import URL

app = func.FunctionApp()

@app.timer_trigger(schedule="0 */1 * * * *", arg_name="timer", run_on_startup=True, use_monitor=False)
def ler_tabela(timer: func.TimerRequest) -> None:
    host = os.environ.get("DB_HOST", "sv-univille-ca.database.windows.net")
    database = os.environ.get("DB_NAME", "db-univille")
    usuario = os.environ["DB_USER"]       
    senha = os.environ["DB_PASSWORD"]     
    tabela_nome = os.environ.get("DB_TABLE", "chamado")  
    schema = os.environ.get("DB_SCHEMA")  

    url = URL.create(
        "mssql+pyodbc",
        username=usuario,
        password=senha,
        host=host,
        port=1433,
        database=database,
        query={"driver": "ODBC Driver 18 for SQL Server", "Encrypt": "yes"},
    )
    engine = create_engine(url)

    try:
        tabela = Table(tabela_nome, MetaData(), schema=schema, autoload_with=engine)

        with engine.connect() as conn:
            linhas = conn.execute(select(tabela)).mappings().all()

        logging.info("Conexão OK. %d registros capturados da tabela '%s'.", len(linhas), tabela_nome)
        for linha in linhas:
            logging.info(dict(linha))
    except Exception:
        logging.exception("Erro ao capturar dados da tabela '%s'.", tabela_nome)
        raise
    finally:
        engine.dispose()  # fecha as conexões