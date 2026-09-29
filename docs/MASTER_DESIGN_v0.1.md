# 窓ふき勇者 MASTER DESIGN v0.1

## One Line

**汚れた魔王城を、戦わず、ハシゴで登り、窓を磨いて攻略するローグライト。**

勇者の武器は剣ではなく、ハシゴ、スクイージー、洗剤、窓ふきの知恵。

## Game Pillars

### CLIMB
ハシゴをどこへ掛け、どの順で登るかが小さなパズルになる。

### CLEAN
1枚磨くだけでも気持ちいい。最後の汚れが落ちる瞬間の「キュッ！」を最優先する。

### DISCOVER
汚れた窓は Fog of War。磨くと部屋、住人、アイテム、仕掛けが現れる。

### OPTIMIZE
クリア自体はやさしく、美しく回ると深い。掛け替え回数、移動距離、時間、清掃率を詰められる。

### HEAL
敵を倒さない。魔王さえ最後は「心の窓」を綺麗にする。

## Genre

**Ladder Puzzle Roguelite**

ハシゴ配置パズル + 探索 + 軽ローグライト + 清掃の気持ちよさ。

## Ideal Run

20-30分。城門、下層、居住区、塔、魔法区画、魔王の間などを進む。

各エリアの基本ループ:

1. ハシゴを運ぶ
2. 設置する
3. 登る
4. 窓を磨く
5. 中身を発見する
6. 次のルートを組み直す
7. 報酬を選ぶ

## Ladder System

ハシゴがビルドの中心。

主要パラメータ:

- LENGTH
- WEIGHT
- ANCHOR
- SHAPE
- RETRIEVE
- SPECIAL

代表候補:

- WOODEN LADDER
- LONG LADDER
- LIGHT LADDER
- HOOK LADDER
- FOLDING LADDER
- DOUBLE LADDER
- TELESCOPIC LADDER
- BRIDGE LADDER
- SLIME LADDER
- MAGNET LADDER
- CLOUD LADDER
- GROWING LADDER
- LEGENDARY LADDER

製品版では30種程度まで拡張可能。

## Window System

すべての窓は最初 DIRTY。

磨くことで種類が判明する。

- NORMAL WINDOW
- CHARACTER WINDOW
- ITEM WINDOW
- MECHANISM WINDOW
- CURSED WINDOW
- SECRET WINDOW

重要: 窓を拭くことが「探索」と「報酬開封」を兼ねる。

## Cleaning Build

- DOUBLE WIPE
- HOLY SQUEEGEE
- BUBBLE SOAP
- RAIN REPELLENT
- HOT WATER
- MAGIC CLOTH
- SOAP BOMB

連続清掃で CLEAN COMBO。

## Enemy Philosophy

HPを削る敵は原則出さない。

敵は「掃除を邪魔する存在」。

例:

- DIRTY CROW: 清掃済み窓を再汚染
- FOG GHOST: 周囲を曇らせる
- FIRE IMP: 焦げ汚れ
- WINDOW WIZARD: 窓位置を交換
- RAIN CLOUD: 一定時間再汚染
- DRAGON: 横列を焦がす

すべて掃除の文法で解決する。

## Residents

悪の城にも普通の生活がある。

窓を磨くと、王女、ゴブリン商人、猫、骸骨、魔女、清掃員、ハシゴ職人、吟遊詩人などが現れる。

住人は小さな物語 + ラン内効果を持つ。

## Castle Progression

製品版候補:

1. DEMON CASTLE
2. SKY CASTLE
3. ICE CASTLE
4. MACHINE CASTLE
5. UNDERWATER CASTLE

完全ランダム生成ではなく、手作りルーム群をSeedで組み合わせる。

## Difficulty Philosophy

- CLEAR: 誰でも進める
- GOOD ROUTE: 少し考える
- PERFECT ROUTE: パズル好き向け

失敗は GAME OVER より評価低下を中心にする。

## Results

- WINDOWS
- LADDER MOVES
- CLIMB DISTANCE
- TIME
- CLEAN ROUTE
- DISCOVERY
- KINDNESS

## Demon King Finale

最上階の巨大な黒い窓。

何度磨いても汚れが落ちず、最後に

`TYPE: HEART WINDOW`

と判明する。

これまで助けた住人や城の記憶が映り、最後の一拭きで朝日が差す。

魔王:

> 「……外って、こんなに明るかったか。」

## Legendary Ladder Ending

城の外、岩に刺さった伝説のハシゴ。

「真の勇者のみ、この梯子を抜くことができる。」

勇者が抜くと、ハシゴが城、雲、月、星を越えて伸び続ける。

> NEXT JOB: THE WINDOWS OF HEAVEN

## Tone

- 70% コミカル
- 20% 気持ちいい
- 10% 少し心に残る

## Visual

縦長2D。巨大な城と小さな勇者。

汚れが落ちてガラス越しの世界が現れる変化を最重要視する。

## Audio

窓ふき音が主役。

- ザラザラ
- キュッキュッ
- 最後の「キュッ！」
- PERFECTの小さなチリン

## Product Vision

- Steam: 980-1,480円候補
- 初回: 3-5時間
- 全解禁: 10-20時間
- Godot 4.7
- Web / Android / PCへ展開可能

## Soul

**剣なら壊す。  
ハシゴなら届く。  
スクイージーなら、見えるようになる。**

世界を倒して変えるゲームではなく、綺麗にして見え方を変えるゲーム。
