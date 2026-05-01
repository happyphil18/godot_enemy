# Godot 節點與 AI 圖解

這份文件根據 `main` 分支目前的場景與腳本整理，主題是「巡邏的敵人」。

目的不是比較語法，而是用三張圖幫助閱讀這個版本的程式。

---

## 1. Game Scene Tree + 責任標註圖

這張圖要表達的是：

- `game.tscn` 的父子節點關係
- 每個 node 的型別
- 每個 node 大致負責什麼工作
- `game.tscn` 中的巡邏敵人節點是 `enemy.tscn` 的實例
- 同一張圖中另外展示 `enemy.tscn` 自己的樹狀結構

PlantUML 檔案： [scene_tree_responsibility.puml](diagrams/scene_tree_responsibility.puml)

---

## 2. 互動關係圖

這張圖要表達的是：

- 巡邏敵人會依賴誰來做判斷
- 平台邊緣與牆面如何影響敵人的轉向
- 敵人改變方向後，怎麼更新朝向顯示

PlantUML 檔案： [interaction_relationships.puml](diagrams/interaction_relationships.puml)

---

## 3. 敵人 Patrol 邏輯圖

這張圖要表達的是：

- 巡邏敵人在每一幀會做哪些檢查
- 什麼情況下會因為平台邊緣轉向
- 什麼情況下會因為撞牆轉向
- 移動與轉向的先後順序

PlantUML 檔案： [enemy_patrol_flow.puml](diagrams/enemy_patrol_flow.puml)

---

## 4. 目前保留的圖

目前文件保留這三張 PlantUML 圖：

| 圖名 | 用途 |
| --- | --- |
| `scene_tree_responsibility.puml` | 同一張圖中同時呈現 `game.tscn` 的 scene tree、node 型別與責任，以及 `enemy.tscn` 的模板結構 |
| `interaction_relationships.puml` | 巡邏敵人、RayCast2D、平台牆面、玩家之間的基本互動關係 |
| `enemy_patrol_flow.puml` | 敵人在巡邏模式下每一幀的邏輯流程 |

## 5. 使用建議

- 後面若要繼續擴充圖，直接維護 `.puml` 檔，不要再把圖內容複製回 Markdown。
- 如果要給學生看，建議把 `.puml` 轉成 `svg` 再插入講義。

---

## 6. 閱讀順序

閱讀這份程式時，可以先不要一開始就逐行看 script。

比較順的方式是：

1. 先用結構圖建立地圖
2. 再用互動圖理解巡邏敵人會讀哪些資訊
3. 最後用 Patrol 邏輯圖閱讀 `_physics_process()` 的順序

這樣會先知道「場上有誰、誰管什麼、敵人依賴哪些節點與環境」，再進入程式細節。

### 第一步：先看 Scene Tree + Responsibility 圖

先看 [scene_tree_responsibility.puml](diagrams/scene_tree_responsibility.puml)。

先回答下面幾個問題：

- 場上有哪些 node？
- 玩家、巡邏敵人、平台、UI 分別是哪個 node？
- 為什麼同一個 `enemy.tscn` 可以被放成多個不同速度的敵人？
- `RayCast2D` 為什麼放在 `enemy.tscn` 裡面，而不是放在主場景？

可以順便對照到程式檔案：

- `Player` 對應 [player.gd](scripts/player.gd:1)
- `Enemy` 對應 [enemy.gd](scripts/enemy.gd:1)
- `GameManager` 對應 [game_manager.gd](scripts/game_manager.gd:1)

先知道「這份 script 是哪個 node 的行為」就夠了，不需要立刻看完每一行。

### 第二步：再看 Interaction Relationships 圖

接著看 [interaction_relationships.puml](diagrams/interaction_relationships.puml)。

這張圖可以用來理解：

- 巡邏敵人不是憑空轉向，而是根據 `RayCast2D` 和牆面碰撞結果做判斷
- 敵人方向改變後，不只速度會改，顯示朝向也要一起改
- 重點是「環境如何影響敵人」

可以分成三條線來看：

- 邊緣偵測分支：`RayCast2D -> Enemy -> direction 反轉 -> Sprite 朝向更新`
- 撞牆分支：`Wall / TileMap -> Enemy -> direction 反轉 -> Sprite 朝向更新`
- 玩家移動分支：`Player -> World`，讓學生知道玩家目前只和平台產生基本移動關係

可以直接帶學生找對應程式：

- RayCast 偵測與邊緣轉向：[enemy.gd](scripts/enemy.gd:22)
- 巡邏移動本體：[enemy.gd](scripts/enemy.gd:32)
- 撞牆轉向：[enemy.gd](scripts/enemy.gd:37)
- 玩家基本移動：[player.gd](scripts/player.gd:12)

這一段可以一直問自己同一個問題：

- 這個判斷是來自角色自己，還是來自環境回饋？

### 第三步：最後看 Enemy Patrol 邏輯圖

最後再看 [enemy_patrol_flow.puml](diagrams/enemy_patrol_flow.puml)。

這張圖可以拿來對照 `enemy.gd` 的 `_physics_process()`，因為這支程式的核心就是：

- 先讓敵人符合物理世界
- 再檢查前方地板
- 然後決定本幀移動方向
- 最後在撞牆時補做一次轉向

不一定要從上到下逐行念，也可以照流程來讀：

- 重力：敵人不在地板上時要往下掉
- RayCast：敵人要先知道自己前面還有沒有地板
- 邊緣轉向：如果快掉下去就先回頭
- 巡邏移動：維持 `direction * speed`
- 撞牆轉向：碰到牆壁再回頭

可以對照的程式位置：

- `_ready()` 初始化朝向：[enemy.gd](scripts/enemy.gd:12)
- 重力與 RayCast 更新：[enemy.gd](scripts/enemy.gd:17)
- 巡邏移動與撞牆轉向：[enemy.gd](scripts/enemy.gd:32)

流程圖不是額外的圖，而是 `_physics_process()` 的閱讀索引。

## 7. 可以先想的問題

閱讀時可以先想下面這幾個問題：

1. 場上有哪些 node？每個 node 負責什麼？
2. 同一個 `enemy.tscn` 為什麼可以變成多隻巡邏敵人？
3. 敵人怎麼知道自己前面還有沒有地板？
4. 敵人為什麼不會一直往前走掉下平台？
5. 除了平台邊緣之外，還有什麼情況會讓敵人轉向？

這幾個問題會把注意力放在：

- 結構
- 責任
- 環境回饋
- 流程順序

而不是一開始就卡在語法細節。

## 8. 這三張圖各自幫助什麼

這三張圖分別對應三種閱讀方式：

- `scene tree` 圖：看責任分工
- `interaction` 圖：看環境與敵人怎麼互相影響
- `flow` 圖：看 `_physics_process()` 的檢查順序與轉向邏輯

先有這三層理解，再回頭讀 `if`、變數、函式，通常會更容易吸收。
