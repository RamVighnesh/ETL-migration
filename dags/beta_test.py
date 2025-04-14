from airflow import DAG
from datetime import datetime, timedelta
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.operators.python import PythonOperator, BranchPythonoperator, ShortCircuitOperator
from airflow.models import Variable
from airflow.providers.google.cloud.hooks.bigquery import BigQueryhook
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup
import pandas as pd


GCP_CONN_ID = 'airflow-gcp-conn-id'

# create a dictionary of default typical args to pass to the dag
default_args = {
    'owner': 'airflow',
    'depends_on_past': False, # does this dag depend on the previous run of the dag? best practice is to try have dags not depend on state or results of a previous run
    'start_date': datetime(2025, 4, 13), # from what date to you want to pretend this dag was born on? by default airflow will try backfill - be careful
    'email_on_failure': True, # should we send emails on failure?
    'email': ['ratna.kumar62@gmail.com','ramvighnesh@gmail.com'], # who to email if fails i.e me :)
    'retries': 1, # if fails how many times should we retry?
    'retry_delay': timedelta(minutes=2), # if we need to retry how long should we wait before retrying?
}

dag = DAG('beta_move_dag',
           schedule_interval=None,
          default_args=default_args,
          catchup=False,
          template_searchpath=['./sqls']
          )


# proclist = {"name":"Data_load_stg", "dataset":"BETA_STG"}
file = 'proc_list.csv'
proclist = pd.read_csv(file,escapechar="\\", dtype=str)


start = EmptyOperator(
    task_id="Start"
)

end = EmptyOperator(
    task_id="End"
)

def check_procedure(**kwargs):
    proc_name = kwargs["name"]
    dataset = kwargs["dataset"]
    conditional_true_task = ["conditional_true_task"]
    conditional_false_task = ["conditional_false_task"]

    bq_hook = BigQueryhook(gcp_conn_id=GCP_CONN_ID, use_legacy_sql=False)

    query = f"select count(1) as count from {dataset}.INFORMATION_SCHEMA.ROUTINES where routine = '{proc_name}'"

    bq_df = bq_hook(sql=query)

    exists = df['count'][0] > 0

    return conditional_true_task if exists else conditional_false_task


previous = None

for procedure in proclist.itertuples():
    procedure_name = procedure["procedure_name"]
    dataset_name = procedure["dataset"]

    with TaskGroup(group_id=f'{dataset_name}') as executegroup:

        check_procedure_exists = BranchPythonoperator(
        task_id='check_procedure',
        python_callable=check_procedure,
        op_kwargs={
            "name":procedure_name,
            "dataset":dataset_name,
            "conditional_true_task":f"call_{procedure_name}",
            "conditional_false_task":f"create_{procedure_name}"
            }
        )

        createprocedure = BigQueryInsertJobOperator(
            task_id=f"create_{procedure_name}",
            configuration={
                "query": {
                    "query": "{% include '" + procedure_name + ".sql' %}",
                    "useLegacySql": False,
                }
            },
            location='US',
        )

        call_procedure = BigQueryInsertJobOperator(
            task_id="call_{procedure_name}",
            configuration={
                "query": {
                    "query": f"CALL {dataset_name}.{procedure_name}() ; ",
                    "useLegacySql": False,
                }
            },
            location='US',
        )

        check_procedure_exists >> [createprocedure, call_procedure]
        createprocedure >> call_procedure
        call_procedure >> end
    
    if previous:
        previous >> executegroup
    previous = executegroup

    
start >> executegroup >> end



