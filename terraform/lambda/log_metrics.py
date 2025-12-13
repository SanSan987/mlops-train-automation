import json

def lambda_handler(event, context):
    print("--- 📝 ЛОГУВАННЯ МЕТРИК ---")
    
    # Step Functions передає сюди вихід попереднього кроку (validate.py)
    print(f"Вхідні дані: {json.dumps(event)}")
    
    # Витягуємо необхідну інформацію
    original_input = event.get('original_input', {})
    source = original_input.get('source', 'unknown')
    commit = original_input.get('commit', 'N/A')
    
    print(f"Метрики: Тренування завершено успішно.")
    print(f"Джерело: {source}")
    print(f"Комміт: {commit}")
    print(f"Статус валідації: {event.get('validated')}")

    # Фінальний результат Step Function
    return {
        'statusCode': 200,
        'message': 'Metrics logged successfully',
        'run_details': {
            'source': source,
            'commit': commit
        }
    }