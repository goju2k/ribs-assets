# 소리 용량 줄이기 (D-049, 2026-10-27)

- 배경음: `scripts/bgm.mjs`로 원본에서 다시 만듦. part0 드론은 모노 40k이고 반복을 197초에서 100초로 줄임(끝 4초 겹침). part1은 80k, boss는 64k. m4a도 같은 기준.
- 효과음: `scripts/sfx-real.mjs`가 wav 원본과 함께 ogg(vorbis q4 모노)·m4a(AAC 96k 모노)를 만듦. 뒤쪽 무음은 자르고, 앞은 시점을 맞춘 소리라 그대로 둠. 게임에는 압축판만 넘김.
- 음질 확인 (고음 대역 에너지, 전체 대비 dB, wav → ogg → m4a)
  - 패링 성공 "챙" 8kHz 위: -17.0 → -17.3 → -17.3, 12kHz 위: -22.7 → -22.9 → -23.3
  - 수호체 "팅" 4kHz 위: -13.3 → -13.1 → -13.3, 8kHz 위: -28.8 → -28.7 → -29.7
  - 두 소리의 m4a는 128k로 올림. 핵심 대역 차이는 0.5dB 안이라 뭉개짐 없음.

## 배경음

| id | 이전 ogg | 이후 ogg | 이전 m4a | 이후 m4a |
|---|---:|---:|---:|---:|
| bgm-part0 | 2661KB | 416KB | 3899KB | 607KB |
| bgm-part1 | 688KB | 411KB | 1027KB | 621KB |
| bgm-boss | 4148KB | 1278KB | 3520KB | 1721KB |
| **합계** | **7497KB** | **2105KB** | **8445KB** | **2950KB** |

## 효과음 (게임이 쓰는 정식 id만, 후보 -a/-b… 제외)

| id | 이전 wav | 이후 ogg | 이후 m4a |
|---|---:|---:|---:|
| move-hum | 60KB | 9KB | 10KB |
| dash-scatter | 41KB | 8KB | 7KB |
| dash-gather | 90KB | 11KB | 12KB |
| fire-shoot | 27KB | 6KB | 4KB |
| fire-impact | 45KB | 7KB | 5KB |
| pillar-charge | 132KB | 16KB | 19KB |
| pillar-burst | 215KB | 25KB | 29KB |
| ember-gain | 26KB | 5KB | 3KB |
| player-hit | 49KB | 6KB | 5KB |
| player-down | 146KB | 15KB | 20KB |
| parry-try | 39KB | 7KB | 5KB |
| parry-fail | 46KB | 6KB | 6KB |
| sentinel-awaken | 143KB | 17KB | 20KB |
| sentinel-hit | 105KB | 9KB | 9KB |
| sentinel-shutdown | 161KB | 18KB | 21KB |
| artifact | 203KB | 27KB | 29KB |
| form-change | 364KB | 39KB | 52KB |
| door-open | 133KB | 14KB | 18KB |
| vine-burn | 70KB | 10KB | 9KB |
| companion-blip-a | 6KB | 4KB | 2KB |
| companion-blip-b | 6KB | 4KB | 2KB |
| companion-blip-c | 7KB | 4KB | 2KB |
| emote | 37KB | 6KB | 5KB |
| ui-select | 19KB | 4KB | 2KB |
| ui-confirm | 37KB | 5KB | 3KB |
| fire-fan | 32KB | 6KB | 4KB |
| pillar-big | 174KB | 21KB | 21KB |
| pillar-quick | 48KB | 8KB | 7KB |
| combo-focus | 143KB | 13KB | 14KB |
| combo-switch | 38KB | 6KB | 5KB |
| combo-slot | 14KB | 4KB | 2KB |
| inspect | 62KB | 9KB | 8KB |
| record-open | 59KB | 8KB | 8KB |
| record-close | 144KB | 11KB | 13KB |
| brazier-ignite | 109KB | 14KB | 13KB |
| seal-door-open | 246KB | 22KB | 31KB |
| wall-collapse | 157KB | 13KB | 15KB |
| form-merge | 134KB | 18KB | 19KB |
| form-flash | 108KB | 14KB | 14KB |
| staff-drop | 48KB | 7KB | 6KB |
| staff-shake | 122KB | 15KB | 16KB |
| wind-gust | 118KB | 15KB | 17KB |
| robe-flutter | 140KB | 18KB | 19KB |
| robe-rise | 263KB | 22KB | 33KB |
| form-radiance | 276KB | 32KB | 39KB |
| handflame-ignite | 84KB | 11KB | 11KB |
| seal-lamp-on-1 | 69KB | 11KB | 11KB |
| seal-lamp-on-2 | 69KB | 11KB | 11KB |
| seal-lamp-on-3 | 69KB | 11KB | 11KB |
| seal-lamp-on-4 | 69KB | 11KB | 11KB |
| seal-lamp-on-5 | 69KB | 11KB | 11KB |
| seal-lamp-on | 69KB | 11KB | 11KB |
| vista-reveal | 190KB | 15KB | 27KB |
| parry-success | 113KB | 9KB | 10KB |
| sentinel-windup | 52KB | 8KB | 8KB |
| sentinel-windup-easy | 78KB | 11KB | 12KB |
| sentinel-cue | 23KB | 5KB | 3KB |
| sentinel-attack | 160KB | 11KB | 15KB |
| **합계 (58개)** | **5756KB** | **695KB** | **756KB** |

후보 포함 전체 71개: wav 6800KB → ogg 807KB / m4a 880KB

**게임이 받는 양 (ogg 기준)**: 배경음 7497KB → 2105KB, 효과음 5756KB → 695KB, 합계 12.9MB → 2.74MB
