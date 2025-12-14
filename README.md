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
AWS_DEFAULT_REGION (опційно)
Після apply Terraform виведе state_machine_arn.
4) Як вручну запустити Step Function
aws stepfunctions start-execution \ --state-machine-arn "<STATE_MACHINE_ARN>" \ --name "manual-$(date +%s)" \ --input '{"source":"manual", "commit":"test"}'
5) Як працює GitLab CI і які змінні потрібні
Файл .gitlab-ci.yml містить job train-model, який запускається на push і викликає:
aws stepfunctions start-execution.
Потрібні CI/CD Variables:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION (наприклад eu-central-1)
STATE_MACHINE_ARN (output Terraform)
6) Приклад JSON, що передається
Приклад input:
{
  "source": "gitlab-ci",
  "commit": "a1b2c3d4"
}
