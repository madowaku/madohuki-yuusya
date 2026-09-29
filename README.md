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
