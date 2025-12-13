import json

def lambda_handler(event, context):
    print("--- ⚙️ ВАЛІДАЦІЯ ДАНИХ ---")
    
    # Логування вхідних даних для перевірки
    print(f"Отримані дані: {json.dumps(event)}")
    
    # Умовна логіка валідації
    is_valid = True
    if "source" in event and event["source"] == "gitlab-ci":
        print("Джерело запуску - GitLab CI. Дані вважаються валідними.")
        is_valid = True
    elif "test_data" in event and not event["test_data"]:
        print("Помилка: Поле 'test_data' порожнє. Дані невалідні.")
        is_valid = False
    else:
        print("Дані валідні. Перехід до наступного кроку.")
        
    # Step Functions передасть результат далі
    return {
        'statusCode': 200,
        'validated': is_valid,
        'original_input': event # Повертаємо вхідні дані для наступного кроку
    }