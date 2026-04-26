# Plan: dockur/android

> Created by Squirrel 🐿️ on 2026-04-26
> Inspired by [dockur/windows](https://github.com/dockur/windows) & [dockur/macos](https://github.com/dockur/macos)

---

## 🎯 Goal

Docker 컨테이너 안에서 Android를 실행하는 프로젝트.  
dockur/windows처럼 `docker-compose up` 한 줄이면 브라우저로 Android에 접근 가능하게 만드는 것이 목표.  
모바일 앱 테스트 자동화, CI/CD 파이프라인, 개인 Android 환경이 필요한 개발자를 대상으로 한다.  
성공 기준: 별 10k 이상, Android 앱이 실제로 실행 가능한 수준의 완성도.

---

## 👤 Users & Use Cases

- **Primary user:** Android 앱 개발자, DevOps 엔지니어
- **Core use case:** CI/CD에서 에뮬레이터 없이 Android 앱 테스트 / 서버에서 Android 원격 접근
- **Secondary use cases:**
  - Appium / UI 자동화 테스트 서버
  - 개인용 Android 클라우드 (게임, 앱 격리 실행)
  - ARM 앱 에뮬레이션 연구

---

## 🏗️ Architecture

**Stack:** Shell + QEMU + Android-x86 ISO + noVNC + Docker

```
┌─────────────────────────────────────┐
│           Docker Container          │
│                                     │
│  ┌─────────────────────────────┐    │
│  │         QEMU (KVM)          │    │
│  │   ┌─────────────────────┐   │    │
│  │   │    Android-x86      │   │    │
│  │   │   (AOSP / GApps)    │   │    │
│  │   └─────────────────────┘   │    │
│  └──────────┬──────────────────┘    │
│             │                       │
│     ┌───────┴──────┐                │
│     │              │                │
│  noVNC           ADB TCP            │
│  :8006           :5555              │
└─────────────────────────────────────┘
         │              │
      브라우저        adb connect
```

**Why this stack:**
- QEMU: dockur 시리즈와 동일한 검증된 기반. KVM 가속 지원
- Android-x86: AOSP를 x86에 포팅한 커뮤니티 프로젝트. QEMU에서 안정적으로 구동 가능
- noVNC: 브라우저 기반 뷰어. 포트 8006 (dockur 시리즈 통일)
- ADB TCP: 개발자 친화적 접근. `adb connect localhost:5555`

**Key design decisions:**
- dockur/windows와 동일한 UX 패턴 유지 (`VERSION` env로 버전 선택, 포트 8006)
- ISO 자동 다운로드 스크립트로 사용자 설치 부담 제거
- GApps(Google Play) 선택적 포함 지원 (법적 이슈 회피, 옵션으로 제공)
- ARM 앱 호환을 위한 libhoudini 통합 검토

---

## 📋 Task Breakdown

### Layer 0 — 리서치 & 기술 검증
- [ ] 🔴 **Android-x86 vs AOSP GSI 선택** — QEMU에서 두 방식 각각 부팅 테스트. 안정적인 쪽 채택  
  Done when: 적어도 하나가 QEMU에서 GUI 부팅까지 성공
- [ ] 🔴 **KVM 가속 Android 부팅 검증** — `--enable-kvm` 옵션으로 부팅 속도 측정  
  Done when: 콜드 부팅 3분 이내
- [ ] 🟡 **noVNC → Android 화면 연결** — QEMU VNC 서버 + noVNC 브리지 동작 확인  
  Done when: 브라우저에서 Android 홈 화면 보임
- [ ] 🟡 **ADB TCP 연결 검증** — 컨테이너 외부에서 `adb connect` 성공 확인  
  Done when: `adb shell` 접속 및 `adb install` APK 설치 성공

### Layer 1 — Dockerfile & 컨테이너 기반
- [ ] 🟡 **베이스 Dockerfile 작성** — Ubuntu 기반, QEMU + noVNC + tini 설치  
  Done when: `docker build` 성공, 이미지 2GB 이하
- [ ] 🟢 **entrypoint.sh 작성** — 환경변수 파싱, QEMU 실행, noVNC 시작 순서 관리  
  Done when: `docker run` 후 포트 8006 응답
- [ ] 🟢 **compose.yml 작성** — dockur/windows 스타일로 최소 설정으로 동작  
  Done when: `docker compose up` 한 줄로 Android 뜸

### Layer 2 — ISO 자동 다운로드
- [ ] 🟡 **download.sh 작성** — VERSION 환경변수에 따라 Android-x86 ISO 자동 다운로드  
  Done when: `VERSION=13` 설정 시 올바른 ISO 다운로드
- [ ] 🟢 **체크섬 검증** — SHA256 검증으로 손상된 ISO 방지  
  Done when: 손상된 ISO 감지 후 재다운로드

### Layer 3 — 버전 매트릭스
- [ ] 🟡 **지원 버전 정의 및 ISO URL 매핑**

  | VERSION 값 | Android 버전 | ISO 소스 |
  |------------|-------------|---------|
  | `9` | Android 9 (Pie) | android-x86.org |
  | `11` | Android 11 | android-x86.org |
  | `13` | Android 13 | AOSP GSI |

  Done when: 세 버전 모두 부팅 확인

### Layer 4 — 개발자 편의 기능
- [ ] 🟡 **ADB 브리지 설정** — 포트 5555 자동 활성화, 안내 메시지 출력  
  Done when: `adb connect localhost:5555` 외부에서 성공
- [ ] 🟡 **APK 자동 설치 지원** — `/apk` 볼륨 마운트 시 부팅 후 자동 설치  
  Done when: `volumes: - ./my.apk:/apk/app.apk` 로 APK 자동 설치
- [ ] 🟢 **CPU/RAM 설정 환경변수** — `RAM_SIZE`, `CPU_CORES` 지원  
  Done when: 환경변수 바꾸면 QEMU 인자에 반영

### Layer 5 — 스토리지 & 네트워킹
- [ ] 🟢 **퍼시스턴트 스토리지** — `/storage` 볼륨으로 Android 데이터 유지  
  Done when: 컨테이너 재시작 후 앱/데이터 유지
- [ ] 🟡 **macvlan 네트워크 지원 문서화** — 독립 IP 할당 가이드  
  Done when: README FAQ에 macvlan 설정 방법 포함
- [ ] 🟢 **포트 정의** — 8006(noVNC), 5555(ADB), 5900(VNC raw) 공식화

### Layer 6 — 테스트
- [ ] 🟡 **GitHub Actions CI** — 빌드 성공 여부 자동 검증  
  Done when: PR마다 `docker build` 자동 실행
- [ ] 🔴 **E2E 부팅 테스트** — QEMU 부팅 후 ADB로 홈 화면 진입 확인 자동화  
  Done when: CI에서 Android 부팅 + ADB 연결 자동 검증
- [ ] 🟡 **멀티 버전 매트릭스 테스트** — Android 9/11/13 각각 빌드 테스트  
  Done when: 3개 버전 모두 CI 통과

### Layer 7 — README & 문서
- [ ] 🟢 **README.md** — dockur/windows 스타일의 깔끔한 문서  
  포함 항목: Features, Quick Start, FAQ(버전 선택/ADB/APK 설치/스토리지)
- [ ] 🟢 **compose.yml 예제** — 복붙 즉시 동작하는 예제
- [ ] 🟢 **YouTube 데모 영상** — dockur/windows처럼 썸네일로 README에 삽입 (스타 유입 핵심)
- [ ] 🟢 **라이선스** — MIT (dockur 시리즈 통일)

### Layer 8 — 바이럴 준비
- [ ] 🟢 **Docker Hub 이미지 퍼블리시** — `dockurr/android` (또는 개인 네임스페이스)
- [ ] 🟢 **GitHub Topics 설정** — `android`, `docker`, `virtualization`, `android-emulator`, `qemu`
- [ ] 🟢 **Hacker News / Reddit r/selfhosted 포스팅 초안** — 런치 당일 배포

---

## ⚠️ Risks & Unknowns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Android-x86이 최신 버전(13+) 미지원 | 🔴 High | 🔴 High | AOSP GSI fallback. Android 11까지만 v1 지원 |
| ARM 앱이 x86 에뮬레이터에서 미동작 | 🔴 High | 🟡 Medium | libhoudini 통합 시도. 미지원시 FAQ에 명시 |
| KVM 없는 환경(macOS 호스트)에서 극도로 느림 | 🔴 High | 🟡 Medium | 호환성 표 명시. KVM 필수 명시 |
| Google Play / GApps 법적 문제 | 🟡 Medium | 🔴 High | 기본 AOSP만 배포. GApps는 사용자가 직접 추가하도록 안내 |
| 이미지 크기 과다 (ISO 포함 시 10GB+) | 🟡 Medium | 🟡 Medium | ISO는 런타임 다운로드, 이미지에 포함 안 함 |
| dockur 팀 네임스페이스 사용 불가 | 🟡 Medium | 🟡 Medium | 개인 네임스페이스로 시작, 기여 제안 |

---

## 🚧 Constraints

- KVM 지원 Linux 호스트 필수 (macOS/Windows 호스트는 느리거나 미지원)
- Android-x86 라이선스: Apache 2.0 (배포 가능)
- GApps 포함 불가 — Google 서비스 라이선스 문제
- 이미지 크기 목표: 500MB 이하 (ISO 제외)

---

## 📌 Open Questions

- [ ] Android-x86 vs AOSP Generic System Image (GSI) — 어느 쪽이 QEMU에서 더 안정적인가?
- [ ] libhoudini (ARM 번역 레이어) 통합이 법적으로/기술적으로 가능한가?
- [ ] dockur 원작자에게 공식 org 편입 제안할 것인가, 독립 레포로 갈 것인가?
- [ ] Android 14/15 지원 로드맵 — AOSP GSI로 가능한가?
- [ ] Waydroid(컨테이너 기반 Android) 방식과 QEMU 방식 중 선택 재검토 필요?

---

## 🔀 대안 아키텍처 검토

QEMU 외에 두 가지 대안이 있음. v1은 QEMU로 진행하고 v2에서 재검토.

| 방식 | 장점 | 단점 |
|------|------|------|
| **QEMU + Android-x86** (채택) | 검증된 방식, dockur 일관성 | ARM 앱 호환성 한계 |
| **Waydroid** | 네이티브 성능, ARM 완전 지원 | Linux 호스트 커널 의존, 복잡 |
| **Cuttlefish (AOSP AVD)** | 공식 Google AVD | 설정 매우 복잡, 문서 부족 |

---

## 📝 Progress Log

| Phase | Status | Notes |
|-------|--------|-------|
| 0 Research | ⏳ | Android-x86 vs GSI 검증 필요 |
| 1 Discover | ✅ | Plan.md 작성 완료 |
| 2 Plan | ✅ | Task breakdown 완료 |
| 3 Build | ⏳ | |
| 4 Test | ⏳ | |
| 5 Bug Hunt | ⏳ | |
| 6 Polish | ⏳ | |
| 7 Document | ⏳ | |
| 8 Ship | ⏳ | |
