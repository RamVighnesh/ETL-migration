from airflow import DAG
from datetime import datetime, timedelta
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

# create a dictionary of default typical args to pass to the dag
default_args = {
    'owner': 'airflow',
    'depends_on_past': False, # does this dag depend on the previous run of the dag? best practice is to try have dags not depend on state or results of a previous run
    'start_date': datetime(2025, 4, 13), # from what date to you want to pretend this dag was born on? by default airflow will try backfill - be careful
    'email_on_failure': True, # should we send emails on failure?
    'email': ['ratna.kumar62@gmail.com'], # who to email if fails i.e me :)
    'retries': 1, # if fails how many times should we retry?
    'retry_delay': timedelta(minutes=2), # if we need to retry how long should we wait before retrying?
}

dag = DAG('beta_move_dag',
           schedule_interval=None
          default_args=default_args,
          catchup=False)


call_staged_stored_procedure = BigQueryInsertJobOperator(
    task_id="call_stored_procedure",
    configuration={
        "query": {
            "query": "CALL project-beta-000002.BETA_STG.Data_load() ; ",
            "useLegacySql": False,
        }
    },
    location='US',
)


call_final_stored_procedure = BigQueryInsertJobOperator(
    task_id="call_final_stored_procedure",
    configuration={
        "query": {
            "query": "CALL project-beta-000002.BETA.Data_load() ; ",
            "useLegacySql": False,
        }
    },
    location='US',
)



call_staged_stored_procedure>>call_final_stored_procedure
