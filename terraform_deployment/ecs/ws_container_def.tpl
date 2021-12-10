[ 
    { 
        "command": ["${command_string}"],
        "entryPoint": [
        "/entrypoint"
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
        "portMappings" : [
            {
                "containerPort": 8080,
                "hostPort" : 8080,
                "protocol" : "tcp"
            }
        ],
        "environment" : [
            { "name" : "AIRFLOW__CORE__EXECUTOR", "value": "CeleryExecutor"},
            { "name" : "_AIRFLOW_DB_UPGRADE", "value": "true"},
            { "name" : "_AIRFLOW_WWW_USER_CREATE", "value": "true"},
            { "name" : "_AIRFLOW_WWW_USER_USERNAME", "value": "${gui_username}"},
            { "name" : "_AIRFLOW_WWW_USER_FIRSTNAME", "value": "${gui_firstname}"},
            { "name" : "_AIRFLOW_WWW_USER_LASTNAME", "value": "${gui_lastname}"},
            { "name" : "_AIRFLOW_WWW_USER_EMAIL", "value": "${gui_email}"},
            { "name" : "_AIRFLOW_WWW_USER_ROLE", "value": "Admin"},
            { "name" : "AIRFLOW__API__AUTH_BACKEND", "value": "airflow.api.auth.backend.basic_auth"},
            { "name" : "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION", "value": "true"},
            { "name" : "AIRFLOW__CORE__LOAD_EXAMPLES", "value": "false"},
            { "name" : "AIRFLOW__CELERY__BROKER_URL", "value": "${sqs_url}"},
            { "name" : "AIRFLOW__CORE__FERNET_KEY", "value": ""}
        ],
        "secrets" : [
            { "name" : "_AIRFLOW_WWW_USER_PASSWORD", "valueFrom": "${ssm_pwd}"},
            { "name" : "AIRFLOW__CORE__SQL_ALCHEMY_CONN", "valueFrom": "${ssm_conn}"},
            { "name" : "AIRFLOW__CELERY__RESULT_BACKEND", "valueFrom": "${ssm_celery}"}
        ]
    }
]
