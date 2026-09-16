import os
import pandas as pd
import geopandas as gpd


# ============================================================
# 경로
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

TOURISM_CSV = os.path.join(
    BASE_DIR,
    "data",
    "tourism_spots.csv",
)

PROTECTED_GEOJSON = os.path.join(
    BASE_DIR,
    "data",
    "protected_areas.geojson",
)

OUTPUT_CSV = os.path.join(
    BASE_DIR,
    "data",
    "tourism_spots_protected.csv",
)


# ============================================================
# 시작
# ============================================================

print("=" * 60)
print("SNOB 관광지 ↔ 보호구역 공간 매칭 시작")
print("=" * 60)


# ============================================================
# 1. 관광지 CSV
# ============================================================

print("")
print("[1/7] 관광지 데이터 읽는 중...")

if not os.path.exists(TOURISM_CSV):
    raise FileNotFoundError(
        f"\n관광지 CSV를 찾을 수 없습니다:\n"
        f"{TOURISM_CSV}\n\n"
        f"먼저 다음 명령을 실행하세요:\n"
        f"dart run lib/test.dart"
    )

tourism = pd.read_csv(
    TOURISM_CSV,
    dtype=str,
    encoding="utf-8-sig",
)

print(
    f"  → 관광지 {len(tourism):,}개"
)


# ============================================================
# 2. 좌표 처리
# ============================================================

print("")
print("[2/7] 관광지 좌표 처리 중...")

tourism["latitude"] = pd.to_numeric(
    tourism["latitude"],
    errors="coerce",
)

tourism["longitude"] = pd.to_numeric(
    tourism["longitude"],
    errors="coerce",
)

original_count = len(tourism)

tourism = tourism.dropna(
    subset=[
        "latitude",
        "longitude",
    ]
).copy()

print(
    f"  → 전체 관광지 : "
    f"{original_count:,}개"
)

print(
    f"  → 좌표 있음 : "
    f"{len(tourism):,}개"
)

print(
    f"  → 좌표 없음 : "
    f"{original_count - len(tourism):,}개"
)


# ============================================================
# 3. 잘못된 좌표 제거
# ============================================================

print("")
print("[3/7] 좌표 유효성 검사 중...")

valid_coordinate = (
    tourism["latitude"].between(-90, 90)
    &
    tourism["longitude"].between(-180, 180)
)

invalid_count = (
    (~valid_coordinate).sum()
)

tourism = tourism[
    valid_coordinate
].copy()

print(
    f"  → 잘못된 좌표 제거 : "
    f"{invalid_count:,}개"
)

print(
    f"  → 최종 좌표 관광지 : "
    f"{len(tourism):,}개"
)


# ============================================================
# 4. Point 생성
# ============================================================

print("")
print("[4/7] 관광지 좌표 → Point 변환 중...")

tourism_gdf = gpd.GeoDataFrame(
    tourism,
    geometry=gpd.points_from_xy(
        tourism["longitude"],
        tourism["latitude"],
    ),
    crs="EPSG:4326",
)

print(
    f"  → Point {len(tourism_gdf):,}개 생성"
)


# ============================================================
# 5. 보호구역 GeoJSON
# ============================================================

print("")
print("[5/7] 보호구역 데이터 읽는 중...")

if not os.path.exists(PROTECTED_GEOJSON):
    raise FileNotFoundError(
        f"\n보호구역 GeoJSON을 찾을 수 없습니다:\n"
        f"{PROTECTED_GEOJSON}"
    )

protected = gpd.read_file(
    PROTECTED_GEOJSON
)

print(
    f"  → 보호구역 : "
    f"{len(protected):,}개"
)

print(
    f"  → 원본 CRS : "
    f"{protected.crs}"
)


# ============================================================
# 6. CRS 통일 + 공간 매칭
# ============================================================

print("")
print("[6/7] 공간 매칭 중...")

protected = protected.to_crs(
    "EPSG:4326"
)

print(
    "  → CRS 통일 : EPSG:4326"
)

# 필요한 컬럼 확인
if "protected_type" not in protected.columns:
    raise ValueError(
        "protected_areas.geojson에 "
        "'protected_type' 컬럼이 없습니다."
    )

protected_small = protected[
    [
        "protected_type",
        "geometry",
    ]
].copy()


# ------------------------------------------------------------
# Point가 보호구역 polygon 내부에 있는지 검사
# ------------------------------------------------------------

matched = gpd.sjoin(
    tourism_gdf,
    protected_small,
    how="left",
    predicate="within",
)

print(
    f"  → 공간 매칭 완료"
)


# ============================================================
# 7. 관광지별 결과 정리
# ============================================================

print("")
print("[7/7] 관광지별 보호구역 여부 계산 중...")


# ------------------------------------------------------------
# 하나의 관광지가 여러 보호구역에 들어갈 수 있음
# 따라서 contentId 기준으로 합침
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

    return "|".join(values)


matched_summary = (
    matched
    .groupby(
        "contentId",
        as_index=False,
    )
    .agg(
        protected_type=(
            "protected_type",
            combine_protected_types,
        )
    )
)


# ------------------------------------------------------------
# 원본 관광지 데이터와 결합
# ------------------------------------------------------------

result = tourism.merge(
    matched_summary,
    on="contentId",
    how="left",
)


# ------------------------------------------------------------
# 보호구역 여부
# ------------------------------------------------------------

result["protected_type"] = (
    result["protected_type"]
    .fillna("")
    .astype(str)
    .str.strip()
)

result["protected"] = (
    result["protected_type"]
    .ne("")
    .astype(int)
)


# ============================================================
# 결과 저장
# ============================================================

result.to_csv(
    OUTPUT_CSV,
    index=False,
    encoding="utf-8-sig",
)


# ============================================================
# 결과 통계
# ============================================================

protected_count = int(
    result["protected"].sum()
)

not_protected_count = (
    len(result)
    - protected_count
)

print("")
print("=" * 60)
print("                 매칭 완료")
print("=" * 60)

print("")
print(
    f"좌표가 있는 관광지 : "
    f"{len(result):,}개"
)

print(
    f"보호구역 내 관광지 : "
    f"{protected_count:,}개"
)

print(
    f"보호구역 외 관광지 : "
    f"{not_protected_count:,}개"
)

print("")

print("보호구역 종류별 관광지 수:")
print("------------------------------------------------------------")

protected_only = result[
    result["protected"] == 1
]

if len(protected_only) > 0:
    print(
        protected_only[
            "protected_type"
        ].value_counts()
    )
else:
    print(
        "보호구역과 매칭된 관광지가 없습니다."
    )

print("")
print("결과 파일:")
print(
    OUTPUT_CSV
)

print("")
print("=" * 60)
print("SNOB 보호구역 매칭 종료")
print("=" * 60)