# 소리 출처·라이선스

D-030: 그래픽은 픽셀, 소리는 리얼 사운드. 모든 재료는 CC0 (출처 표기 의무 없음, 상업 이용 가능) — 각 페이지에서 라이선스를 확인하고 받았다 (2026-10-26).
표기 의무는 없지만 감사의 뜻으로 크레딧에 남기는 것을 권한다.

## 배경음 (`export/bgm/`, 원본 `audio/bgm-src/`)

| id | 곡 | 만든 사람 | 라이선스 | 출처 | 가공 |
|---|---|---|---|---|---|
| bgm-part0 | Dungeon Ambience | yd | CC0 | https://opengameart.org/content/dungeon-ambience | 앞 0.93초·뒤 3.6초 무음 자름, 끝 4초를 처음 4초에 겹쳐 이음매 없는 반복 (197.4초) |
| bgm-part1 | Dark Shrine Loop | qubodup (yd "Shrine" 리믹스) | CC0 | https://opengameart.org/content/dark-shrine-loop | 끝 1.5초 무음 자름, 끝 3초를 처음 3초에 겹쳐 반복 (52.1초) |
| bgm-boss | Boss Battle Theme | Cleyton Kauffman | CC0 | https://opengameart.org/content/boss-battle-theme | 원곡이 반복용 — 그대로 ogg 변환 (171.5초) |

- 모두 ogg vorbis q6, 44.1kHz 스테레오. 파일 전체를 그대로 반복 재생하면 된다 (loopStart 0, loopEnd = 끝).
- 같은 곡의 `.m4a` (AAC 160k): ogg를 못 읽는 예전 사파리용 대체 (길이 동일).
- `export/bgm/loop-check/<id>-seam.ogg`: 끝 4초 + 처음 4초를 이어 붙인 이음매 확인용.

## 효과음 재료

| 재료 | 만든 사람 | 라이선스 | 출처 |
|---|---|---|---|
| Impact Sounds (130) | Kenney | CC0 | https://kenney.nl/assets/impact-sounds |
| RPG Audio (50) | Kenney | CC0 | https://kenney.nl/assets/rpg-audio |
| Interface Sounds (100) | Kenney | CC0 | https://kenney.nl/assets/interface-sounds |

### Freesound 녹음 (CC0, 공개 미리듣기 mp3 사용)

| 키 | 녹음 | 라이선스 | 출처 | 파일 |
|---|---|---|---|---|
| whoosh | hnhnh — fire-whoosh.wav | CC0 | https://freesound.org/people/hnhnh/sounds/244926/ | `audio/sfx-src/freesound/fs-244926.mp3` |
| crackleA | samarobryn — Crackling Fire | CC0 | https://freesound.org/people/samarobryn/sounds/414767/ | `audio/sfx-src/freesound/fs-414767.mp3` |
| crackleB | jmehlferber — fire-crackling.wav | CC0 | https://freesound.org/people/jmehlferber/sounds/370938/ | `audio/sfx-src/freesound/fs-370938.mp3` |
| crackleC | florianreichelt — fire crackles | CC0 | https://freesound.org/people/florianreichelt/sounds/563766/ | `audio/sfx-src/freesound/fs-563766.mp3` |
| torch | LordStirling — torch ambience loop (30~50초 구간) | CC0 | https://freesound.org/people/LordStirling/sounds/483692/ | `audio/sfx-src/freesound/fs-483692.mp3` |
| scrapeV | Vrymaa — Stone heavy - Scraping concrete | CC0 | https://freesound.org/people/Vrymaa/sounds/802691/ | `audio/sfx-src/freesound/fs-802691.mp3` |
| scrapeC | CheatinSloth — Heavy Stone Scraping, Being Dragged | CC0 | https://freesound.org/people/CheatinSloth/sounds/738784/ | `audio/sfx-src/freesound/fs-738784.mp3` |
| scrapeAxe | dslrguide — Scraping Stone | CC0 | https://freesound.org/people/dslrguide/sounds/321488/ | `audio/sfx-src/freesound/fs-321488.mp3` |
| bowl | zambolino — singing bowl.wav | CC0 | https://freesound.org/people/zambolino/sounds/439235/ | `audio/sfx-src/freesound/fs-439235.mp3` |
| wine | jhumbucker — Wine glass tinkles | CC0 | https://freesound.org/people/jhumbucker/sounds/193823/ | `audio/sfx-src/freesound/fs-193823.mp3` |
| ceramic | OwlStorm — Ceramic Tink | CC0 | https://freesound.org/people/OwlStorm/sounds/209014/ | `audio/sfx-src/freesound/fs-209014.mp3` |
| clang | jashstudios — Metal Clang | CC0 | https://freesound.org/people/jashstudios/sounds/184343/ | `audio/sfx-src/freesound/fs-184343.mp3` |
| tinkle | soundofsong — bells tinkling end.wav | CC0 | https://freesound.org/people/soundofsong/sounds/640717/ | `audio/sfx-src/freesound/fs-640717.mp3` |

### 효과음별 재료 (`audio/sfx-real-recipes.mjs`)

| 재료 키 | 쓰는 효과음 |
|---|---|
| bell0 | parry-success-b |
| bell1 | parry-success-a, parry-success |
| bell2 | parry-success-c, sentinel-cue-a, ui-confirm, sentinel-cue |
| plateL0 | parry-success-a, parry-success |
| plateH0 | parry-success-d |
| plateM0 | sentinel-hit |
| metalL0 | parry-success-b |
| glass0 | sentinel-cue-a, companion-blip-a, sentinel-cue |
| glass1 | ember-gain, staff-drop |
| glass2 | companion-blip-b, staff-shake |
| glass3 | companion-blip-c, staff-drop |
| mine0 | sentinel-attack-a, sentinel-attack-b, record-close, wall-collapse, sentinel-attack |
| mine1 | wall-collapse |
| mine3 | sentinel-hit, wall-collapse |
| softH | dash-gather, player-down, sentinel-attack-b, pillar-big, seal-door-open |
| softM | fire-impact, record-open, brazier-ignite, robe-flutter, robe-rise |
| punchM | player-hit |
| punchH | pillar-burst, parry-success-d, sentinel-attack-a, pillar-big, combo-focus, wall-collapse, sentinel-attack |
| woodL0 | ui-select, staff-drop, staff-shake |
| woodL1 | ui-confirm, combo-slot, staff-drop, staff-shake |
| woodM | parry-fail |
| cloth1 | inspect, robe-flutter, robe-rise |
| cloth2 | dash-scatter, vine-burn, robe-flutter, robe-rise |
| cloth3 | parry-try, combo-switch, robe-flutter, robe-rise |
| knife1 | parry-success-a, parry-success |
| knife2 | parry-success-d |
| door1 | door-open |
| whoosh | dash-scatter, dash-gather, fire-shoot, fire-impact, pillar-charge, pillar-burst, player-hit, player-down, sentinel-attack-a, form-change, vine-burn, fire-fan, pillar-big, pillar-quick, combo-focus, combo-switch, brazier-ignite, form-flash, wind-gust, handflame-ignite, sentinel-attack |
| crackleA | fire-shoot, pillar-burst, form-change, fire-fan, pillar-big, brazier-ignite, handflame-ignite |
| crackleB | dash-scatter, pillar-charge, ember-gain, vine-burn, pillar-quick, combo-slot, form-merge |
| crackleC | fire-impact, player-down, combo-focus, handflame-ignite |
| torch | move-hum |
| scrapeV | sentinel-windup-b, sentinel-windup-easy-b, sentinel-attack-b, sentinel-shutdown, door-open, record-open, record-close, wall-collapse |
| scrapeC | sentinel-awaken, sentinel-windup-a, sentinel-windup-easy-a, seal-door-open, sentinel-windup, sentinel-windup-easy |
| bowl | sentinel-awaken, sentinel-windup-a, sentinel-windup-b, sentinel-windup-easy-a, sentinel-windup-easy-b, sentinel-shutdown, artifact, form-change, seal-door-open, form-merge, form-flash, form-radiance, sentinel-windup, sentinel-windup-easy |
| wine | sentinel-cue-c, sentinel-shutdown, artifact, form-radiance |
| ceramic | sentinel-cue-b, emote, inspect |
| clang | parry-success-c |
| tinkle | artifact, form-merge, form-flash, form-radiance |

가공: ffmpeg (자르기·음높이·EQ·겹치기·지연·잔향 통일·최고점 맞춤), `node scripts/sfx-real.mjs`.
