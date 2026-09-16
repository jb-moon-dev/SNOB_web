import os
import pandas as pd
import geopandas as gpd


# ============================================================
# SNOB 관광지 ↔ 보호구역 공간 매칭
# ============================================================

print("")
print("=" * 60)
print("SNOB 관광지 ↔ 보호구역 공간 매칭 시작")
print("=" * 60)
print("")


# ============================================================
# 1. 파일 경로
# ============================================================

TOURISM_CSV = "data/tourism_spots.csv"
PROTECTED_GEOJSON = "data/protected_areas.geojson"

OUTPUT_CSV = "data/tourism_spots_protected.csv"


print("[1] 파일 확인")
print("")

print(f"관광지 데이터:")
print(os.path.abspath(TOURISM_CSV))

print("")

print(f"보호구역 데이터:")
print(os.path.abspath(PROTECTED_GEOJSON))

print("")


if not os.path.exists(TOURISM_CSV):
    raise FileNotFoundError(
        f"관광지 CSV 파일을 찾을 수 없습니다:\n"
        f"{os.path.abspath(TOURISM_CSV)}"
    )


if not os.path.exists(PROTECTED_GEOJSON):
    raise FileNotFoundError(
        f"보호구역 GeoJSON 파일을 찾을 수 없습니다:\n"
        f"{os.path.abspath(PROTECTED_GEOJSON)}"
    )


# ============================================================
# 2. 관광지 CSV 읽기
# ============================================================

print("[2] 관광지 CSV 읽는 중...")
print("")

# UTF-8 우선
try:
    tourism_df = pd.read_csv(
        TOURISM_CSV,
        encoding="utf-8-sig",
    )
except UnicodeDecodeError:
    tourism_df = pd.read_csv(
        TOURISM_CSV,
        encoding="cp949",
    )


print(f"관광지 수: {len(tourism_df):,}개")

print("")

print("관광지 컬럼:")
print(list(tourism_df.columns))

print("")


# ============================================================
# 3. 좌표 컬럼 확인
# ============================================================

required_columns = [
    "latitude",
    "longitude",
]

for column in required_columns:
    if column not in tourism_df.columns:
        raise ValueError(
            f"필수 컬럼이 없습니다: {column}"
        )


# 문자열 → 숫자
tourism_df["latitude"] = pd.to_numeric(
    tourism_df["latitude"],
    errors="coerce",
)

tourism_df["longitude"] = pd.to_numeric(
    tourism_df["longitude"],
    errors="coerce",
)


# ============================================================
# 4. 좌표가 정상적인 관광지만 사용
# ============================================================

before_count = len(tourism_df)

tourism_df_valid = tourism_df[
    tourism_df["latitude"].notna()
    & tourism_df["longitude"].notna()
].copy()


# 대한민국 범위에서 명백하게 잘못된 좌표 제거
tourism_df_valid = tourism_df_valid[
    tourism_df_valid["latitude"].between(
        32.0,
        39.0,
    )
    & tourism_df_valid["longitude"].between(
        124.0,
        132.0,
    )
].copy()


after_count = len(tourism_df_valid)

print("[3] 관광지 좌표 검증")
print("")

print(
    f"전체 관광지: {before_count:,}개"
)

print(
    f"정상 좌표 관광지: {after_count:,}개"
)

print(
    f"좌표 오류/누락: "
    f"{before_count - after_count:,}개"
)

print("")


# ============================================================
# 5. 관광지 → GeoDataFrame
# ============================================================

print("[4] 관광지 Point 생성")
print("")


tourism_gdf = gpd.GeoDataFrame(
    tourism_df_valid,
    geometry=gpd.points_from_xy(
        tourism_df_valid["longitude"],
        tourism_df_valid["latitude"],
    ),
    crs="EPSG:4326",
)


print(
    f"관광지 Point 생성 완료: "
    f"{len(tourism_gdf):,}개"
)

print("")


# ============================================================
# 6. 보호구역 GeoJSON 읽기
# ============================================================

print("[5] 보호구역 GeoJSON 읽는 중...")
print("")


protected_gdf = gpd.read_file(
    PROTECTED_GEOJSON
)


print(
    f"보호구역 수: "
    f"{len(protected_gdf):,}개"
)

print("")

print(
    f"보호구역 CRS: "
    f"{protected_gdf.crs}"
)

print("")


# ============================================================
# 7. 보호구역 CRS 확인
# ============================================================

print("[6] 좌표계 통일")
print("")


if protected_gdf.crs is None:
    print(
        "⚠️ 보호구역 CRS가 지정되어 있지 않습니다."
    )

    print(
        "EPSG:4326으로 가정합니다."
    )

    protected_gdf = protected_gdf.set_crs(
        "EPSG:4326"
    )


protected_gdf = protected_gdf.to_crs(
    "EPSG:4326"
)


tourism_gdf = tourism_gdf.to_crs(
    "EPSG:4326"
)


print(
    "관광지 CRS: EPSG:4326"
)

print(
    "보호구역 CRS: EPSG:4326"
)

print("")


# ============================================================
# 8. 보호구역 컬럼 확인
# ============================================================

print("[7] 보호구역 컬럼 확인")
print("")

print(
    list(protected_gdf.columns)
)

print("")


# ============================================================
# 9. 보호구역 이름/종류 컬럼 준비
# ============================================================

# match_protected_area.py에서 만든
# protected_type 컬럼을 사용

if "protected_type" not in protected_gdf.columns:

    print(
        "⚠️ protected_type 컬럼이 없습니다."
    )

    print(
        "보호구역 종류를 '보호구역'으로 처리합니다."
    )

    protected_gdf["protected_type"] = "보호구역"


# ============================================================
# 10. 보호구역 공간 매칭
# ============================================================

print("[8] 관광지 ↔ 보호구역 공간 매칭")
print("")

print(
    "관광지 좌표가 보호구역 폴리곤 안에 있는지 확인합니다."
)

print("")


# 필요한 컬럼만 사용
protected_for_join = protected_gdf[
    [
        "protected_type",
        "geometry",
    ]
].copy()


# ------------------------------------------------------------
# 관광지 하나가 여러 보호구역과 겹칠 수 있음
# ------------------------------------------------------------

joined = gpd.sjoin(
    tourism_gdf,
    protected_for_join,
    how="left",
    predicate="intersects",
)


print(
    f"공간 매칭 결과 행 수: "
    f"{len(joined):,}개"
)

print("")


# ============================================================
# 11. 관광지별 보호구역 정보 통합
# ============================================================

print("[9] 관광지별 보호구역 정보 통합")
print("")


# 관광지 원본 순서를 유지하기 위한 ID
joined["tourism_index"] = joined.index


# 보호구역 매칭 여부
joined["is_protected"] = (
    joined["protected_type"]
    .notna()
)


# ------------------------------------------------------------
# 관광지별 보호구역 종류를 합침
#
# 하나의 관광지가
# 국가 + 시도 보호구역에 동시에 걸릴 수 있으므로
# 중복 종류를 합쳐서 저장
# ------------------------------------------------------------

def combine_protected_types(series):
    values = []

    for value in series:
        if pd.isna(value):
            continue

        value = str(value).strip()

        if value == "":
            continue

        if value not in values:
            values.append(value)

    if not values:
        return ""

    return "|".join(values)


# 관광지별 그룹화
grouped = (
    joined
    .groupby("tourism_index")
    .agg(
        is_protected=(
            "is_protected",
            "max",
        ),
        protected_type=(
            "protected_type",
            combine_protected_types,
        ),
    )
)


# ============================================================
# 12. 원본 관광지 데이터에 결과 붙이기
# ============================================================

print("[10] 매칭 결과를 관광지 데이터에 결합")
print("")


result = tourism_df_valid.copy()


# index 기준으로 붙이기
result["is_protected"] = (
    grouped["is_protected"]
    .reindex(result.index)
    .fillna(False)
    .astype(bool)
)


result["protected_type"] = (
    grouped["protected_type"]
    .reindex(result.index)
    .fillna("")
)


# ============================================================
# 13. 보호구역 점수용 컬럼 추가
# ============================================================

# SNOB에서 나중에 점수 계산하기 편하도록
#
# 보호구역이면 1
# 아니면 0
#
# 형태의 숫자 컬럼도 추가

result["protected_flag"] = (
    result["is_protected"]
    .astype(int)
)


# ============================================================
# 14. 결과 통계
# ============================================================

total_count = len(result)

protected_count = int(
    result["is_protected"].sum()
)

not_protected_count = (
    total_count - protected_count
)


print("")
print("=" * 60)
print("매칭 결과")
print("=" * 60)
print("")

print(
    f"전체 관광지: "
    f"{total_count:,}개"
)

print(
    f"보호구역 관광지: "
    f"{protected_count:,}개"
)

print(
    f"보호구역 아닌 관광지: "
    f"{not_protected_count:,}개"
)

print("")


if total_count > 0:

    protected_ratio = (
        protected_count
        / total_count
        * 100
    )

    print(
        f"보호구역 관광지 비율: "
        f"{protected_ratio:.2f}%"
    )


# ============================================================
# 15. 보호구역 종류별 통계
# ============================================================

print("")
print("보호구역 종류별 관광지 수")
print("-" * 60)


protected_result = result[
    result["is_protected"]
].copy()


if len(protected_result) > 0:

    type_counts = (
        protected_result[
            "protected_type"
        ]
        .str.split("|")
        .explode()
        .value_counts()
    )

    print(type_counts)

else:

    print(
        "보호구역에 매칭된 관광지가 없습니다."
    )


# ============================================================
# 16. 샘플 확인
# ============================================================

print("")
print("[11] 매칭 결과 샘플")
print("")


sample = result[
    result["is_protected"]
].head(10)


if len(sample) > 0:

    for _, row in sample.iterrows():

        print(
            f"관광지: {row.get('title', '')}"
        )

        print(
            f"지역: {row.get('regionName', '')}"
        )

        print(
            f"좌표: "
            f"({row.get('latitude', '')}, "
            f"{row.get('longitude', '')})"
        )

        print(
            f"보호구역: "
            f"{row.get('protected_type', '')}"
        )

        print("-" * 40)

else:

    print(
        "보호구역 매칭 샘플이 없습니다."
    )


# ============================================================
# 17. CSV 저장
# ============================================================

print("")
print("[12] 결과 CSV 저장")
print("")


result.to_csv(
    OUTPUT_CSV,
    index=False,
    encoding="utf-8-sig",
)


print(
    "저장 위치:"
)

print(
    os.path.abspath(OUTPUT_CSV)
)


# ============================================================
# 18. 파일 크기 확인
# ============================================================

if os.path.exists(OUTPUT_CSV):

    file_size = (
        os.path.getsize(OUTPUT_CSV)
        / (1024 * 1024)
    )

    print("")

    print(
        f"파일 크기: "
        f"{file_size:.2f} MB"
    )


# ============================================================
# 19. 최종 완료
# ============================================================

print("")
print("=" * 60)
print("SNOB 관광지 ↔ 보호구역 매칭 완료!")
print("=" * 60)
print("")

print(
    "다음 파일이 생성되었습니다:"
)

print(
    f"→ {OUTPUT_CSV}"
)

print("")

print(
    "주요 컬럼:"
)

print(
    "  is_protected    : 보호구역 여부 (True / False)"
)

print(
    "  protected_flag  : 보호구역 여부 (1 / 0)"
)

print(
    "  protected_type  : 보호구역 종류"
)

print("")

print(
    "이제 이 데이터를 이용해서 "
    "SNOB 보호구역 점수를 계산할 수 있습니다."
)

print("")