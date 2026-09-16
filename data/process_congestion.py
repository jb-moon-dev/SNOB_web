import requests
import pandas as pd
import time


# ==========================
# API 설정
# ==========================

url = "https://apis.data.go.kr/B551011/DataLabService/locgoRegnVisitrDDList"


params = {
    "serviceKey": "22cfa7aa1cefdd4fe98e0e9dad0415b994b125c08a2da84a8757d7ac5aa09af5",
    "MobileOS": "ETC",
    "MobileApp": "SNOB",
    "_type": "json",

    # 성수기/비수기 반영을 위한 기간
    "startYmd": "20240701",
    "endYmd": "20250131",

    "numOfRows": 1000,
    "pageNo": 1
}


# ==========================
# 전체 데이터 수집
# ==========================

all_items = []

page = 1


while True:

    print(f"{page} 페이지 요청 중...")


    params["pageNo"] = page

    response = requests.get(
        url,
        params=params
    )


    data = response.json()


    # 에러 확인
    if "response" not in data:
        print(data)
        break


    body = data["response"]["body"]


    items = body.get("items")


    if not items:
        break


    item_list = items["item"]


    all_items.extend(item_list)


    print(
        "현재 수집:",
        len(all_items)
    )


    total_count = body["totalCount"]


    if len(all_items) >= total_count:
        break


    page += 1

    time.sleep(0.2)



print("\n원본 데이터 개수:")
print(len(all_items))


# ==========================
# DataFrame 변환
# ==========================

df = pd.DataFrame(all_items)


print(df.head())


# ==========================
# 방문자 수 숫자 변환
# ==========================

df["touNum"] = df["touNum"].astype(float)



# ==========================
# 시군구별 날짜 합산
# ==========================

result = (
    df
    .groupby(
        [
            "signguCode",
            "signguNm",
            "baseYmd"
        ]
    )["touNum"]
    .sum()
    .reset_index()
)



# ==========================
# 컬럼명 변경
# ==========================

result.rename(
    columns={
        "signguCode": "SIGUNGU_CD",
        "signguNm": "SIGUNGU_NM",
        "baseYmd": "DATE",
        "touNum": "VISITOR_CNT"
    },
    inplace=True
)



# ==========================
# 저장
# ==========================

result.to_csv(
    "sigungu_visitors.csv",
    index=False,
    encoding="utf-8-sig"
)


print("\n저장 완료!")
print(result.head())


print(
    "\n최종 데이터:",
    len(result)
)


print(
    "날짜:",
    result["DATE"].min(),
    "~",
    result["DATE"].max()
)