# Asset Production v0.1 — 窓ふき勇者

2026-09-29 / TASK-001〜007。既成素材を骨格に、生成素材を作品の顔にする。ゲームの進行は既存の5窓スライスを維持する。

## 受け入れ基準

- 透過PNG、指定命名、参照画像との一貫性。
- 720×1280、360×800で帽子・色・道具・ポーズが読める。
- 単体、Kenney素材との組み合わせ、Godot内の実寸でレビューする。
- 清掃の見た目と判定が一致し、最後の5.5%の自動仕上げを維持する。
- 警告・実行時エラーを残さず、マウス／タッチで5窓を完走する。

## 成果物

21点の生成原画（採用マスターの参照コピーを除く）。全点のPNGデコード・alpha・透明領域を検査済み。

| Task | 成果物 | 用途 |
| --- | --- | --- |
| 001 | `hero_master_v01.png` | 採用し `assets/reference/hero_master.png` にコピー |
| 002 | `style_reference_v01.png` / `color_palette_reference_v01.png` | 絵柄と冷暖対比の基準 |
| 003 | `item_legendary_ladder_v01.png` | 太陽と雲の翼を持つ、終盤用の伝説のハシゴ |
| 004 | `hero_{idle,walk,carry_ladder,place_ladder,climb,wipe}_v01.png` | 全6ポーズをゲームの状態・配置イベントへ接続 |
| 005 | `npc_goblin_merchant_{neutral,surprised,happy}_v01.png` | 商人窓で通常→驚き→笑顔と手振り |
| 006 | `dirt_{soot,mud,streak,bird,magic}_v01.png` | 全5枚の窓に1種ずつ割り当て、消去マスクへ接続 |
| 007 | `window_heart_concept_v01.png` / `window_heart_clean_hint_v01.png` | 黒い窓と暖かな室内の比較コンセプト |

保存先：Heroは `assets/generated/raw/hero/`、NPCは `raw/npc/`、伝説のハシゴは `raw/items/`、汚れとHeart Windowは `raw/windows/`。絵柄・配色見本は `assets/reference/`。原画は上書き加工せず保持し、将来の加工版用に `assets/generated/processed/` を用意した。

生成は組み込みの `image_gen` を使用。モデルのバージョンはツールから返されないため、Images 2.5であることは確認できない。CLI/APIへの切り替えはしていない。全プロンプトと参照画像は [production_prompts.json](../assets/generated/production_prompts.json) に保存。

## 絵柄

- 外は青灰色、内は蜂蜜色とクリーム色。正確な色値は `assets/reference/palette.json`。生成された色見本のピクセル値は厳密な色指定として使わない。
- 勇者は金色の柔らかい帽子、青緑の短いマント、茶色の靴、大きなスクイージー。武器・鎧なし。
- 商人は大きな耳、丸眼鏡、帳簿。敵に見せない。
- 勇者は100px高、商人は112px高。360px幅では約50px／56px。
- 縮小時の輪郭のざらつきを、ミップマップと線形補間で修正して再レビュー済み。
- Heart Windowと伝説のハシゴは終盤用コンセプト。本編の進行へ先に追加しない。

## 既成素材

[Kenney Platformer Pack Medieval](https://kenney.nl/assets/platformer-pack-medieval) と [UI Pack Adventure](https://kenney.nl/assets/ui-pack-adventure) を採用。配布ページと同梱ライセンスでCC0・商用利用可を確認。ZIP原本は `C:\Dev\AssetsShared\Kenney\archives`、展開済み原本も共有フォルダへ保存。

城壁・遠景の窓・バルコニー梁・フック金具の下地はMedieval atlas、窓枠・基本ボタンはUI Adventureを使用。Godotで領域指定、色調整、9-sliceを行う。空、屋根、植生、室内小物、普通のハシゴ、フックの操作記号は既存のプロジェクト描画と合成する。

`assets/third_party/` に採用分のみ配置。追加2パックの原文ライセンスは `assets/licenses/` に保存し、CREDITSと書き出しZIPにも含める。今回はitch.io素材の追加はない。

## 実装

- `CharacterArt`：ポーズ選択、透過領域からの足元揃え、左右反転。ゲーム状態を変更しない。
- `DirtArt`：原画をメモリ上で66×80へ縮小し、薄い汚れの膜と合成。未清掃セルに約38%以上の不透明度を確保し、透明な穴に清掃判定だけが残る問題を防ぐ。
- 消去する2×2ピクセルは33×40の論理マスクに対応。動的な汚れには古いミップレベルを残さない。
- `EnvironmentArt`：既成素材の領域・9-sliceを分離。
- 原画はフル解像度を保持。Godotインポートだけを最大512pxへ制限。基準画像・コンセプト・レビューシーンはWeb本体から除外。

## レビューと検証

`scenes/review/asset_review.tscn` をGodotで開きF6。クリック／タップで3ページを切り替える。

1. 6ポーズと3表情をKenney城壁・窓枠の中に実寸表示。
2. 汚れ5種、Heart Window前後、伝説のハシゴ。
3. 絵柄と配色の参照画像。

Godot撮影結果は `output/art-review/godot-page-{1,2,3}.png`。レビューシーンの実行引数に `-- --capture-art` を渡すと再撮影できる。Web版のゲーム画面は `output/playwright/`。撮影出力はGit対象外。

- `tests/test_art.gd`：97項目。全20PNGの透過、汚れと論理セルの一致、古いミップレベルの排除、6ポーズの切り替え。
- `tests/test_stage.gd`：35項目。ハシゴ、進行、最後の汚れ補助、戻り道、リスタート。
- `tests/test_ui_runtime.gd`：480項目。2サイズ×日英、タイトル・操作・一時停止・クレジット、音と時間停止。
- Webの通し操作は `tools/playtest-browser.js`。タッチ360×800とマウス720×1280で検証。

## 限界と次の段階

6枚の状態ポーズであり、連続歩行のフレームアニメーションではない。Heart Windowは比較用の完成絵で、清掃用の分割レイヤーではない。細部は小画面で省略されるが、帽子・色・姿勢で識別する。

実機スマートフォンのGPU・音声と、初見プレイヤーの理解・愛着・再挑戦意欲は人による確認が残る。PHASE C（008 NPC量産、009装飾UI、010宣伝キービジュアル）は、初見理解と手触りを確かめて絵柄を固めてから進める。
