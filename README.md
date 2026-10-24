# ribs-assets

[ribs-home](https://github.com/goju2k/ribs-home)에서 쓰는 게임 에셋(3D 모델, 2D 스프라이트)과 그 연구 기록.

## 구조

```
blender/<에셋>/      3D — 원본 .blend, 생성 스크립트(.py), 내보낸 .glb, 미리보기 .png
aseprite/<에셋>/     2D — 원본 .aseprite, 내보낸 스프라이트 시트 .png + .json
research/            실험·참고자료 메모 (날짜-주제.md)
scripts/             일괄 내보내기 도구
```

에셋 폴더마다 `README.md`에 용도, 크기 기준(미터·픽셀), 원본 출처를 적는다.

## 게임(g-game-farm)과 주고받기

요청 → 제작 → 공유 폴더로 전달 → 엔진 점검 → 양쪽 반영. 형식·흐름·브랜치 규칙은 [docs/asset-contract.md](docs/asset-contract.md), 형식 검사용 스키마는 [schema/anim.schema.json](schema/anim.schema.json). 요청은 이슈 양식 "에셋 요청"으로.

## 원격 미리보기 — http://home.ribs.kr:3108

```bash
scripts/preview.sh   # 서버(127.0.0.1:3208) + 중계 컨테이너 dev-proxy-3108 켜기
```

- `scratch/`(커밋 안 함), `blender/`, `aseprite/`, `research/` 의 파일이 최신순 카드로 나온다. 파일이 바뀌면 열린 페이지가 자동 갱신(새 파일은 파란 테두리).
- `.glb` → 3D 뷰어(돌리기·확대), `.png` + 같은 이름 `.json`(Aseprite 내보내기) → 태그별 애니메이션 재생, 그 밖의 이미지·영상·`.md`·`.py` → 그대로 표시.
- 공유기 포트 3100~3110 중 ribs-home이 3100·3102(·3104 UDP)를 쓰고, 이 저장소는 **3108**을 쓴다.
- 공유기 NAT 루핑이 안 돼서 집 안 PC에서는 `home.ribs.kr:3108`이 안 열린다 → 집 안에서는 `http://127.0.0.1:3108`, 외부 확인은 휴대폰 LTE 또는 `node ../ops/extcheck.mjs http http://home.ribs.kr:3108/`.

## 원격 미리보기 — http://home.ribs.kr:3108

\이미 실행 중: http://home.ribs.kr:3108
- (커밋 안 함), , ,  의 파일이 최신순 카드로 나온다. 파일이 바뀌면 열린 페이지가 자동 갱신(새 파일은 파란 테두리).
-  → 3D 뷰어(돌리기·확대),  + 같은 이름 (Aseprite 내보내기) → 태그별 애니메이션 재생, 그 밖의 이미지·영상·· → 그대로 표시.
- 공유기 포트 3100~3110 중 ribs-home이 3100·3102(·3104 UDP)를 쓰고, 이 저장소는 **3108**을 쓴다.

## 내보내기

```bash
# Blender: .blend → .glb (같은 폴더에)
scripts/export-blend.sh blender/<에셋>/<파일>.blend

# Aseprite: .aseprite → 스프라이트 시트 .png + 프레임/태그 .json (같은 폴더에)
scripts/export-aseprite.sh aseprite/<에셋>/<파일>.aseprite
```

## 도구

- Blender 4.5 LTS
- Aseprite (Steam)
- 큰 바이너리(.blend, .aseprite, .glb, .png 등)는 Git LFS로 저장 — `.gitattributes` 참고

## 라이선스

별도 표기가 없으면 저장소 소유자에게 저작권이 있다.
