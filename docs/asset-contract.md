# 에셋 계약 (ribs-assets → g-game-farm)

contract: **2** (2026-10-24) — 바뀌면 숫자를 올리고 아래 변경 기록에 적는다. 캐릭터 애니메이션(`.anim.json`)의 `"contract"` 값은 형식이 바뀌지 않아 1 그대로.

ribs-assets가 만든 픽셀 애니메이션을 g-game-farm 엔진이 그대로 쓰기 위한 약속과, 두 저장소가 주고받는 흐름. 기계 검사용 스키마: [`schema/anim.schema.json`](../schema/anim.schema.json).

## 개발 흐름

원칙: **각 세션은 자기 저장소에만 쓴다.** 두 저장소 사이 경계는 공유 폴더.

| 단계 | 누가 | 무엇을 |
|---|---|---|
| 1. 요청 | 엔진 방 | ribs-assets에 이슈 (양식: 에셋 요청). 무엇을, 크기, 필요한 clip·태그, 기한 |
| 2. 제작 | 에셋 방 | 브랜치 `asset/<이슈번호>-<id>` → 미리보기 서버(home.ribs.kr:3108)에서 사용자가 확정 |
| 3. 전달 | 에셋 방 | 내보내기 → `C:\github-clones\_asset-drop\<id>\v<n>\` → 엔진 방에 알림 (세션 메시지 또는 이슈 댓글) |
| 4. 점검 | 엔진 방 | 공유 폴더에서 자기 브랜치로 복사 → 스키마 검사 + 게임 안 확인. 문제 → 이슈 댓글로 2단계로 |
| 5. 반영 | 둘 다 | 사용자 OK → ribs-assets PR 머지 **먼저** → 엔진 PR 머지 (`source`를 머지된 커밋으로) |

- 공유 폴더의 `v<n>`은 덮어쓰지 않고 쌓는다 (이전 판과 비교용). 저장소 밖이라 커밋되지 않는다.
- 커밋·push·머지는 사용자 확인 후.

### ribs-assets 브랜치

| 브랜치 | 용도 |
|---|---|
| `main` | 확정된 것만. PR로만 들어감 |
| `asset/<이슈번호>-<id>` | 에셋 요청 하나당 하나 |
| `contract/<버전>` | 이 계약 변경. 엔진 방 확인 후 머지 |
| `research/<주제>` | 실험·연구 기록 |

## 전달물

캐릭터(또는 이펙트) 하나당 두 파일:

| 파일 | 내용 |
|---|---|
| `<id>.png` | 모든 동작 프레임이 들어간 시트 한 장 (투명 배경, 반투명 픽셀 없음) |
| `<id>.anim.json` | 동작(clip)별 프레임 사각형·시간·태그 |

원본 `.aseprite`는 ribs-assets에만 둔다 (Git LFS). 게임 저장소에는 변환 결과만 간다.

## `.anim.json` 형식

```json
{
  "contract": 1,
  "id": "player-child",
  "texture": "player-child.png",
  "frameSize": [48, 24],
  "anchor": [24, 22],
  "source": "ribs-assets@1a2b3c4",
  "clips": {
    "float": { "loop": true, "frames": [
      { "sx": 0, "sy": 0, "sWidth": 48, "sHeight": 24, "durationMs": 110 }
    ] },
    "dash": { "loop": false, "frames": [
      { "sx": 0, "sy": 24, "sWidth": 48, "sHeight": 24, "durationMs": 70, "tags": ["dash:charge"] }
    ] }
  }
}
```

- 각 clip → 엔진 `SpriteAnimation`으로 1:1: `{ name: "<id>:<clip>", texture: <texture를 불러온 핸들>, loop, frames }`. `frames`의 필드는 엔진 `SpriteAnimationFrame`(`libs/engine-animation/src/lib/types.ts`)과 같은 이름·의미.
- `texture`: `.anim.json`과 같은 폴더 기준 상대 경로.
- `frameSize`: 한 캐릭터의 모든 프레임은 같은 크기 (엔진 프레임에 기준점이 없어서, 동작이 바뀔 때 캐릭터가 튀지 않게). 화면에 그려지는 크기 그대로 — 게임은 1픽셀 = 월드 1단위, 정수 배율로 그린다.
- `anchor` (필수): 프레임 안에서 캐릭터 발밑(떠 있는 캐릭터는 그림자 자리) 픽셀 좌표. 엔진은 기준점을 모르고(그리기 기준은 왼쪽 위), 게임 렌더가 엔티티 위치에서 이만큼 빼서 그린다. 엔진 프레임 필드가 아니라 게임이 해석하는 에셋 메타데이터.
- `source`: 이 결과물을 만든 ribs-assets 커밋. 전달(3단계) 때는 작업 브랜치 커밋, 반영(5단계) 때 머지된 커밋으로 다시 내보낸다.

### 방향

- **내보낸 모든 프레임은 오른쪽을 본다.** 왼쪽은 게임이 좌우 반전(flipX)으로 만든다.
- 반전해서 그릴 때 게임은 anchor x로 `frameSize[0] - anchor[0]`을 쓴다.
- 원본 `.aseprite`는 어느 방향으로 그려도 된다. 왼쪽을 보는 원본은 변환 스크립트가 반전해서 내보낸다.

### 검사 (스키마로 표현 못 하는 것)

`scripts/check-anim.mjs <파일.anim.json>`이 스키마 규칙과 함께 확인한다. 내보내기 때 자동 실행, 엔진 쪽 점검에도 쓸 수 있다.
- 모든 프레임의 `sWidth`/`sHeight` = `frameSize`
- 모든 프레임 사각형이 png 크기 안
- `anchor`가 프레임 안

## 태그 (프레임에 들어설 때 게임에 보내는 신호)

이름 규칙: `<동작>:<구간>`. 의미는 게임이 정한다. 이동 거리·무적 여부 같은 수치는 태그가 아니라 스킬 데이터에 둔다.

| 태그 | 붙는 곳 | 뜻 |
|---|---|---|
| `dash:charge` | 대시에서 불씨로 변하기 시작하는 프레임 | 변신·멈춤 구간 시작 (패널티) |
| `dash:travel` | 돌진 첫 프레임 | 이동 시작 |
| `dash:recover` | 다시 모이는 첫 프레임 | 이동 끝, 회복 구간 |
| `parry:flash` | 패링 성공 첫 프레임 | 섬광·히트스톱 등 연출 시점 |

- 엔진은 clip을 시작할 때(`startAnimationPlayer`) 0번 프레임의 태그도 보낸다. 그래서 0번 프레임에 태그를 붙여도 된다.

Aseprite에서는 태그 이름 = clip 이름, 프레임 User Data에 쉼표로 태그를 적는다 (예: `dash:travel`). 변환 스크립트가 읽는다.

## 타일셋 (contract 2)

맵(방) 그림용. 레벨 설계(실제 방 배치·충돌 칠하기)는 게임 쪽 몫이고, 에셋 방은 "Tiled에서 바로 칠할 수 있는 타일셋"과 견본 방 하나까지 만든다.

### 전달물

| 파일 | 내용 |
|---|---|
| `<id>.png` | 타일 그림. 16×16 칸, 간격·여백 없음, 투명(0) 아니면 불투명(255)만 |
| `<id>.tsj` | Tiled 외부 타일셋(JSON). 타일 애니메이션 포함. 편집용 자동 타일(Wang 세트)·타일 이름은 있으면 넣음 (선택) |
| `<id>-sample.tmj` | 견본 방 하나 (게임 `maps/README.md` 규칙대로). 타일셋이 실제로 쓰인다는 증명이자 출발점 |

### `.tsj` 규칙

- `tilewidth`/`tileheight` 16, `margin`/`spacing` 0, `columns`·`tilecount`·`imagewidth`/`imageheight`는 png와 일치.
- `image`: 같은 폴더의 `<id>.png` (상대 경로). 파일 이름은 반드시 `<id>.tsj` — 게임은 확장자를 뺀 파일 이름을 타일셋 이름으로 쓴다.
- `columns`는 자유 (게임이 빌드 때 `.tsj`에서 읽는다).
- **타일 애니메이션 (필수 지원)**: Tiled 기본 형식 `tiles[].animation = [{ "tileid", "duration" }]`.
  - 지도에 놓는 타일 = 애니메이션 첫 프레임 타일. 프레임 타일은 모두 같은 타일셋 안.
  - `duration`은 ms 정수. 같은 타일의 애니메이션은 지도 전체에서 같은 시계로 돈다 (Tiled 편집기와 같음).
- 편집용 정보(Wang 세트, 타일 `type`/이름)는 게임에 의미 없음 — 게임은 무시해도 된다. 게임적 의미(충돌 등)는 지금처럼 별도 레이어.
- 뒤집기·회전 타일은 쓰지 않는다 (변환기가 거부).

### 견본 방 레이어 (아래가 먼저 그려짐)

`floor` → `wall` → `props` (모두 그 타일셋) → `collision` (`collision` 타일셋) → `markers` (오브젝트: `entryPoint` 등). 벽은 2칸 높이(윗면+벽면 2줄)이고, 벽면 두 줄 모두 충돌 칸.

- 견본은 같은 폴더 기준으로 `<id>.tsj`와 `collision.tsj`를 가리킨다. `collision.tsj/png`는 게임 `maps/collision.tsj`(16×16 1칸, 이름 `collision`)를 그대로 복사해 함께 보낸다.
- 한 방에서 그림 타일셋 여러 개를 써도 되지만, 레이어 하나에는 타일셋 하나만.

## 위치

| 어디 | 경로 |
|---|---|
| ribs-assets (원본) | `aseprite/<id>/<id>.aseprite` |
| ribs-assets (변환 결과) | `export/<id>/` — 캐릭터: `<id>.png`, `<id>.anim.json` / 타일셋: `<id>.png`, `<id>.tsj`, `<id>-sample.tmj` |
| 공유 폴더 (전달) | `C:\github-clones\_asset-drop\<id>\v<n>\` |
| g-game-farm (복사 위치) | 캐릭터: `libs/games/roguelite/public/game/characters/<id>/` / 타일셋: `.tsj`·png는 `libs/games/roguelite/public/game/map/<id>/` (받은 그대로, 바이트 동일), 견본은 `maps/<id>-sample.tmj` (엔진 방이 `tilesets[].source`만 고침) |

## 색 의미 (참고)

방어 계열 = 흰 `#ffffff` → 연청 `#cbdbfc` → 청록 `#5fcde4` (어두운 `#306082`). 봉인 소품도 같은 계열.

## 엔진 쪽과 정한 것 (2026-10-24 엔진 방 검토)

1. **기준점**: 같은 프레임 크기 + 에셋 단위 `anchor`. 엔진에는 Transform·pivot이 없고 위치는 게임 렌더의 몫이라 계층상 맞음. 나중에 트리밍된 프레임이 필요하면 프레임에 선택 필드(오프셋)를 하위 호환으로 추가.
2. **복사 위치**: `libs/games/roguelite/public/game/characters/<id>/` (게임 `ASSET_BASE_URL` `/game/` 아래). png와 `.anim.json`을 같은 폴더에 두고 게임이 런타임에 불러옴.
3. **아틀라스 패킹**: 지금은 안 함 (캐릭터 단위 시트). 텍스처 전환 비용이 실제로 측정되면 g-game-farm 빌드 단계에서 패킹 — `sx/sy`와 `texture`만 바뀌고 형식은 그대로.

## 엔진 쪽과 정한 것 (contract 2, 2026-10-24 엔진 방 결론)

4. **위치·경로**: 위 표대로. `.tsj`·png는 수정 없이 두고, 견본 `.tmj`의 타일셋 경로만 게임 쪽에서 바꾼다.
5. **그림 타일셋 여러 개**: 게임이 타일셋 이름으로 텍스처를, `.tsj`의 `columns`로 열 수를 고른다.
6. **타일 애니메이션**: 빌드 때 `.tsj`의 `tiles[].animation`을 읽어 TileMap에 넣고, 렌더는 방 전체가 시계 하나(시뮬레이션 시간 — 게임을 멈추면 같이 멈춤)로 프레임을 고른다. 프레임 `tileid`가 범위 밖이거나 `duration` ≤ 0이면 빌드 에러. 애니메이션 프레임 타일이 지도에 직접 놓이면, 그 타일 자체에 애니메이션이 없으면 정지 그림. Wang 세트·타일 type/이름은 무시.

## 변경 기록

| contract | 날짜 | 내용 |
|---|---|---|
| 1 | 2026-10-24 | 초안 → 엔진 방 검토 반영 (anchor 필수, 방향 규칙, 검사 스크립트, 0번 프레임 태그, 1픽셀=1단위) |
| 2 | 2026-10-24 | 타일셋 전달 형식 추가 (png + .tsj + 견본 .tmj, 타일 애니메이션 필수), 미정 4~6 |
