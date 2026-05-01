# Godot 節點與 AI 圖解

這份文件根據 `level-3-attack` 分支目前的場景與腳本整理，主題是「敵人的攻擊」。

目的不是比較語法，而是用三張圖幫助閱讀這個版本的程式。

---

## 1. Game Scene Tree + 責任標註圖

這張圖要表達的是：

- `game.tscn` 的父子節點關係
- 每個 node 的型別
- 每個 node 大致負責什麼工作
- `game.tscn` 中的敵人節點是 `enemy.tscn` 的實例
- 同一張圖中另外展示 `enemy.tscn` 自己的樹狀結構

PlantUML 檔案： [scene_tree_responsibility.puml](diagrams/scene_tree_responsibility.puml)

---

## 2. 互動關係圖

這張圖要表達的是：

- 敵人怎麼讀取玩家位置來追蹤與攻擊
- 玩家被攻擊後，血量怎麼傳到 `GameManager`
- `GameManager` 怎麼更新 HUD
- 巡邏與追蹤時，平台邊緣和牆面怎麼影響敵人轉向

PlantUML 檔案： [interaction_relationships.puml](diagrams/interaction_relationships.puml)

---

## 3. 敵人 AI 狀態圖

這張圖要表達的是：

- 敵人的行為狀態
- 狀態之間怎麼切換
- 哪些條件會觸發追蹤與攻擊

PlantUML 檔案： [enemy_ai_states.puml](diagrams/enemy_ai_states.puml)

---

## 4. 目前保留的圖

目前文件保留這三張 PlantUML 圖：

| 圖名 | 用途 |
| --- | --- |
| `scene_tree_responsibility.puml` | 同一張圖中同時呈現 `game.tscn` 的 scene tree、node 型別與責任，以及 `enemy.tscn` 的模板結構 |
| `interaction_relationships.puml` | 玩家、敵人、GameManager、HUD 與環境之間的互動關係 |
| `enemy_ai_states.puml` | 敵人從巡邏、追蹤到攻擊的狀態切換 |

## 5. 使用建議

- 後面若要繼續擴充圖，直接維護 `.puml` 檔，不要再把圖內容複製回 Markdown。
- 如果要給學生看，建議把 `.puml` 轉成 `svg` 再插入講義。

---

## 6. 閱讀順序

閱讀這份程式時，可以先不要一開始就逐行看 script。

比較順的方式是：

1. 先用結構圖建立地圖
2. 再用互動圖理解攻擊事件怎麼流動
3. 最後用狀態圖閱讀敵人的行為切換

這樣會先知道「場上有誰、誰管什麼、資料怎麼流、敵人什麼時候會攻擊」，再進入程式細節。

### 第一步：先看 Scene Tree + Responsibility 圖

先看 [scene_tree_responsibility.puml](diagrams/scene_tree_responsibility.puml)。

先回答下面幾個問題：

- 場上有哪些 node？
- 玩家、敵人、平台、UI 分別是哪個 node？
- 為什麼同一個 `enemy.tscn` 可以變成巡邏、追蹤、攻擊三種行為？
- `HealthHUD` 為什麼放在 `GameManager` 下面？

可以順便對照到程式檔案：

- `Player` 對應 [player.gd](scripts/player.gd:1)
- `Enemy` 對應 [enemy.gd](scripts/enemy.gd:1)
- `GameManager` 對應 [game_manager.gd](scripts/game_manager.gd:1)

先知道「這份 script 是哪個 node 的行為」就夠了，不需要立刻看完每一行。

### 第二步：再看 Interaction Relationships 圖

接著看 [interaction_relationships.puml](diagrams/interaction_relationships.puml)。

這張圖可以用來理解：

- 敵人先讀取玩家位置，再決定要追蹤還是攻擊
- 攻擊發生時，敵人會呼叫 `Player.take_damage()`
- 玩家扣血後會通知 `GameManager`
- `GameManager` 會把新的血量顯示在 HUD 上

可以分成三條線來看：

- 攻擊分支：`Enemy -> Player.take_damage -> GameManager.set_health -> HUD 更新`
- 邊緣轉向分支：`RayCast2D -> Enemy -> direction 反轉`
- 撞牆轉向分支：`Wall / TileMap -> Enemy -> direction 反轉`

可以直接對照程式：

- 追蹤與攻擊判定：[enemy.gd](scripts/enemy.gd:49)
- 攻擊玩家：[enemy.gd](scripts/enemy.gd:92)
- 玩家扣血：[player.gd](scripts/player.gd:67)
- 更新 HUD：[game_manager.gd](scripts/game_manager.gd:24)

這一段可以一直問自己同一個問題：

- 這一行是在做判斷、改資料，還是更新畫面？

### 第三步：最後看 Enemy AI State 圖

最後再看 [enemy_ai_states.puml](diagrams/enemy_ai_states.puml)。

這張圖可以拿來對照 `enemy.gd` 的 `_physics_process()`，因為這支程式的核心就是：

- 先維持基本巡邏
- 玩家進入範圍後改成追蹤
- 玩家靠近後停下並攻擊
- 攻擊結束後繼續檢查是否仍在攻擊距離內

可以照狀態來讀：

- `Patrol`：正常巡邏，前方沒地板或撞牆就轉向
- `Chase`：玩家進入偵測範圍後，改成朝玩家方向移動
- `Attack`：玩家進入攻擊距離後停下並呼叫 `_try_attack()`

可以對照的程式位置：

- 巡邏與 RayCast 偵測：[enemy.gd](scripts/enemy.gd:35)
- 追蹤玩家：[enemy.gd](scripts/enemy.gd:49)
- 攻擊玩家：[enemy.gd](scripts/enemy.gd:60)
- 攻擊冷卻：[enemy.gd](scripts/enemy.gd:92)

狀態圖不是額外的圖，而是 `enemy.gd` 的閱讀索引。

## 7. 可以先想的問題

閱讀時可以先想下面這幾個問題：

1. 哪些敵人只會巡邏，哪些敵人會追蹤，哪些敵人會攻擊？
2. 敵人怎麼知道玩家進入偵測範圍？
3. 敵人怎麼判定「已經靠近到可以攻擊」？
4. 玩家被攻擊後，血量是在哪裡改變的？
5. HUD 的血量圖示為什麼會跟著變化？

這幾個問題會把注意力放在：

- 結構
- 責任
- 資料流
- 狀態切換

而不是一開始就卡在語法細節。

## 8. 這三張圖各自幫助什麼

這三張圖分別對應三種閱讀方式：

- `scene tree` 圖：看責任分工
- `interaction` 圖：看攻擊事件與資料怎麼流動
- `state` 圖：看敵人什麼時候巡邏、追蹤、攻擊

先有這三層理解，再回頭讀 `if`、變數、函式，通常會更容易吸收。
