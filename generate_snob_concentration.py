import pandas as pd
import json
from pathlib import Path


# ================================================================
# 설정
# ================================================================

EXCEL_PATH = r"C:\Users\USER\OneDrive\Desktop\SNOB_congestion\output\snob_congestion_nationwide_final.xlsx"

SHEET_NAME = "최종_관광지_혼잡도"

OUTPUT_PATH = "assets/data/snob_concentration.json"


# ================================================================
# 관광지 이름 정규화
# Flutter의 _normalizeName()과 동일한 방식
# ================================================================

def normalize_name(value):
    if pd.isna(value):
        return ""

    return (
        str(value)
        .strip()
        .replace('"', '')
        .replace("'", '')
        .replace(' ', '')
        .replace('\n', '')
        .replace('\r', '')
        .replace('\t', '')
        .replace('(', '')
        .replace(')', '')
        .lower()
    )


# ================================================================
# Excel 읽기
# ================================================================

print()
print("=" * 70)
print("📂 SNOB 관광지 집중률 JSON 생성")
print("=" * 70)

print()
print(f"Excel 파일 : {EXCEL_PATH}")
print(f"시트       : {SHEET_NAME}")


df = pd.read_excel(
    EXCEL_PATH,
    sheet_name=SHEET_NAME,
    usecols=[
        "시도",
        "시군구코드",
        "시군구",
        "관광지",
        "집중률",
    ],
)


print()
print(f"원본 데이터 수 : {len(df):,}")


# ================================================================
# 데이터 정리
# ================================================================

# 시군구코드 정리
df["시군구코드"] = (
    pd.to_numeric(
        df["시군구코드"],
        errors="coerce",
    )
    .astype("Int64")
    .astype(str)
    .replace("<NA>", "")
    .str.zfill(5)
)


# 관광지명 정리
df["관광지"] = (
    df["관광지"]
    .fillna("")
    .astype(str)
    .str.strip()
)


# 집중률 숫자로 변환
df["집중률"] = pd.to_numeric(
    df["집중률"],
    errors="coerce",
)


# 정규화 관광지명 생성
df["normalizedName"] = df["관광지"].apply(
    normalize_name
)


# ================================================================
# 잘못된 데이터 제거
# ================================================================

before_count = len(df)


df = df[
    (df["시군구코드"] != "")
    &
    (df["normalizedName"] != "")
    &
    df["집중률"].notna()
    &
    (df["집중률"] >= 0)
    &
    (df["집중률"] <= 100)
].copy()


removed_count = before_count - len(df)


print()
print("🧹 데이터 정리")
print("-" * 70)
print(f"제거된 데이터 : {removed_count:,}")
print(f"사용 데이터   : {len(df):,}")


# ================================================================
# 같은 시군구 + 같은 관광지의 집중률 평균 계산
#
# Excel에는 관광지마다 30일 데이터가 있으므로
# Flutter에서 매번 30개를 평균내지 않고
# 여기서 미리 평균을 계산한다.
# ================================================================

grouped = (
    df.groupby(
        [
            "시군구코드",
            "시도",
            "시군구",
            "관광지",
            "normalizedName",
        ],
        as_index=False,
    )
    .agg(
        집중률=("집중률", "mean"),
        데이터개수=("집중률", "size"),
    )
)


print()
print("📊 평균 계산")
print("-" * 70)
print(
    f"관광지 + 시군구 조합 : "
    f"{len(grouped):,}개"
)


# ================================================================
# JSON records 생성
# ================================================================

records = []


for _, row in grouped.iterrows():

    records.append(
        {
            "sigunguCode": str(
                row["시군구코드"]
            ),

            "sido": str(
                row["시도"]
            ),

            "sigungu": str(
                row["시군구"]
            ),

            "name": str(
                row["관광지"]
            ),

            "normalizedName": str(
                row["normalizedName"]
            ),

            "concentration": round(
                float(row["집중률"]),
                4,
            ),

            "dataCount": int(
                row["데이터개수"]
            ),
        }
    )


# ================================================================
# 이름만으로 매칭 가능한 관광지 확인
#
# 동일 관광지명이 여러 시군구에 존재하면
# 이름만으로 매칭하면 잘못된 지역의 값을 가져올 수 있다.
#
# 따라서 이름이 전국에서 한 시군구에만 존재하는 경우에만
# 이름 fallback을 허용한다.
# ================================================================

name_region_count = (
    grouped
    .groupby("normalizedName")["시군구코드"]
    .nunique()
)


unique_name_records = [
    record
    for record in records
    if name_region_count.get(
        record["normalizedName"],
        0,
    ) == 1
]


# ================================================================
# 최종 JSON
# ================================================================

output = {

    "source":
        "snob_congestion_nationwide_final.xlsx",

    "sheet":
        SHEET_NAME,

    "description":
        "시군구별 관광지 30일 집중률 평균 데이터",

    "recordCount":
        len(records),

    "uniqueNameFallbackCount":
        len(unique_name_records),

    "records":
        records,
}


# ================================================================
# 출력 폴더 생성
# ================================================================

output_file = Path(
    OUTPUT_PATH
)

output_file.parent.mkdir(
    parents=True,
    exist_ok=True,
)


# ================================================================
# JSON 저장
# ================================================================

output_file.write_text(
    json.dumps(
        output,
        ensure_ascii=False,
        indent=2,
    ),
    encoding="utf-8",
)


# ================================================================
# 결과 출력
# ================================================================

print()
print("=" * 70)
print("✅ JSON 생성 완료")
print("=" * 70)

print()
print(
    f"출력 파일 : {OUTPUT_PATH}"
)

print(
    f"관광지-시군구 데이터 : "
    f"{len(records):,}개"
)

print(
    f"이름만으로 안전하게 매칭 가능 : "
    f"{len(unique_name_records):,}개"
)

print()
print("=" * 70)
print("🏁 완료")
print("=" * 70)