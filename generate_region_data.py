import csv
import time
from pathlib import Path
from collections import defaultdict

import requests


# ============================================================
# SNOB Region Data Generator
# ============================================================
#
# congestion_final.csv의 모든 시군구를 기준으로
# RegionVector 데이터를 생성한다.
#
# 지역 성향:
#   관광지 API → nature / hidden / healing
#
# 혼잡도:
#   congestion_final.csv → CONGESTION_SCORE
#
# 최종:
#   lib/snob/region_data.dart
#
# ============================================================


# ============================================================
# 경로
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

CONGESTION_FILE = (
    BASE_DIR / "congestion_final.csv"
)

OUTPUT_FILE = (
    BASE_DIR
    / "lib"
    / "snob"
    / "region_data.dart"
)


# ============================================================
# Data.go.kr
# ============================================================

SERVICE_KEY = (
    "cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9"
)

BASE_URL = (
    "https://apis.data.go.kr/B551011/KorService2"
)

MOBILE_OS = "AND"
MOBILE_APP = "SNOB"

CONTENT_TYPE_ID = "12"

NUM_OF_ROWS = 100

REQUEST_TIMEOUT = 30

SLEEP = 0.05


session = requests.Session()


# ============================================================
# 문자열
# ============================================================

def clean(value):

    if value is None:
        return ""

    return str(value).strip()


# ============================================================
# API 요청
# ============================================================

def request_json(
    url,
    params,
    retries=3,
):

    for attempt in range(retries):

        try:

            response = session.get(
                url,
                params=params,
                timeout=REQUEST_TIMEOUT,
            )

            response.raise_for_status()

            return response.json()

        except Exception as e:

            print(
                f"API 오류 "
                f"({attempt + 1}/{retries}) : {e}"
            )

            if attempt < retries - 1:

                time.sleep(1)

    return None


# ============================================================
# API items
# ============================================================

def extract_items(data):

    if not data:
        return []

    try:

        items = (
            data
            .get("response", {})
            .get("body", {})
            .get("items", {})
            .get("item")
        )

    except Exception:

        return []

    if items is None:
        return []

    if isinstance(items, dict):
        return [items]

    return items


# ============================================================
# congestion_final.csv
# ============================================================

def load_congestion():

    print()
    print("=" * 60)
    print("혼잡도 데이터 로드")
    print("=" * 60)

    if not CONGESTION_FILE.exists():

        raise FileNotFoundError(
            f"파일을 찾을 수 없습니다:\n"
            f"{CONGESTION_FILE}"
        )

    regions = {}

    with open(
        CONGESTION_FILE,
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as f:

        reader = csv.DictReader(f)

        for row in reader:

            code = clean(
                row.get("SIGUNGU_CD")
            )

            name = clean(
                row.get("SIGUNGU_NM")
            )

            score_text = clean(
                row.get("CONGESTION_SCORE")
            )

            if not code:
                continue

            if not name:
                continue

            try:

                congestion = float(
                    score_text
                )

            except:

                continue

            regions[code] = {
                "code": code,
                "sigungu_name": name,
                "congestion": congestion,
            }

    print(
        f"혼잡도 지역 수 : {len(regions)}"
    )

    return regions


# ============================================================
# 시도 코드
# ============================================================

def get_region_codes():

    url = f"{BASE_URL}/ldongCode2"

    params = {
        "serviceKey": SERVICE_KEY,
        "MobileOS": MOBILE_OS,
        "MobileApp": MOBILE_APP,
        "_type": "json",
    }

    data = request_json(
        url,
        params,
    )

    items = extract_items(data)

    result = []

    for item in items:

        code = clean(
            item.get("code")
        )

        if code:
            result.append(code)

    return result


# ============================================================
# 시군구 코드
# ============================================================

def get_sigungu_codes(
    region_code,
):

    url = f"{BASE_URL}/ldongCode2"

    params = {
        "serviceKey": SERVICE_KEY,
        "MobileOS": MOBILE_OS,
        "MobileApp": MOBILE_APP,
        "_type": "json",
        "lDongRegnCd": region_code,
    }

    data = request_json(
        url,
        params,
    )

    items = extract_items(data)

    result = []

    for item in items:

        code = clean(
            item.get("code")
        )

        if code:
            result.append(code)

    return result


# ============================================================
# 관광지 조회
# ============================================================

def get_tourism_spots(
    region_code,
    sigungu_code,
    page,
):

    url = f"{BASE_URL}/areaBasedList2"

    params = {
        "serviceKey": SERVICE_KEY,
        "MobileOS": MOBILE_OS,
        "MobileApp": MOBILE_APP,
        "_type": "json",
        "numOfRows": NUM_OF_ROWS,
        "pageNo": page,
        "contentTypeId": CONTENT_TYPE_ID,
        "lDongRegnCd": region_code,
        "lDongSignguCd": sigungu_code,
    }

    data = request_json(
        url,
        params,
    )

    return extract_items(data)


# ============================================================
# 관광지 데이터 수집
# ============================================================

def collect_tourism_data():

    print()
    print("=" * 60)
    print("관광지 데이터 수집")
    print("=" * 60)

    all_spots = []

    region_codes = get_region_codes()

    print(
        f"시도 개수 : {len(region_codes)}"
    )

    for region_index, region_code in enumerate(
        region_codes,
        start=1,
    ):

        print(
            f"\n[시도 {region_index}/{len(region_codes)}]"
            f" code={region_code}"
        )

        sigungus = get_sigungu_codes(
            region_code
        )

        print(
            f"시군구 개수 : {len(sigungus)}"
        )

        for sigungu_index, sigungu_code in enumerate(
            sigungus,
            start=1,
        ):

            print(
                f"  조회 "
                f"{sigungu_index}/{len(sigungus)} "
                f": {region_code}/{sigungu_code}"
            )

            page = 1

            while True:

                items = get_tourism_spots(
                    region_code,
                    sigungu_code,
                    page,
                )

                if not items:
                    break

                for item in items:

                    item["_region_code"] = (
                        region_code
                    )

                    item["_sigungu_code"] = (
                        sigungu_code
                    )

                    all_spots.append(item)

                print(
                    f"    page={page}, "
                    f"관광지={len(items)}"
                )

                if len(items) < NUM_OF_ROWS:
                    break

                page += 1

                time.sleep(SLEEP)

            time.sleep(SLEEP)

    print()
    print(
        f"전체 관광지 수 : "
        f"{len(all_spots)}"
    )

    return all_spots


# ============================================================
# 지역 코드
# ============================================================

def make_region_code(
    region_code,
    sigungu_code,
):

    region_code = clean(
        region_code
    )

    sigungu_code = clean(
        sigungu_code
    )

    if not region_code:
        return ""

    if not sigungu_code:
        return ""

    # 실제 API에서 반환되는
    # lDongRegnCd / lDongSignguCd를
    # 그대로 조합한다.
    #
    # 예:
    #
    # 11 + 110 = 11110
    # 11 + 140 = 11140
    # 11 + 170 = 11170

    # 세종특별자치시
    # API에서 시도 코드와 시군구 코드가
    # 모두 36110으로 반환됨
    if region_code == "36110":
        return "36110"

    return (
        region_code.zfill(2)
        + sigungu_code.zfill(3)
    )


# ============================================================
# 관광지 1개 → 성향 벡터
# ============================================================

def calculate_spot_vector(
    item,
):

    title = clean(
        item.get("title")
    )

    lcls1 = clean(
        item.get("lclsSystm1")
    )

    lcls2 = clean(
        item.get("lclsSystm2")
    )

    lcls3 = clean(
        item.get("lclsSystm3")
    )

    region_code = clean(
        item.get("_region_code")
    )

    sigungu_code = clean(
        item.get("_sigungu_code")
    )

    nature = 50.0
    hidden = 50.0
    healing = 50.0


    # ========================================================
    # 자연
    # ========================================================

    if lcls1 == "NA":

        nature += 30


    if lcls2.startswith("NA01"):

        nature += 20


    if lcls1 == "HS":

        nature -= 10


    # ========================================================
    # 숨은
    # ========================================================

    if (
        lcls3
        and lcls3.endswith("00")
    ):

        hidden += 10


    hidden_keywords = [
        "공원",
        "산",
        "숲",
        "계곡",
        "길",
    ]

    for keyword in hidden_keywords:

        if keyword in title:

            hidden += 10

            break


    # ========================================================
    # 힐링
    # ========================================================

    healing_keywords = [
        "온천",
        "휴양",
        "힐링",
        "치유",
        "정원",
    ]

    for keyword in healing_keywords:

        if keyword in title:

            healing += 30

            break


    if lcls1 == "VE":

        healing -= 10


    # ========================================================
    # 범위
    # ========================================================

    nature = max(
        0,
        min(100, nature),
    )

    hidden = max(
        0,
        min(100, hidden),
    )

    healing = max(
        0,
        min(100, healing),
    )


    code = make_region_code(
        region_code,
        sigungu_code,
    )


    return {
        "code": code,
        "nature": nature,
        "hidden": hidden,
        "healing": healing,
    }


# ============================================================
# 지역별 평균
# ============================================================

def aggregate_spots(
    spots,
):

    grouped = defaultdict(
        lambda: {
            "nature": [],
            "hidden": [],
            "healing": [],
        }
    )

    for item in spots:

        vector = calculate_spot_vector(
            item
        )

        code = vector["code"]

        if not code:
            continue

        grouped[code][
            "nature"
        ].append(
            vector["nature"]
        )

        grouped[code][
            "hidden"
        ].append(
            vector["hidden"]
        )

        grouped[code][
            "healing"
        ].append(
            vector["healing"]
        )


    result = {}


    for code, values in grouped.items():

        nature_values = values[
            "nature"
        ]

        hidden_values = values[
            "hidden"
        ]

        healing_values = values[
            "healing"
        ]


        if not nature_values:
            continue


        result[code] = {

            "nature":
                sum(nature_values)
                / len(nature_values),

            "hidden":
                sum(hidden_values)
                / len(hidden_values),

            "healing":
                sum(healing_values)
                / len(healing_values),

            "spot_count":
                len(nature_values),
        }


    return result


# ============================================================
# 시군구 코드 → 시도 이름
# ============================================================

SIDO_NAMES = {
    "11": "서울특별시",
    "12": "전남광주통합특별시",
    "26": "부산광역시",
    "27": "대구광역시",
    "28": "인천광역시",
    "30": "대전광역시",
    "31": "울산광역시",
    "41": "경기도",
    "43": "충청북도",
    "44": "충청남도",
    "47": "경상북도",
    "48": "경상남도",
    "50": "제주특별자치도",
    "51": "강원특별자치도",
    "52": "전북특별자치도",
    "36": "세종특별자치시",
}


# ============================================================
# Dart 문자열
# ============================================================

def dart_string(
    value,
):

    value = clean(value)

    value = value.replace(
        "\\",
        "\\\\",
    )

    value = value.replace(
        "'",
        "\\'",
    )

    return value


# ============================================================
# Dart 숫자
# ============================================================

def dart_number(
    value,
):

    return f"{float(value):.2f}"


# ============================================================
# Dart 파일 생성
# ============================================================

def generate_dart(
    regions,
):

    OUTPUT_FILE.parent.mkdir(
        parents=True,
        exist_ok=True,
    )


    lines = []


    lines.append(
        "import 'region_vector.dart';"
    )

    lines.append("")
    lines.append("")

    lines.append(
        "// ====================================================="
    )

    lines.append(
        "// SNOB Region Data"
    )

    lines.append(
        "// Automatically generated"
    )

    lines.append(
        f"// Total regions: {len(regions)}"
    )

    lines.append(
        "// ====================================================="
    )

    lines.append("")


    lines.append(
        "const List<RegionVector> regions = ["
    )

    lines.append("")


    # 코드순 정렬
    sorted_regions = sorted(
        regions,
        key=lambda x: x[
            "code"
        ],
    )


    for region in sorted_regions:

        code = region["code"]

        sido_code = code[:2]

        sido_name = SIDO_NAMES.get(
            sido_code,
            "",
        )

        sigungu_name = region[
            "sigungu_name"
        ]

        if sido_name:

            region_name = (
                f"{sido_name} "
                f"{sigungu_name}"
            )

        else:

            region_name = (
                sigungu_name
            )


        vector = region[
            "vector"
        ]


        lines.append(
            "  RegionVector("
        )

        lines.append(
            f"    regionName: "
            f"'{dart_string(region_name)}',"
        )

        lines.append(
            f"    nature: "
            f"{dart_number(vector['nature'])},"
        )

        lines.append(
            f"    hidden: "
            f"{dart_number(vector['hidden'])},"
        )

        lines.append(
            f"    healing: "
            f"{dart_number(vector['healing'])},"
        )

        lines.append(
            f"    congestion: "
            f"{dart_number(region['congestion'])},"
        )

        lines.append(
            "  ),"
        )

        lines.append("")


    lines.append("];")

    lines.append("")


    OUTPUT_FILE.write_text(
        "\n".join(lines),
        encoding="utf-8",
    )


    print()
    print("=" * 60)
    print("region_data.dart 생성 완료")
    print("=" * 60)

    print(
        f"파일 : {OUTPUT_FILE}"
    )

    print(
        f"지역 수 : {len(regions)}"
    )


# ============================================================
# 메인
# ============================================================

def main():

    print()
    print("=" * 60)
    print("SNOB Region Data Generator")
    print("=" * 60)


    # --------------------------------------------------------
    # 1. 혼잡도 지역
    # --------------------------------------------------------

    congestion = load_congestion()


    # --------------------------------------------------------
    # 2. 관광지
    # --------------------------------------------------------

    spots = collect_tourism_data()


    # --------------------------------------------------------
    # 3. 관광지 성향 계산
    # --------------------------------------------------------

    print()
    print("=" * 60)
    print("관광지 성향 계산")
    print("=" * 60)


    spot_vectors = aggregate_spots(
        spots
    )


    print(
        f"성향 계산 지역 수 : "
        f"{len(spot_vectors)}"
    )


    # --------------------------------------------------------
    # 4. 핵심
    #
    # congestion_final.csv의 모든 지역을
    # 기준으로 사용한다.
    #
    # 관광지가 없는 지역도 삭제하지 않는다.
    # --------------------------------------------------------

    final_regions = []


    matched = 0
    no_tourism = 0


    for code, congestion_info in congestion.items():

        vector = spot_vectors.get(
            code
        )


        # ----------------------------------------------------
        # 관광지가 있는 경우
        # ----------------------------------------------------

        if vector is not None:

            final_vector = vector

            matched += 1


        # ----------------------------------------------------
        # 관광지가 없는 경우
        #
        # 지역을 삭제하지 않고
        # 기본 성향 50/50/50을 사용한다.
        #
        # 이것은 "테스트용 지역"이 아니라
        # 실제 지역이 존재하지만
        # API에서 관광지 데이터가 없는 경우의
        # 중립값이다.
        # ----------------------------------------------------

        else:

            final_vector = {

                "nature": 50.0,

                "hidden": 50.0,

                "healing": 50.0,

                "spot_count": 0,

            }

            no_tourism += 1


        final_regions.append({

            "code": code,

            "sigungu_name":
                congestion_info[
                    "sigungu_name"
                ],

            "congestion":
                congestion_info[
                    "congestion"
                ],

            "vector":
                final_vector,

        })


    # --------------------------------------------------------
    # 5. 결과 확인
    # --------------------------------------------------------

    print()
    print("=" * 60)
    print("최종 지역 데이터")
    print("=" * 60)


    print(
        f"혼잡도 기준 지역 : "
        f"{len(congestion)}"
    )

    print(
        f"관광지 데이터 매칭 : "
        f"{matched}"
    )

    print(
        f"관광지 데이터 없음 : "
        f"{no_tourism}"
    )

    print(
        f"최종 RegionVector : "
        f"{len(final_regions)}"
    )


    # --------------------------------------------------------
    # 6. 샘플 출력
    # --------------------------------------------------------

    print()
    print("샘플 지역:")


    for region in final_regions[:10]:

        vector = region[
            "vector"
        ]

        print(
            f"{region['code']} "
            f"{region['sigungu_name']} "
            f"| 자연 {vector['nature']:.1f} "
            f"| 숨은 {vector['hidden']:.1f} "
            f"| 힐링 {vector['healing']:.1f} "
            f"| 혼잡 {region['congestion']:.1f} "
            f"| 관광지 {vector['spot_count']}"
        )


    # --------------------------------------------------------
    # 7. Dart 생성
    # --------------------------------------------------------

    generate_dart(
        final_regions
    )


    print()
    print("=" * 60)
    print("완료")
    print("=" * 60)

    print(
        "이제 Flutter에서:"
    )

    print(
        "RecommendationEngine → regions"
    )

    print(
        "구조로 바로 사용할 수 있습니다."
    )


# ============================================================
# 실행
# ============================================================

if __name__ == "__main__":

    main()