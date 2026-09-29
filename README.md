# 窓ふき勇者 / WINDOW HERO

> 汚れた魔王城を、戦わず、ハシゴで登り、窓を磨いて攻略する。

Godot 4.7 で制作する、**ハシゴ配置 × 窓ふき × 探索 × 軽ローグライト**。

## Game Pillars

1. **CLIMB** - ハシゴをどこへ掛ければ届くか考える
2. **CLEAN** - 窓をゴシゴシして最後の「キュッ！」を気持ちよくする
3. **DISCOVER** - 磨いた窓の向こうに部屋・住人・仕掛けが現れる
4. **OPTIMIZE** - 掛け替え回数や移動距離を詰められる
5. **HEAL** - 敵を倒さず、最後まで「綺麗にする」で解決する

## Current Goal

### Ladder logic puzzle prototype — 2026-09-30

**1本のハシゴを、縦の道にも横の橋にも使う論理パズル。** 3城壁・16窓の短いランを実装しています。最後は四階建ての塔で、Eの窓を磨いて中段の回廊を開き、横橋を上段から最上階の到達まで使い回します。日本語 / English、マウス / タッチ、キーボード移動に対応しています。

2枚目は途切れたベランダ、3枚目は上下二段の切れ目と雨戸の連鎖。住人から選ぶ道具で解法も変わります。画面の「仕掛け」で条件を確認でき、考えている間は時間が止まります。目標回数を超えてもクリア可能です。

- `project.godot` を **Godot 4.7 stable** で開き、F6ではなくF5で実行。
- Web版は `build/web/index.html` へ書き出します。`python tools/serve.py` のあと、[ローカルで遊ぶ](http://127.0.0.1:8066)。HTMLのダブルクリック起動ではなくHTTP経由で開きます。
- itch.io提出用アーカイブ：`build/window-hero-itch.zip`（生成物のためGit対象外）。
- [遊び方・ビルド手順](docs/BUILD_AND_PLAY.md)
- [検証結果と残る確認](docs/PLAYTEST_2026-09-29.md)
- [四階建て塔・縦横ハシゴの論理パズル設計](docs/LADDER_PUZZLE_v0.3.md)
- [itch.io掲載文と提出手順](docs/ITCH_SUBMISSION.md)
- [素材・ライセンス一覧](CREDITS.md)
- [生成アセット21点・組み込み・レビュー方法](docs/ASSET_PRODUCTION_v0.1.md)

### Scope

最初に作るのは巨大なローグライトではなく、次の30秒が面白いかを検証する Vertical Slice。

```
ハシゴを持つ
→ 掛ける
→ 登る
→ 汚れた窓を指/マウスで拭く
→ キュッ！
→ ガラスが透明になる
→ 窓の向こうの住人/仕掛けが見える
→ 次の窓へ行きたくなる
```

このループが気持ちよくなるまで、コンテンツ量を増やさない。

## Target

- Engine: Godot 4.7
- Primary: Web / mobile portrait
- Reference resolution: 720 × 1280
- Input: mouse + touch
- Jam build: 8-12 minutes
- Product vision: 20-30 minute roguelite runs

## Docs

- [MASTER DESIGN v0.1](docs/MASTER_DESIGN_v0.1.md)
- [Vertical Slice v0.1](docs/VERTICAL_SLICE_v0.1.md)
- [Implementation Sprint v0.1](docs/IMPLEMENTATION_SPRINT_v0.1.md)
- [AI development rules](AGENTS.md)

## Core Ending

魔王を倒さず「心の窓」を磨く。

最後に勇者だけが抜ける**伝説のハシゴ**を引き抜くと、天まで伸びる。

> NEXT JOB: THE WINDOWS OF HEAVEN
