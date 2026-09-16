import pandas as pd


# ==========================
# 데이터 읽기
# ==========================

df = pd.read_csv(
    "sigungu_visitors.csv",
    dtype={
        "SIGUNGU_CD": str
    }
)


df["DATE"] = pd.to_datetime(
    df["DATE"],
    format="%Y%m%d"
)


# ==========================
# 기준 날짜
# ==========================

today = df["DATE"].max()

print("기준 날짜:", today)



# ==========================
# 현재 방문자
# ==========================

current = (
    df[df["DATE"] == today]
    .groupby(
        [
            "SIGUNGU_CD",
            "SIGUNGU_NM"
        ]
    )["VISITOR_CNT"]
    .sum()
    .reset_index()
)


current.rename(
    columns={
        "VISITOR_CNT": "CURRENT_VISITOR"
    },
    inplace=True
)



# ==========================
# 평균 계산 함수
# ==========================

def get_average(months):

    start = today - pd.DateOffset(
        months=months
    )

    temp = df[
        (df["DATE"] >= start)
        &
        (df["DATE"] < today)
    ]


    avg = (
        temp
        .groupby(
            [
                "SIGUNGU_CD",
                "SIGUNGU_NM"
            ]
        )["VISITOR_CNT"]
        .mean()
    )


    return avg.reset_index()



avg_1m = get_average(1)
avg_3m = get_average(3)
avg_6m = get_average(6)



# ==========================
# 평균 병합
# ==========================

result = current.copy()


result = result.merge(
    avg_1m,
    on=[
        "SIGUNGU_CD",
        "SIGUNGU_NM"
    ],
    how="left"
)


result.rename(
    columns={
        "VISITOR_CNT": "AVG_1M"
    },
    inplace=True
)



result = result.merge(
    avg_3m,
    on=[
        "SIGUNGU_CD",
        "SIGUNGU_NM"
    ],
    how="left"
)


result.rename(
    columns={
        "VISITOR_CNT": "AVG_3M"
    },
    inplace=True
)



result = result.merge(
    avg_6m,
    on=[
        "SIGUNGU_CD",
        "SIGUNGU_NM"
    ],
    how="left"
)


result.rename(
    columns={
        "VISITOR_CNT": "AVG_6M"
    },
    inplace=True
)



# ==========================
# 평소 방문자 계산
# ==========================

result["NORMAL_VISITOR"] = (

    result["AVG_1M"] * 0.5

    +

    result["AVG_3M"] * 0.3

    +

    result["AVG_6M"] * 0.2

)



# ==========================
# 평소 대비 %
# ==========================

result["NORMAL_COMPARE"] = (

    (
        result["CURRENT_VISITOR"]
        /
        result["NORMAL_VISITOR"]
    )

    - 1

) * 100



result["NORMAL_COMPARE"] = (
    result["NORMAL_COMPARE"]
    .round(1)
)



# ==========================
# 저장
# ==========================

result = result[
    [
        "SIGUNGU_CD",
        "SIGUNGU_NM",
        "CURRENT_VISITOR",
        "NORMAL_VISITOR",
        "NORMAL_COMPARE"
    ]
]


result.to_csv(
    "congestion_result.csv",
    index=False,
    encoding="utf-8-sig"
)



print("\n완료!")
print(result.head())

print(
    "\n생성 데이터:",
    len(result)
)