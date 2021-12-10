[ 
    { 
        "command": ["${command_string}"],
        "entryPoint": [
        "/bin/bash",
        "-c"
        ],
        "mountPoints" : [
            {
                "sourceVolume" : "airflow_dag",
                "containerPath" : "/opt/airflow/dags"
            }
        ],
        "cpu" : 1024,
        "memory": 4096,
        "essential": true,
        "image": "${ecr_url}",
        "logConfiguration": { 
            "logDriver": "awslogs",
            "options": { 
                "awslogs-group" : "${cw_logroup}",
                "awslogs-region": "${region}",
                "awslogs-stream-prefix": "ecs"
            }
        },
        "name": "${task_name}",
        "environment" : [
            { "name" : "AIRFLOW__CORE__EXECUTOR", "value": "CeleryExecutor"},
            { "name" : "AIRFLOW__API__AUTH_BACKEND", "value": "airflow.api.auth.backend.basic_auth"},
            { "name" : "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", "value": "true"},
            { "name" : "AIRFLOW__CORE__LOAD_EXAMPLES", "value": "false"},
            { "name" : "AIRFLOW__CELERY__BROKER_URL", "value": "${sqs_url}"},
            { "name" : "DUMB_INIT_SETSID", "value": "0"},
            { "name" : "AIRFLOW__CORE__FERNET_KEY", "value": ""}
        ],
        "secrets" : [
            { "name" : "AIRFLOW__CORE__SQL_ALCHEMY_CONN", "valueFrom": "${ssm_conn}"},
            { "name" : "AIRFLOW__CELERY__RESULT_BACKEND", "valueFrom": "${ssm_celery}"}
        ]
    }
]
