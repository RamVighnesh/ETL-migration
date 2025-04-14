from airflow import DAG
from datetime import datetime,timedelta
from google.auth.transport.requests import AuthorizedSession
from google.auth import impersonated_credentials
from airflow.exceptions import AirflowFailException
from airflow.models import Variable
import json




default_args={
    'owner': 'airflow',
    'depends_on_past': False, # does this dag depend on the previous run of the dag? best practice is to try have dags not depend on state or results of a previous run
    'start_date': datetime(2025, 4, 13), # from what date to you want to pretend this dag was born on? by default airflow will try backfill - be careful
    'email_on_failure': True, # should we send emails on failure?
    'email': ['ratna.kumar62@gmail.com','ramvighnesh@gmail.com'], # who to email if fails i.e me :)
    'retries': 1, # if fails how many times should we retry?
    'retry_delay': timedelta(minutes=2), # if we need to retry how long should we wait before retrying?
}

dag=DAG("cf_beta_test",
default_args=default_args,
schedule_interval=None,
catchup=False
)


def invoke_cloud_function(**kwargs):
    scopes=["https://www.googleapis.com/auth/cloud-platform.read-only"]
    try:
        credntials,project_id=google.auth.default(scopes=scopes)
        variable=Variable.get("cf_airflow_variable")
        var=json.loads(variable)
        cf_variable=Variable.get("cf_variable")
        cf_json=json.loads(cf_variable)



        #cf_json2={ "name": "Developer", "limit": 100 , "offset_value": 100, "dest_bucket" : "usc1-landing-archive" , "project_id" : "project-beta-000002", "dataset_table" : "BETA_LANDING.Landing_Table" }


        url=var["cf_url"]

        request=google.auth.transport.requests.Request()

        target_credentials = impersonated_credentials.Credntials(
            source_credentials=credntials,
            target_scope=scopes,
            target_principal=var['cf_service_account'],
            lifetime=500

        )
        id_token_credentials=impersonated_credentials.IDTokenCredentials(target_credentials,
        target_audience=url,
        include_email=False,
        quota_project_id= None)
        resp =AuthorizedSession(id_token(credntials).request("POST",url=url,json=cf_json))
        print(resp.status_code)
        response=str(resp.content)
        print(response)
        if resp.status_code!=200:
            raise AirflowFailException(str(response))
    except Exception as e:
        raise AirflowFailException(str(e))

cf_invoke = PythonOperator(
    task_id="cf_invoke"
    python_callable=invoke_cloud_function,
    provide_context=True,
    dag=dag
)


start=EmptyOperator(
    task_id="start"
)

end=EmptyOperator(
    task_id="end"
)


start>>cf_invoke>>end