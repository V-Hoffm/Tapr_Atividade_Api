import logging
import azure.functions as func
import requests

app = func.FunctionApp()

@app.timer_trigger(schedule="0 */10 * * * *", arg_name="myTimer", run_on_startup=False,
              use_monitor=False) 
def timer_trigger_tarpb(myTimer: func.TimerRequest) -> None:

    logging.info('Deu boa!')

@app.route(route="http_trigger", auth_level=func.AuthLevel.ANONYMOUS)
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    name = req.params.get('name')
    sobrenome = req.params.get('sobrenome')

    if not name and sobrenome:
        try:
            req_body = req.get_json()
        except ValueError:
            pass
        else:
            name = req_body.get('name')
            sobrenome = req_body.get('sobrenome')
    if name and sobrenome:
        return func.HttpResponse(f"Hello, {name} {sobrenome}. This HTTP triggered function executed successfully.")
    else:
        return func.HttpResponse(
             "This HTTP triggered function executed successfully. Pass a name and surname in the query string or in the request body for a personalized response.",
             status_code=200
        )

@app.timer_trigger(schedule="0 */5 * * * *", arg_name="myTimer", run_on_startup=False,
              use_monitor=False) 
def timer_trigger(myTimer: func.TimerRequest) -> None:
    
    if myTimer.past_due:
        logging.info('The timer is past due!')

    logging.info('Python timer trigger function executed.')

    nome_parametro = "Teste 123"

    url = "azfunc-taprb-hoffmann-gehzgebxbjb2g4an.eastus2-01.azurewebsites.net/api/http_trigger?nome=" + nome_parametro + "&sobrenome=Hoffmann"

    response = requests.get(url)

    logging.info(f'Response: {response.text}')
