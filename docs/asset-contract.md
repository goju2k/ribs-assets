# 에셋 계약 (ribs-assets → g-game-farm)

contract: **1** (초안, 2026-10-24) — 바뀌면 숫자를 올리고 아래 변경 기록에 적는다.

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
- `frameSize`: 한 캐릭터의 모든 프레임은 같은 크기 (엔진 프레임에 기준점이 없어서, 동작이 바뀔 때 캐릭터가 튀지 않게).
- `anchor`: 프레임 안에서 캐릭터 발밑(떠 있는 캐릭터는 그림자 자리) 픽셀 좌표. 게임이 엔티티 위치에서 이만큼 빼서 그리면 된다. (미정 1 참고)
- `source`: 이 결과물을 만든 ribs-assets 커밋. 전달(3단계) 때는 작업 브랜치 커밋, 반영(5단계) 때 머지된 커밋으로 다시 내보낸다.

## 태그 (프레임에 들어설 때 게임에 보내는 신호)

이름 규칙: `<동작>:<구간>`. 의미는 게임이 정한다. 이동 거리·무적 여부 같은 수치는 태그가 아니라 스킬 데이터에 둔다.

| 태그 | 붙는 곳 | 뜻 |
|---|---|---|
| `dash:charge` | 대시에서 불씨로 변하기 시작하는 프레임 | 변신·멈춤 구간 시작 (패널티) |
| `dash:travel` | 돌진 첫 프레임 | 이동 시작 |
| `dash:recover` | 다시 모이는 첫 프레임 | 이동 끝, 회복 구간 |
| `parry:flash` | 패링 성공 첫 프레임 | 섬광·히트스톱 등 연출 시점 |

Aseprite에서는 태그 이름 = clip 이름, 프레임 User Data에 쉼표로 태그를 적는다 (예: `dash:travel`). 변환 스크립트가 읽는다.

## 위치

| 어디 | 경로 |
|---|---|
| ribs-assets (원본) | `aseprite/<id>/<id>.aseprite` |
| ribs-assets (변환 결과) | `export/<id>/<id>.png`, `<id>.anim.json` |
| 공유 폴더 (전달) | `C:\github-clones\_asset-drop\<id>\v<n>\` |
| g-game-farm (복사 위치) | `libs/games/roguelite/public/game/characters/<id>/` |

## 색 의미 (참고)

방어 계열 = 흰 `#ffffff` → 연청 `#cbdbfc` → 청록 `#5fcde4` (어두운 `#306082`). 봉인 소품도 같은 계열.

## 미정 (엔진 쪽 의견 필요)

1. **기준점**: 지금은 같은 프레임 크기 + `anchor`로 맞춤. 엔진 `SpriteAnimationFrame`에 기준점 필드를 넣을지는 엔진 쪽 결정.
2. **복사 위치**: `public/game/characters/<id>/`로 괜찮은지.
3. **아틀라스 패킹**: 지금은 동작별 한 줄씩 배치한 단순 시트. 여러 캐릭터를 한 장으로 묶는 패킹이 필요해지면 `sx/sy`만 바뀌고 형식은 그대로.

## 변경 기록

| contract | 날짜 | 내용 |
|---|---|---|
| 1 | 2026-10-24 | 초안 |
