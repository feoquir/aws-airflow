import datetime

from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator

# create_pet_table, populate_pet_table, get_all_pets, and get_birth_date are examples of tasks created by
# instantiating the Postgres Operator

with DAG(
    dag_id="postgres_read_dag",
    start_date=datetime.datetime(2021, 10, 11),
    schedule_interval="@once",
    catchup=False,
) as dag:
    get_all_pets = PostgresOperator(
        task_id="get_all_pets",
        postgres_conn_id="remote_psql",
        sql="SELECT * FROM pet;"
    )
    get_birth_date = PostgresOperator(
        task_id="get_birth_date",
        postgres_conn_id="remote_psql",
        sql="""
            SELECT * FROM pet
            WHERE birth_date
            BETWEEN SYMMETRIC DATE '{{ params.begin_date }}' AND DATE '{{ params.end_date }}';
            """,
        params={'begin_date': '2020-01-01', 'end_date': '2020-12-31'},
    )

    get_all_pets >> get_birth_date