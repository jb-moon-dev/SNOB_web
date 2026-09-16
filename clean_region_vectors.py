import json
from pathlib import Path


# ============================================================
# 경로 설정
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

REGION_VECTOR_FILE = BASE_DIR / "assets" / "data" / "region_vectors.json"
CONCENTRATION_FILE = BASE_DIR / "assets" / "data" / "snob_concentration.json"

OUTPUT_FILE = BASE_DIR / "assets" / "data" / "region_vectors_canonical.json"


# ============================================================
# 문자열 정리
# ============================================================

def normalize(value):
    if value is None:
        return ""

    return " ".join(str(value).strip().split())


# ============================================================
# canonical 210 지역 불러오기
# ============================================================

def load_canonical_regions():
    print()
    print("=" * 70)
    print("📂 SNOB canonical 지역 불러오기")
    print("=" * 70)

    with open(CONCENTRATION_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    records = data.get("records", [])

    if not isinstance(records, list):
        raise ValueError(
            "snob_concentration.json의 records가 리스트가 아닙니다."
        )

    canonical_regions = set()

    for record in records:
        if not isinstance(record, dict):
            continue

        sido = normalize(record.get("sido"))
        sigungu = normalize(record.get("sigungu"))

        if not sido or not sigungu:
            continue

        canonical_regions.add(
            normalize(f"{sido} {sigungu}")
        )

    print(f"원본 concentration record 수 : {len(records):,}")
    print(f"canonical 지역 수              : {len(canonical_regions)}")

    if len(canonical_regions) != 210:
        print()
        print("⚠️ 주의: canonical 지역 수가 210이 아닙니다.")

    return canonical_regions


# ============================================================
# region_vectors 지역명 정리
# ============================================================

def convert_region_name(region_name, canonical_regions):
    """
    region_vectors.json의 지역명을
    snob_concentration.json의 canonical 지역명으로 변환한다.

    중요한 원칙:
    - 정확히 일치하면 그대로 사용
    - 명확한 전남광주통합특별시 → 전라남도 변환만 허용
    - 애매한 지역은 절대 추측해서 변환하지 않음
    """

    name = normalize(region_name)

    # --------------------------------------------------------
    # 1. 이미 canonical이면 그대로 사용
    # --------------------------------------------------------

    if name in canonical_regions:
        return name, "exact"


    # --------------------------------------------------------
    # 2. 전남광주통합특별시 → 전라남도
    #
    # 예:
    # 전남광주통합특별시 무안군
    # → 전라남도 무안군
    #
    # 단, 실제 canonical 210에 존재할 때만 변환
    # --------------------------------------------------------

    prefix = "전남광주통합특별시 "

    if name.startswith(prefix):
        sigungu = name[len(prefix):].strip()

        target = normalize(
            f"전라남도 {sigungu}"
        )

        if target in canonical_regions:
            return target, "rename"


    # --------------------------------------------------------
    # 3. 그 외에는 변환하지 않음
    #
    # 특히 아래는 자동 변환하지 않는다.
    #
    # 전북특별자치도 → 전라북도
    # 광주광역시
    # 인천광역시 검단구
    # 인천광역시 서해구
    # 인천광역시 영종구
    # 인천광역시 제물포구
    # 화성시 동탄구 등
    #
    # canonical 210에 없으면 제외
    # --------------------------------------------------------

    return None, "excluded"


# ============================================================
# region_vectors 읽기
# ============================================================

def load_region_vectors():
    print()
    print("=" * 70)
    print("📂 region_vectors.json 불러오기")
    print("=" * 70)

    with open(REGION_VECTOR_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError(
            "region_vectors.json은 JSON 리스트 형식이어야 합니다."
        )

    print(f"기존 RegionVector 수 : {len(data)}")

    return data


# ============================================================
# 메인 정리
# ============================================================

def main():

    print()
    print("=" * 70)
    print("🧹 SNOB region_vectors canonical 정리")
    print("=" * 70)

    # --------------------------------------------------------
    # 파일 존재 확인
    # --------------------------------------------------------

    if not REGION_VECTOR_FILE.exists():
        raise FileNotFoundError(
            f"region_vectors.json을 찾을 수 없습니다.\n"
            f"{REGION_VECTOR_FILE}"
        )

    if not CONCENTRATION_FILE.exists():
        raise FileNotFoundError(
            f"snob_concentration.json을 찾을 수 없습니다.\n"
            f"{CONCENTRATION_FILE}"
        )

    # --------------------------------------------------------
    # 데이터 로드
    # --------------------------------------------------------

    canonical_regions = load_canonical_regions()
    region_vectors = load_region_vectors()


    # --------------------------------------------------------
    # 정리 시작
    # --------------------------------------------------------

    cleaned = []

    renamed = []
    excluded = []
    duplicates = []

    used_targets = {}


    for vector in region_vectors:

        if not isinstance(vector, dict):
            continue

        original_name = normalize(
            vector.get("regionName")
        )

        if not original_name:
            excluded.append(
                ("<빈 지역명>", "지역명이 비어 있음")
            )
            continue


        # canonical 이름으로 변환
        target_name, status = convert_region_name(
            original_name,
            canonical_regions,
        )


        # ----------------------------------------------------
        # canonical에 없는 지역
        # ----------------------------------------------------

        if target_name is None:

            excluded.append(
                (
                    original_name,
                    "canonical 210에 없음"
                )
            )

            continue


        # ----------------------------------------------------
        # 중복 canonical 지역 처리
        # ----------------------------------------------------

        if target_name in used_targets:

            previous_name = used_targets[target_name]

            duplicates.append(
                (
                    target_name,
                    previous_name,
                    original_name
                )
            )

            # ------------------------------------------------
            # 중요:
            #
            # 이미 정확한 canonical 지역이 존재하면
            # 뒤의 변환 지역을 버린다.
            #
            # 예:
            # 경기도 화성시
            # 경기도 화성시 동탄구
            #
            # → 경기도 화성시만 유지
            # ------------------------------------------------

            if previous_name == target_name:
                excluded.append(
                    (
                        original_name,
                        f"canonical 지역 {target_name}와 중복"
                    )
                )
                continue

            # 혹시 변환 지역이 먼저 들어온 경우
            # 정확한 canonical 지역을 우선하기 위해
            # 기존 항목을 제거한다.

            cleaned = [
                item
                for item in cleaned
                if normalize(item["regionName"]) != target_name
            ]

            excluded.append(
                (
                    previous_name,
                    f"{target_name} 정확한 canonical 지역 우선"
                )
            )


        # ----------------------------------------------------
        # 원본 데이터 복사
        # ----------------------------------------------------

        new_vector = dict(vector)

        # 지역명만 canonical 이름으로 변경
        new_vector["regionName"] = target_name

        cleaned.append(new_vector)

        used_targets[target_name] = target_name


        # ----------------------------------------------------
        # 변경 기록
        # ----------------------------------------------------

        if status == "rename":
            renamed.append(
                (original_name, target_name)
            )


    # ========================================================
    # JSON 저장
    # ========================================================

    with open(
        OUTPUT_FILE,
        "w",
        encoding="utf-8",
    ) as f:

        json.dump(
            cleaned,
            f,
            ensure_ascii=False,
            indent=2,
        )


    # ========================================================
    # 결과 출력
    # ========================================================

    print()
    print("=" * 70)
    print("✅ 정리 완료")
    print("=" * 70)

    print(f"canonical 지역 수       : {len(canonical_regions)}")
    print(f"기존 RegionVector 수    : {len(region_vectors)}")
    print(f"정리 후 RegionVector 수 : {len(cleaned)}")
    print(f"지역명 변경             : {len(renamed)}")
    print(f"제외된 지역             : {len(excluded)}")
    print(f"중복 발견               : {len(duplicates)}")

    # --------------------------------------------------------
    # 이름 변경 목록
    # --------------------------------------------------------

    if renamed:

        print()
        print("-" * 70)
        print("🔄 지역명 변경")
        print("-" * 70)

        for old, new in renamed:
            print(f"{old} → {new}")


    # --------------------------------------------------------
    # 제외 목록
    # --------------------------------------------------------

    if excluded:

        print()
        print("-" * 70)
        print("🚫 제외된 지역")
        print("-" * 70)

        for name, reason in excluded:
            print(f"{name}")
            print(f"  └─ {reason}")


    # --------------------------------------------------------
    # 중복 목록
    # --------------------------------------------------------

    if duplicates:

        print()
        print("-" * 70)
        print("⚠️ 중복 canonical 지역")
        print("-" * 70)

        for target, previous, current in duplicates:
            print(f"canonical : {target}")
            print(f"기존      : {previous}")
            print(f"현재      : {current}")
            print()


    # --------------------------------------------------------
    # 출력 파일
    # --------------------------------------------------------

    print()
    print("=" * 70)
    print("📁 출력 파일")
    print("=" * 70)

    print(OUTPUT_FILE)

    print()
    print("⚠️ 기존 region_vectors.json은 수정하지 않았습니다.")
    print("새 파일을 확인한 뒤 문제가 없으면 교체하면 됩니다.")


# ============================================================
# 실행
# ============================================================

if __name__ == "__main__":
    main()
