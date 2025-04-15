from airflow import DAG
from datetime import datetime, timedelta
from google.auth.transport.requests import AuthorizedSession
from google.auth import impersonated_credentials
from google.auth.transport.requests import Request
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.exceptions import AirflowFailException
from airflow.models import Variable
import requests
import json
import google.auth


default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 4, 13),
    'email_on_failure': True,
    'email': ['ratna.kumar62@gmail.com', 'ramvighnesh@gmail.com'],
    'retries': 1,
    'retry_delay': timedelta(minutes=2),
}


dag = DAG(
    "beta_cf_trigger",
    default_args=default_args,
    schedule_interval=None,
    catchup=False
)


def invoke_cloud_function(**kwargs):
    try:
        # Get the credentials
        credentials, _ = google.auth.default()
        
        # If credentials do not support access tokens, we need to refresh them first
        if not credentials.valid:
            credentials.refresh(Request())  # Refresh the credentials if they're not valid
        
        variable = Variable.get("cf_airflow_variable")
        var = json.loads(variable)
        cf_variable = Variable.get("cf_variable")
        cf_json = json.loads(cf_variable)
        print(cf_json)


        url = var["cf_url"]

        # Fetch the access token
        access_token = credentials.token
        
        # Use the token to set the Authorization header
        headers = {"Authorization": f"Bearer {access_token}"}

        # Make the POST request to the Cloud Function
        resp = requests.post(url, json=cf_json, headers=headers)
        print(resp.status_code)
        response = str(resp.content)
        print(response)

        if resp.status_code != 200:
            raise AirflowFailException(response) 
        cf_json["offset_value"]=int(cf_json["offset_value"])+int(cf_json["limit"])
        Variable.set("cf_variable",json.dumps(cf_json))

    except Exception as e:
        raise AirflowFailException(str(e))

cf_invoke = PythonOperator(
    task_id="cf_invoke",
    python_callable=invoke_cloud_function,
    dag=dag
)



trigger = TriggerDagRunOperator(
        task_id="trigger_target_dag",
        trigger_dag_id="beta_load",  
        wait_for_completion=True
    )

start = EmptyOperator(
    task_id="start"
)

end = EmptyOperator(
    task_id="end"
)

start >> cf_invoke >> end
