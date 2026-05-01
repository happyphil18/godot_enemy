# Godot 2D 物理教學講稿

這份講稿以 [`scripts/enemy.gd`](./scripts/enemy.gd) 為例，整理 Godot 2D 遊戲中最常見的物理概念：`CharacterBody2D`、`velocity`、`gravity`、`delta`、`move_and_slide()`，以及 `RayCast2D` 在巡邏 AI 裡的作用。

## 教學主題

今天要講的是：Godot 2D 遊戲裡，角色或敵人是怎麼「動起來」的。

很多初學者看到角色會走、會掉下去、會撞牆轉向，會以為 Godot 幫我們全部算好了。其實不是。

在 `CharacterBody2D` 裡，Godot 不會自動幫我們產生速度，我們必須自己算出 `velocity`，再交給 `move_and_slide()` 去做移動和碰撞處理。

## 一、先建立核心觀念

在 2D 物理裡，最重要的三個概念是：

1. `position`：角色目前在哪裡。
2. `velocity`：角色目前正往哪個方向、用多快的速度移動。
3. `delta`：這一幀經過了多少時間。

可以先記一句最基本的運動公式：

```text
位移 = 速度 × 時間
```

換成遊戲程式語言就是：

```text
displacement = velocity * delta
```

也就是說，如果速度是每秒 40 像素，而這一幀只過了 `1/60` 秒，那這一幀就只會移動大約：

```text
40 * 1/60 ≈ 0.67 像素
```

這就是為什麼遊戲裡移動不是一次跳很遠，而是每一幀累積一點點位移。

## 二、`velocity` 是什麼

在 `CharacterBody2D` 裡，`velocity` 是一個 `Vector2`，也就是二維向量：

```gdscript
velocity.x
velocity.y
```

- `velocity.x` 控制左右移動
- `velocity.y` 控制上下移動

例如：

```gdscript
velocity.x = -40
```

表示角色每秒往左移動 40 像素。

如果：

```gdscript
velocity.y = 100
```

表示角色每秒往下移動 100 像素。因為 Godot 2D 的座標系裡，`y` 往下是正的。

## 三、重力是怎麼來的

看這段程式：

```gdscript
if not is_on_floor():
    velocity.y += gravity * delta
```

這段的意思是：

如果角色現在不在地板上，就把重力加到垂直速度上。

這裡不是直接改位置，而是先改「速度」。因為真實世界裡，自由落體不是每一幀固定掉一樣多，而是越掉越快。

所以重力公式在遊戲中常寫成：

```text
新垂直速度 = 舊垂直速度 + 重力 × 時間
```

也就是：

```gdscript
velocity.y += gravity * delta
```

這樣角色就會出現「加速下落」的效果。

## 四、為什麼一定要乘 `delta`

如果不乘 `delta`，每台電腦每秒跑的幀數不同，角色速度就會不一致。

- 60 FPS 的電腦，一秒加 60 次
- 120 FPS 的電腦，一秒加 120 次

這樣同一段程式，在不同裝置上結果會不同。所以我們要乘上 `delta`，讓運動依照「時間」而不是依照「幀數」來計算。

你可以把 `delta` 想成：「這一幀只是整整 1 秒裡面的一小片時間。」

## 五、`move_and_slide()` 在做什麼

`move_and_slide()` 是 `CharacterBody2D` 裡最重要的移動函式之一。

它的工作不是幫你決定速度，而是：

1. 根據目前的 `velocity` 嘗試移動角色。
2. 如果碰到牆、地板、斜坡，幫你做碰撞修正。
3. 讓角色沿著表面滑動，而不是硬穿過去。
4. 必要時修正 `velocity`。

所以流程是：

```gdscript
先算 velocity
再呼叫 move_and_slide()
```

不是反過來。

## 六、怎麼理解它算下個位置

在沒有碰撞時，可以先把它理解成：

```text
下個位置 = 目前位置 + velocity * delta
```

例如：

```gdscript
velocity = Vector2(-40, 0)
```

如果 `delta = 1/60`，那這一幀的位移就是：

```text
(-40, 0) * 1/60 = (-0.67, 0)
```

也就是往左移 0.67 像素。

但真正在 `move_and_slide()` 裡，如果途中撞到牆，它不會照原路走完。它會把撞到牆的那部分速度消掉，改成沿著表面滑動。

所以更精確地說，`move_and_slide()` 算的不是單一公式，而是：

1. 先拿 `velocity * delta` 當成本幀想走的位移。
2. 嘗試移動。
3. 如果碰撞，就修正移動方向。
4. 再用修正後的方向繼續走剩下的距離。

這就是為什麼它叫 `move_and_slide`，不是單純 `move`。

## 七、用敵人巡邏範例來看

在 [`scripts/enemy.gd`](./scripts/enemy.gd) 裡，水平移動的核心是：

```gdscript
velocity.x = direction * speed
```

假設：

```gdscript
direction = -1
speed = 40
```

那就會得到：

```gdscript
velocity.x = -40
```

表示敵人每秒向左走 40 像素。

如果同時角色在空中，垂直方向又會受到重力影響：

```gdscript
velocity.y += gravity * delta
```

所以這個敵人在某一幀的完整速度，可能是：

```text
velocity = (-40, 16.3)
```

意思是：

- 水平往左
- 垂直往下

然後丟進：

```gdscript
move_and_slide()
```

Godot 就會根據這個速度幫它移動，並處理碰撞。

## 八、RayCast2D 跟物理的關係

你的敵人不只靠碰撞移動，還有用 `RayCast2D` 來「預判前方有沒有地板」：

```gdscript
floor_ray.target_position = Vector2(10 * direction, 12)
floor_ray.force_raycast_update()
```

這裡不是移動角色，而是在做偵測。

它的用途是：

1. 往前下方打出一條射線。
2. 看下一步前面還有沒有平台。
3. 如果沒地板，就轉身。

所以這套敵人行為其實分成兩部分：

1. `velocity + move_and_slide()`：負責真的移動。
2. `RayCast2D`：負責提早判斷要不要轉向。

這是很常見的巡邏 AI 寫法。

## 九、碰撞後為什麼 `velocity` 會變

初學者常以為 `velocity` 是自己設定多少就永遠不變，其實不是。

例如角色往下掉：

```gdscript
velocity.y += gravity * delta
```

如果沒有碰到地板，`velocity.y` 會越來越大。但一旦 `move_and_slide()` 判定已經落地，垂直方向就不應該繼續往下穿透，所以它會修正速度，讓角色停在地面上。

也就是說：

- `velocity` 是你「希望」角色怎麼動。
- `move_and_slide()` 會根據碰撞，把它修正成「實際可行的移動結果」。

## 十、這份程式的完整物理流程

可以把每一幀想成下面這個順序：

1. 先判斷角色是否在地板上。
2. 如果不在地板上，就套用重力。
3. 設定 ray 偵測前下方地板。
4. 如果前面沒地板，就先轉身。
5. 根據 `direction * speed` 設定水平速度。
6. 呼叫 `move_and_slide()` 做真正移動。
7. 如果撞牆，再轉身一次。

這就是巡邏敵人的物理更新流程。

## 十一、上課時可以強調的重點句

你可以直接講這幾句：

- `CharacterBody2D` 不會自己幫你產生速度，速度要自己算。
- `velocity` 是速度，不是位置。
- `delta` 是時間差，讓移動跟幀率無關。
- 重力不是直接改位置，而是先改垂直速度。
- `move_and_slide()` 會根據 `velocity` 來移動，並自動處理滑動碰撞。
- `RayCast2D` 不是拿來移動角色，而是拿來偵測前方環境。

## 十二、總結

總結來說，Godot 2D 角色移動的核心不是「直接改座標」，而是：

1. 先算出速度 `velocity`。
2. 再讓 `move_and_slide()` 根據速度與碰撞去更新位置。

所以你看到敵人會巡邏、會掉落、會撞牆轉身，本質上都是同一套物理邏輯在運作。
