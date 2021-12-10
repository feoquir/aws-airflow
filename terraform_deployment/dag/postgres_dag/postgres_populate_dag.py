import datetime

from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator

# create_pet_table, populate_pet_table, get_all_pets, and get_birth_date are examples of tasks created by
# instantiating the Postgres Operator

with DAG(
    dag_id="postgres_populate_dag",
    start_date=datetime.datetime(2021, 10, 11),
    schedule_interval="@once",
    catchup=False,
) as dag:
    create_pet_table = PostgresOperator(
        task_id="create_pet_table",
        postgres_conn_id="remote_psql",
        sql="sql/pet_schema.sql"
    )
    populate_pet_table = PostgresOperator(
        task_id="populate_pet_table",
        postgres_conn_id="remote_psql",
        sql="sql/pet_values.sql"
    )

    create_pet_table >> populate_pet_table