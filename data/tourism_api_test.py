import requests
import json

url = "https://apis.data.go.kr/B551011/DataLabService/locgoRegnVisitrDDList"

params = {
    "serviceKey": "22cfa7aa1cefdd4fe98e0e9dad0415b994b125c08a2da84a8757d7ac5aa09af5",
    "MobileOS": "ETC",
    "MobileApp": "SNOB",
    "_type": "json",

    "startYmd": "20250101",
    "endYmd": "20250131",

    "numOfRows": 1000,
    "pageNo": 1
}

response = requests.get(url, params=params)

print("상태 코드:", response.status_code)

data = response.json()

print(json.dumps(data, indent=2, ensure_ascii=False)[:3000])