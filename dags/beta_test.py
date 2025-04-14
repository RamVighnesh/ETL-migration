from airflow import DAG
from datetime import datetime, timedelta
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.operators.python import PythonOperator, BranchPythonOperator, ShortCircuitOperator
from airflow.models import Variable
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup
from airflow.utils.helpers import chain
from io import StringIO
import pandas as pd
import logging


GCP_CONN_ID = 'airflow-gcp-conn-id'

# create a dictionary of default typical args to pass to the dag
default_args = {
    'owner': 'airflow',
    'depends_on_past': False, # does this dag depend on the previous run of the dag? best practice is to try have dags not depend on state or results of a previous run
    'start_date': datetime(2025, 4, 13), # from what date to you want to pretend this dag was born on? by default airflow will try backfill - be careful
    'email_on_failure': False, # should we send emails on failure?
    'retries': 1, # if fails how many times should we retry?
    'retry_delay': timedelta(minutes=2), # if we need to retry how long should we wait before retrying?
}

with DAG('beta_load',
           schedule_interval=None,
          default_args=default_args,
          catchup=False,
          template_searchpath=['./sqls']
          ) as dag :


    # proclist = {"name":"Data_load_stg", "dataset":"BETA_STG"}
    file = 'proc_list.csv'


    def gcs_to_df():
        gcshook = GCSHook(gcp_conn_id=GCP_CONN_ID)
        gcs_file_path = f'dags/proc_list.csv'
        file_bytes = gcshook.download(bucket_name="us-central1-tests-3b5f7783-bucket",object_name=gcs_file_path)
        file = file_bytes.decode('utf-8')
        df = pd.read_csv(StringIO(file))
        return df

    #proclist = pd.read_csv(file,escapechar="\\", dtype=str)

    proclist=gcs_to_df()

    start = EmptyOperator(
        task_id="Start"
    )

    end = EmptyOperator(
        task_id="End",
        trigger_rule="none_failed_min_one_success"
    )

    def check_procedure(**kwargs):
        logging.info(f"<INFO> {__name__}:checking")
        proc_name = kwargs["name"]
        dataset = kwargs["dataset"]
        conditional_true_task = kwargs["conditional_true_task"]
        conditional_false_task = kwargs["conditional_false_task"]

        bq_hook = BigQueryHook(gcp_conn_id=GCP_CONN_ID, use_legacy_sql=False)

        query = f"select count(1) as count from {dataset}.INFORMATION_SCHEMA.ROUTINES where routine_name = '{proc_name}'"

        logging.info(f"<INFO>  the query is : {query}")

        bq_df = bq_hook.get_pandas_df(sql=query)

        exists = bq_df['count'][0] > 0

        return conditional_true_task if exists else conditional_false_task
        # return exists


    # previous = None
    task_groups = []

    for procedure in proclist.itertuples():
        procedure_name = procedure.procedure_name
        dataset_name = procedure.dataset

        with TaskGroup(group_id=f'{dataset_name}') as executegroup:

            check_procedure_exists = BranchPythonOperator(
            task_id=f'check_procedure_{procedure_name}',
            python_callable=check_procedure,
            op_kwargs={
                "name":procedure_name,
                "dataset":dataset_name,
                "conditional_true_task":f"{dataset_name}.exists_{procedure_name}",
                "conditional_false_task":f"{dataset_name}.not_exists_{procedure_name}"
                }
            )

            createprocedure = BigQueryInsertJobOperator(
                task_id=f"create_{procedure_name}",
                gcp_conn_id=GCP_CONN_ID,
                configuration={
                    "query": {
                        "query": "{% include '" + procedure_name + ".sql' %}",
                        "useLegacySql": False,
                    }
                }
            )

            call_procedure = BigQueryInsertJobOperator(
                task_id=f"call_{procedure_name}",
                gcp_conn_id=GCP_CONN_ID,
                configuration={
                    "query": {
                        "query": f"CALL {dataset_name}.{procedure_name}() ; ",
                        "useLegacySql": False,
                    }
                },
                trigger_rule='none_failed_min_one_success'
            )

            exists = EmptyOperator(task_id=f"exists_{procedure_name}")
            not_exists = EmptyOperator(task_id=f"not_exists_{procedure_name}")

            check_procedure_exists >> [exists, not_exists]
            not_exists >> createprocedure >> call_procedure
            exists >> call_procedure
        
        task_groups.append(executegroup)

    chain(start, *task_groups, end)



