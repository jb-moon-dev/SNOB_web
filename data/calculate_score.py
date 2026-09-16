import pandas as pd


# ==========================
# 데이터 불러오기
# ==========================

df = pd.read_csv(
    "congestion_result.csv",
    dtype={
        "SIGUNGU_CD": str
    }
)


# ==========================
# 1. 평소 대비 혼잡도 점수
# ==========================
#
# -50% 이하 → 0점
#  0%       → 50점
# +50% 이상 → 100점
#
# 해당 범위를 벗어나면 0~100 제한
# ==========================

df["CONGESTION_SCORE"] = (
    (df["NORMAL_COMPARE"] + 50)
    / 100
) * 100


df["CONGESTION_SCORE"] = (
    df["CONGESTION_SCORE"]
    .clip(0, 100)
    .round(1)
)



# ==========================
# 2. 절대 방문자 규모 점수
# ==========================
#
# 현재 방문자가 전국 시군구 중
# 어느 정도 규모인지 표현
#
# 최소 방문자 = 0점
# 최대 방문자 = 100점
# ==========================

min_visitor = df["CURRENT_VISITOR"].min()
max_visitor = df["CURRENT_VISITOR"].max()


df["ABSOLUTE_SCORE"] = (
    (df["CURRENT_VISITOR"] - min_visitor)
    /
    (max_visitor - min_visitor)
) * 100


df["ABSOLUTE_SCORE"] = (
    df["ABSOLUTE_SCORE"]
    .clip(0, 100)
    .round(1)
)



# ==========================
# 평소 대비 혼잡 등급
# ==========================

def get_level(score):

    if score >= 80:
        return "매우 혼잡"

    elif score >= 60:
        return "혼잡"

    elif score >= 40:
        return "보통"

    elif score >= 20:
        return "여유"

    else:
        return "매우 여유"



df["CONGESTION_LEVEL"] = (
    df["CONGESTION_SCORE"]
    .apply(get_level)
)



# ==========================
# 저장
# ==========================

result = df[
    [
        "SIGUNGU_CD",
        "SIGUNGU_NM",

        # 현재 방문자
        "CURRENT_VISITOR",

        # 평소 대비 데이터
        "NORMAL_VISITOR",
        "NORMAL_COMPARE",
        "CONGESTION_SCORE",

        # 절대 규모 데이터
        "ABSOLUTE_SCORE",

        # 등급
        "CONGESTION_LEVEL"
    ]
]


result.to_csv(
    "congestion_final.csv",
    index=False,
    encoding="utf-8-sig"
)



print("\n완료!\n")

print(result.head())

print("\n생성 데이터:", len(result))