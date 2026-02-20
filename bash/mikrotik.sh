#!/bin/bash

# Настройки подключения
HOST="192.168.30.1"
USER="restapi"
PASS="***********************"

# Выполнение через встроенный Python-посредник
# --- СОХРАНЕНИЕ В ПЕРЕМЕННУЮ ---
# Весь вывод Python-скрипта (stdout) записывается в переменную log_data
log_data=$(python3 - <<EOF
import socket

def encode_word(word):
    b = word.encode('utf-8')
    length = len(b)
    if length < 0x80: header = bytes([length])
    elif length < 0x4000: header = bytes([(length >> 8) | 0x80, length & 0xFF])
    else: header = bytes([(length >> 16) | 0xC0, (length >> 8) & 0xFF, length & 0xFF])
    return header + b

def read_word(s):
    b = s.recv(1)
    if not b: return None
    val = int.from_bytes(b, 'big')
    if val & 0x80 == 0x00: length = val
    elif val & 0xC0 == 0x80: length = ((val & 0x3F) << 8) + int.from_bytes(s.recv(1), 'big')
    elif val & 0xE0 == 0xC0: length = ((val & 0x1F) << 16) + (int.from_bytes(s.recv(1), 'big') << 8) + int.from_bytes(s.recv(1), 'big')
    else: length = 0
    data = b""
    while len(data) < length:
        chunk = s.recv(length - len(data))
        if not chunk: break
        data += chunk
    return data.decode('utf-8', errors='ignore')

try:
    s = socket.create_connection(("$HOST", 8728), timeout=5)
    for w in ["/login", "=name=$USER", "=password=$PASS", ""]:
        s.sendall(encode_word(w))
    while True:
        w = read_word(s)
        if w in ["!done", "!trap"]: break

    for w in ["/log/print", "=.proplist=time,topics,message", ""]:
        s.sendall(encode_word(w))

    current_entry = {}
    while True:
        w = read_word(s)
        if w == "!done": break
        if w == "!re":
            if current_entry:
                print(f"{current_entry.get('time', 'N/A')} | {current_entry.get('topics', 'N/A')} | {current_entry.get('message', '')}")
            current_entry = {}
        elif w and w.startswith("="):
            parts = w[1:].split("=", 1)
            if len(parts) == 2: current_entry[parts[0]] = parts[1]
    if current_entry:
        print(f"{current_entry.get('time', 'N/A')} | {current_entry.get('topics', 'N/A')} | {current_entry.get('message', '')}")
except:
    pass
finally:
    if 's' in locals(): s.close()
EOF
)


# TELEGRAM_CHAT="${2:--5013323561}"
TELEGRAM_BOT_CHATID="${3:-517090498}"
teletram_API="https://api.telegram.org/bot7482410376:AAFua_zEhM3nW2dEiVtBJuGWJ7GPE7UBLc0/sendMessage"


send_message_telegram() {
    local teletram_API_f="${1:-$teletram_API}"
    local TELEGRAM_CHAT_f="${2:-$TELEGRAM_BOT_CHATID}"
    local TELEGRAM_MESSAGE_TEXT="${3:-"No message provided"}"
    echo -e "\n---------------------- START function!\n"
    curl -s -X POST $teletram_API_f \
            -d chat_id=$TELEGRAM_CHAT_f \
            -d text="$TELEGRAM_MESSAGE_TEXT"
    echo -e "\n---------------------- END function!\n"
}


# --- ТЕПЕРЬ МОЖНО ФИЛЬТРОВАТЬ И СОРТИРОВАТЬ ПЕРЕМЕННУЮ ---
# 2. Подготовка списка IP (извлекаем кол-во и IP)
# Простой вывод количества строк
count=$(echo "$log_data" | wc -l)
echo "Получено строк: $count"

# Пример фильтрации ошибок из переменной и сохранение в новую переменную
errors_only=$(echo "$log_data" | grep -iE "error|critical|warning")

# Пример сортировки по алфавиту (сообщение находится после второй '|')
sorted_logs=$(echo "$log_data" | sort -t '|' -k 3)
declare -A ip_data_table


# Вывод результата
echo "--- Отсортированные логи ---"
echo "------------Critical, Error и Warning сообщения:"
echo "$sorted_logs" | grep -iE "error|critical|warning"
echo "попытки подключения к RDP:"
list_of_rdp_attempts=$(echo "$sorted_logs" | grep -iE "rdp|remote desktop|mstsc|3390" | awk -F '|' '{print $3}' | awk -F ',' '{print $4}' | awk -F ':' '{print $1}' | sort | uniq -c | sort -nr | head -n 10)
echo "$list_of_rdp_attempts"

echo -e "Count\tIP\t\tCountry\t\tOrganization"
echo "--------------------------------------"

while read -r count ip; do
    [[ -z "$ip" ]] && continue
    
    # Делаем запрос. Флаг -s убирает прогресс-бар curl
    # Мы запрашиваем JSON целиком, так как это надежнее при лимитах
    response=$(curl -s "https://ipinfo.io")

    # Извлекаем значение поля "country" с помощью grep и cut
    # Это сработает, даже если пришел многострочный JSON
    country=$(echo "$response" | grep '"country":' | cut -d'"' -f4)
    org=$(echo "$response" | grep '"org":' | cut -d'"' -f4)

    # Если страна не найдена в ответе (например, ошибка API)
    if [ -z "$country" ]; then
        country="Unknown/Limit"
    fi

    # 3. СОХРАНЯЕМ В МАССИВ (Ключ - IP, Значение - строка с разделителем |)
    ip_data_table["$ip"]="$count|$country|$org"

    # Вывод в одну строку
    printf "%-7s %-15s %s\t\t%s\n" "$count" "$ip" "$country" "$org"
    
    # Небольшая пауза, чтобы не получать ошибку 429 (Too Many Requests)
    sleep 1
done <<< "$list_of_rdp_attempts"

# --- ПРОВЕРКА МАССИВА ПОСЛЕ ЦИКЛА ---
echo -e "\n--- Итоговое содержимое массива (проверка) ---"
total_items=${#ip_data_table[@]}
if [ "$total_items" -eq 0 ]; then
    echo "Ошибка: Массив пуст. Проверьте, не пуста ли переменная \$list_of_rdp_attempts"
    echo "Содержимое переменной list_of_rdp_attempts:"
    echo "$list_of_rdp_attempts"
else
   send_message_telegram "$teletram_API" "$TELEGRAM_BOT_CHATID" "Топ 10 IP по попыткам RDP:\n$list_of_rdp_attempts"
    # for current_ip in "${!ip_data_table[@]}"; do
    #     # # Распаковываем данные
    #     IFS='|' read -r c_val geo_val org_val <<< "${ip_data_table[$current_ip]}"
    #     echo "IP: $current_ip | Попыток: $c_val | Страна: $geo_val | Org: $org_val"
    # done
fi
