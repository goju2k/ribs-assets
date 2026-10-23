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
