MLOps Training Automation Pipeline

ІНСТРУКЦІЯ

Цей проєкт демонструє автоматизований, контрольований та відтворюваний запуск пайплайну тренування ML-моделей з використанням Terraform для розгортання інфраструктури, AWS Step Functions для оркестрації та GitLab CI для автоматичного запуску.

Архітектура
Пайплайн реалізовано як AWS Step Function (State Machine), що послідовно викликає дві AWS Lambda-функції:
1. `ValidateData`: Перевіряє вхідні параметри запуску.
2. `LogMetrics`: Імітує логування результатів тренування.
Уся інфраструктура описується та розгортається через Terraform.

Покрокова інструкція

1. Структура
mlops-train-automation/
├── terraform/
│ ├── main.tf
│ ├── variables.tf
│ └── lambda/
│ ├── validate.py
│ ├── log_metrics.py
│ ├── validate.zip
│ └── log_metrics.zip
├── .gitlab-ci.yml
└── README.md

2) Як зібрати Lambda-архіви
cd .\terraform\lambda
Compress-Archive -Path .\validate.py -DestinationPath .\validate.zip -Force
Compress-Archive -Path .\log_metrics.py -DestinationPath .\log_metrics.zip –Force
3) Як розгорнути інфраструктуру через Terraform
Потрібні AWS креденшали (через env vars або aws configure):
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION .
Після apply Terraform виведе state_machine_arn.
Необхідні CI/CD змінні (GitLab → Settings → CI/CD → Variables)
Створи змінні в GitLab-проєкті:
AWS_ACCESS_KEY_ID — Masked + Protected
AWS_SECRET_ACCESS_KEY — Masked + Protected
AWS_DEFAULT_REGION — Protected (Visible)
STATE_MACHINE_ARN — Protected (Visible)
Важливо: якщо змінні мають прапорець Protected, то гілка, з якої запускається pipeline (lesson-10), теж має бути Protected branch.

4) Як вручну запустити Step Function
При кожному push у гілку lesson-10 GitLab запускає job train-model, який:
Перевіряє наявність AWS_DEFAULT_REGION та STATE_MACHINE_ARN;
Перевіряє AWS доступ через aws sts get-caller-identity;
Формує ім’я execution та JSON-вхідні параметри;
Викликає AWS Step Functions командою aws stepfunctions start-execution.

Як перевірити виконання в GitLab:
GitLab → Build → Pipelines
Відкрти останній pipeline
Відкрти job train-model
У логах має бути вивід start-execution з executionArn

Як перевірити виконання в AWS Console
AWS Console → Step Functions
Відкрий state machine (наприклад mlops-train-automation-training-pipeline)
Перейди на вкладку Executions
Відкрий останній execution:
Status має бути Succeeded
У Input буде JSON, який надіслав GitLab CI

5) Як працює GitLab CI і які змінні потрібні
Файл .gitlab-ci.yml містить job train-model, який запускається на push і викликає:
aws stepfunctions start-execution.
Потрібні CI/CD Variables:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION (eu-central-1)
STATE_MACHINE_ARN (output Terraform)

6) Приклад JSON, що передається
Приклад структури –input (копія з AWS консолі):
{
  "source": "gitlab-ci",
  "commit": "d79c2ae1",
  "gitlab_job_id": "12430978532"
}
