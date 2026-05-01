# Godot 節點與 AI 圖解

這份文件根據目前專案的場景與腳本整理，統一使用 `PlantUML` 來描述結構與關係。

---

## 1. Game Scene Tree + 責任標註圖

這張圖要表達的是：

- `game.tscn` 的父子節點關係
- 每個 node 的型別
- 每個 node 大致負責什麼工作
- `game.tscn` 中的敵人節點是 `enemy.tscn` 的實例
- 同一張圖中另外展示 `enemy.tscn` 自己的樹狀結構

PlantUML 檔案： [scene_tree_responsibility.puml](/Users/tywang/project/godot/enemy/diagrams/scene_tree_responsibility.puml)

---

## 2. 互動關係圖

這張圖要表達的是：

- 誰會呼叫誰
- 誰會影響誰
- 誰負責更新資料或畫面

PlantUML 檔案： [interaction_relationships.puml](/Users/tywang/project/godot/enemy/diagrams/interaction_relationships.puml)

---

## 3. 敵人 AI 狀態圖

這張圖要表達的是：

- 敵人的行為狀態
- 狀態之間怎麼切換
- 哪些條件會觸發追蹤、攻擊、被打敗與重生

PlantUML 檔案： [enemy_ai_states.puml](/Users/tywang/project/godot/enemy/diagrams/enemy_ai_states.puml)

---

## 4. 目前保留的圖

目前文件只保留這三張 PlantUML 圖：

| 圖名 | 用途 |
| --- | --- |
| `scene_tree_responsibility.puml` | 同一張圖中同時呈現 `game.tscn` 的 scene tree、node 型別與責任，以及 `enemy.tscn` 的模板結構 |
| `interaction_relationships.puml` | 玩家、敵人、GameManager、HUD 的互動關係 |
| `enemy_ai_states.puml` | 敵人巡邏、追蹤、攻擊、被打敗、重生的狀態切換 |


---

## 6. 程式閱讀順序

1. 先用結構圖建立地圖
2. 再用互動圖理解事件怎麼流動
3. 最後用狀態圖閱讀敵人 AI 的判斷邏輯

這樣學生會先知道「場上有誰、誰管什麼、事件怎麼傳」，再進入程式細節，比較不容易迷路。

### 第一步：先看 Scene Tree + Responsibility 圖

先看 [scene_tree_responsibility.puml](/Users/tywang/project/godot/enemy/diagrams/scene_tree_responsibility.puml)。

這一步的目標不是讀懂所有程式，而是先回答：

- 場上有哪些 node？
- 玩家、敵人、UI 分別是哪個 node？
- 哪些 node 是 `game.tscn` 的一部分？
- 為什麼 `enemy.tscn` 可以被實例化成很多敵人？

這張圖建立兩個基本觀念：

- scene tree 是「場景結構圖」
- 每個 node 都有自己的責任

可以順便對照到程式檔案：

- `Player` 對應 [player.gd](/Users/tywang/project/godot/enemy/scripts/player.gd:1)
- `Enemy` 對應 [enemy.gd](/Users/tywang/project/godot/enemy/scripts/enemy.gd:1)
- `GameManager` 對應 [game_manager.gd](/Users/tywang/project/godot/enemy/scripts/game_manager.gd:1)

### 第二步：再看 Interaction Relationships 圖

接著看 [interaction_relationships.puml](/Users/tywang/project/godot/enemy/diagrams/interaction_relationships.puml)。

這張圖理解：

- 誰會呼叫誰
- 血量變化後，為什麼 UI 也會跟著改
- 玩家、敵人、GameManager 不是寫在同一個檔案裡，卻仍然能互相合作

分成兩條分支：

- 攻擊分支：`Enemy -> Player.take_damage -> GameManager.set_health -> HUD 更新`
- 踩踏分支：`Enemy 判定被踩 -> Player.heal -> GameManager.heal -> HUD 更新`

找對應程式：

- 敵人攻擊玩家：[enemy.gd](/Users/tywang/project/godot/enemy/scripts/enemy.gd:113)
- 玩家受傷後更新血量：[player.gd](/Users/tywang/project/godot/enemy/scripts/player.gd:67)
- 玩家回血後通知管理者：[player.gd](/Users/tywang/project/godot/enemy/scripts/player.gd:77)
- `GameManager` 更新 HUD：[game_manager.gd](/Users/tywang/project/godot/enemy/scripts/game_manager.gd:24)

資料與畫面分開：

- `Player.health` 是資料
- `GameManager.current_health` 是管理中的狀態
- HUD 圖示是畫面呈現

### 第三步：最後看 Enemy AI State 圖

最後再看 [enemy_ai_states.puml](/Users/tywang/project/godot/enemy/diagrams/enemy_ai_states.puml)。

讀 `enemy.gd` 的 `_physics_process()`，因為這支程式本質上就是：

- 先檢查目前情況
- 再決定敵人要進入哪種行為

不建議從上到下逐行念，而是照狀態來讀：

- `Patrol`：敵人平常巡邏，前面沒地板就轉向
- `Chase`：玩家進入偵測範圍後開始追
- `Attack`：玩家靠近後停下並攻擊
- `Defeated`：被玩家從上方踩中後失效
- `Respawn`：倒數結束後回到出生位置

可以對照的程式位置：

- 巡邏與地板偵測：[enemy.gd](/Users/tywang/project/godot/enemy/scripts/enemy.gd:58)
- 追蹤玩家：[enemy.gd](/Users/tywang/project/godot/enemy/scripts/enemy.gd:68)
- 攻擊玩家：[enemy.gd](/Users/tywang/project/godot/enemy/scripts/enemy.gd:79)
- 被踩與重生：[enemy.gd](/Users/tywang/project/godot/enemy/scripts/enemy.gd:122)

這樣學生比較容易理解：狀態圖不是額外的圖，而是 `enemy.gd` 的閱讀索引。

## 7. 問題順序
用下面這個順序：

1. 場上有哪些 node？每個 node 負責什麼？
2. 玩家受傷時，誰先改資料？誰後更新畫面？
3. 玩家踩到敵人時，為什麼會回血？
4. 敵人什麼時候巡邏、追蹤、攻擊？
5. 為什麼敵人不會一直往前走掉下平台？

這組提問的目的，注意力放在：

- 結構
- 責任
- 資料流
- 狀態切換

