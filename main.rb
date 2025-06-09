require 'gosu' 

#====Blockクラス===========================================

class Block
  attr_reader :x, :y, :width, :height, :colors, :color_index # ゲッター(外からも参照できるように)

  def initialize(x, y, width = 60, height = 20, color_index = 0)
    @x = x
    @y = y
    @width = width
    @height = height
    @color_index = color_index
    @colors = [Gosu::Color::RED, Gosu::Color::YELLOW, Gosu::Color::GREEN, Gosu::Color::CYAN, Gosu::Color::BLUE]
  end
  
  def draw
    Gosu.draw_rect(@x, @y, @width, @height, @colors[@color_index - 1])
  end
end
#====Blockクラス===========================================

#====================Itemクラス==================================
class Item
attr_reader :x, :y, :type

  def initialize(x, y, type = :item_2x)
    @x = x
    @y = y
    @type = type
    @image = case type
      when :item_2x
        Gosu::Image.new("image/item_2x.png")
      when :item_fire
        Gosu::Image.new("image/item_fire.png")
      end
    @fall_speed = 3
  end

  def update
    @y += @fall_speed
  end

  def draw
    @image.draw(@x, @y, 1, 1.2, 1.2)
  end
end

#====================Itemクラス==================================

#====Barクラス===========================================

class Bar
  attr_reader :bar_x, :bar_y, :width, :height # ゲッター(外からも参照できるように)
  
  def initialize
    @bar = Gosu::Image.new("image/bar.png")
    @width = 80
    @height = 20
    reset_position
    @moving = false  # まだ動かない
  end

  def reset_if_ball_fallen(ball)
    if ball.y > 479
      reset_position
    end
  end

  def reset_position
    @bar_x = 280  # 初期位置
    @bar_y = 450
    @moving = false  # まだ動かない
  end

  def start
    return if @moving  # すでに動いていたら何もしない
    @moving = true
  end

  def move_left
    if @moving == true
      @bar_x -= 5
      @bar_x = 0 if @bar_x < 0
    end
  end

  def move_right
    if @moving == true
      @bar_x += 5
      @bar_x = 640 - @width if @bar_x > 640 - @width
    end
  end

  def draw
    @bar.draw(@bar_x, @bar_y, 0)
  end
end
#====Barクラス===========================================


#====Ballクラス===========================================
class Ball
  attr_accessor :vx, :vy
  attr_reader :x, :y, :radius, :vx, :vy, :moving #ゲッター(外からも参照できるように)
  
  def initialize
    @radius = 10
    reset_position
    @ball = Gosu::Image.new("image/ball.png")
  end

  def reset_position
    @x = 312  # 画面中央
    @y = 436 #435
    @vx = 0
    @vy = 0
    @moving = false  # まだ動かない
  end

  def start
    return if @moving  # すでに動いていたら何もしない
    @vx = [-4, -3, -2, 2, 3, 4].sample  # ランダムに左 or 右
    @vy = -4  # 上に向かって発射
    @moving = true
  end

  def update(bar_x)
    return unless @moving  # Enterが押されるまで動かない

    @x += @vx
    @y += @vy
    
    # バーとの衝突判定
    if (450 - @y).abs <= 10 && (bar_x + 40 - @x).abs <= 40 && @y < 451
      @vy = -@vy  # 上に反射
    end
    # if (450 - @y).abs <= 10 && (bar_x + 40 - @x).abs == 40
    #   @vy += 2
    #   @vy = -@vy  # 上に反射
    # end

    # 画面の端で反射
    @vx = -@vx if @x - @radius <= 0 || @x + @radius >= 640
    @vy = -@vy if @y - @radius <= 0  # 上の壁で反射

    # 落ちたらゲームオーバー
    if @y > 480
      reset_position # 位置をリセット
    end
  end

  def draw
    @ball.draw(@x, @y, 0)
  end
end
#====Ballクラス===========================================


class BlockBreaker < Gosu::Window
  def initialize
    super(640, 480, false)
    self.caption = "Block Breaker"
    @font = Gosu::Font.new(32)  # サイズ32のフォントを作成
    @state = :title  # 初期状態はタイトル画面
    @stage_select_over = :false #ステージ選択画面のオーバーレイ
    @title_image = Gosu::Image.new("image/title.png")
    @ball = Ball.new #ボールのインスタンス
    @bar = Bar.new #バーのインスタンス
    @blocks = [] # ブロックの配列
    create_blocks #ブロックを作る関数
    @items = [] # アイテムの配列
    @block_broken = false #ブロックが壊れたかどうか

    #title画面の画像==============================
    @title_ball = Gosu::Image.new("image/ball.png")
    @title_ball_value = 0 # タイトル画面のボールの位置
    #title画面の画像==============================


    # ステージ選択画面の画像=================================
    @stage_select_blocks = [
      Gosu::Image.new("image/red_block.png"),
      Gosu::Image.new("image/yellow_block.png"),
      Gosu::Image.new("image/green_block.png"),
      Gosu::Image.new("image/purple_block.png")
    ]
    @selected_stage = 0

    @key_up_pressed = false  # 上キーが押されたかどうか
    @key_down_pressed = false  # 下キーが押されたかどうか
    @key_input_time = 0  # 最後にキー入力を受け付けた時刻
    @input_delay = 100  # 500ミリ秒（0.5秒）の待機時間
    # ステージ選択画面の画像=================================

    @enter_pressed = false # Enterキーが押されたかどうかのフラグ

    # ステージ選択に必要な変数
    @stages = ["ステージ1", "ステージ2", "ステージ3", "Extra Stage"]

  end

#===============blockを生成する関数==========================
  def create_blocks
    rows = 5
    cols = 10
    block_width = 80
    block_height = 20
    margin = 1
    offset_x = 0
    offset_y = 30
    color_index = 0

    rows.times do |row|
      cols.times do |col|
        x = offset_x + col * (block_width + margin)
        y = offset_y + row * (block_height + margin)
        @blocks << Block.new(x, y, block_width, block_height, color_index)
        color_index += 1
        if color_index > 5
          color_index = 0
        end
      end
    end
  end

  def draw_text(text, x, y, z, scale_x, scale_y, color)
    @font.draw_text(text, x, y, z, scale_x, scale_y, color)
  end
#===============blockを生成する関数==========================

#=======================アイテム取得判定=======================
  def check_item_get
    @items.delete_if do |item|
      item_left   = item.x
      item_right  = item.x + 32   # 画像サイズに合わせて調整
      item_top    = item.y
      item_bottom = item.y + 32

      bar_left   = @bar.bar_x
      bar_right  = @bar.bar_x + @bar.width
      bar_top    = @bar.bar_y
      bar_bottom = @bar.bar_y + @bar.height

      if item_right > bar_left && item_left < bar_right &&
        item_bottom > bar_top && item_top < bar_bottom
        # アイテム取得時の効果をここで発動
        true  # 取得したので削除
      else
        false
      end
    end
  end
#=======================アイテム取得判定=======================

#=======================ブロックが壊れたか=======================
  def broken_block# ボールとブロックの衝突判定
      @blocks.delete_if do |block|
        # ボールとブロックの矩形衝突判定
        ball_left   = @ball.x - @ball.radius
        ball_right  = @ball.x + @ball.radius
        ball_top    = @ball.y - @ball.radius
        ball_bottom = @ball.y + @ball.radius

        block_left   = block.x
        block_right  = block.x + block.width
        block_top    = block.y
        block_bottom = block.y + block.height

        if ball_right > block_left && ball_left < block_right &&
            ball_bottom > block_top && ball_top < block_bottom
          # 衝突したらボールの向きを反転
            @ball.vy = -@ball.vy
            if rand(0..10) < 3
              @items << Item.new(block.x, block.y, [:item_2x, :item_fire].sample) # アイテムを追加
            end
            true # このブロックを削除
        else
            false
        end
      end
  end
#=======================ブロックが壊れたか=======================



# ＝＝＝＝＝＝＝＝＝update＝＝＝＝＝＝＝＝＝＝＝＝＝

  def update

    case @state
    # タイトル画面
    when :title

      if button_down?(Gosu::KB_RETURN) && @title_ball_value == 0
        @state = :stage_select
        @enter_pressed = true # Enterキーが押された
        @enter_pressed = false
      end

      if button_down? Gosu::KB_UP
        @title_ball_value = 0 # ボールの位置を変更
  
      elsif button_down? Gosu::KB_DOWN
        @title_ball_value = 1 # ボールの位置を変更
      end

    # ステージ選択画面
    when :stage_select
      #-1 % 3 = 2になる。
      #↑なぜか。 理屈は難しいけど、簡単に考える方法がある。
      #それは、-1 % 3 = 2 だと、3になるまでに2足りない(マイナス無視)
      #なので、-3 % 3 = 0, -2 % 3 = 1

      current_time = Gosu.milliseconds

      # 上キーが押され、入力待機時間が経過した場合
      if button_down?(Gosu::KB_UP) && !@key_up_pressed && current_time - @key_input_time >= @input_delay
        @selected_stage = (@selected_stage - 1) % @stages.size
        @key_up_pressed = true  # 上キーが押されたことを記録
        @key_input_time = current_time  # 最後に入力を受け付けた時刻を更新
      # 下キーが押され、入力待機時間が経過した場合
      elsif button_down?(Gosu::KB_DOWN) && !@key_down_pressed && current_time - @key_input_time >= @input_delay
        @selected_stage = (@selected_stage + 1) % @stages.size
        @key_down_pressed = true  # 下キーが押されたことを記録
        @key_input_time = current_time  # 最後に入力を受け付けた時刻を更新
      end

      # キーが離れたらフラグをリセット
      if !button_down?(Gosu::KB_UP) && @key_up_pressed
        @key_up_pressed = false
      elsif !button_down?(Gosu::KB_DOWN) && @key_down_pressed
        @key_down_pressed = false
      end

      if button_down?(Gosu::KB_SPACE) && @selected_stage == 0
        @state = :playing_stage1 # ステージ選択後、ゲーム開始
      end

      if button_down?(Gosu::KB_SPACE) && @selected_stage == 1
        @state = :playing_stage2 # ステージ選択後、ゲーム開始
      end

      if button_down?(Gosu::KB_SPACE) && @selected_stage == 2
        @state = :playing_stage3 # ステージ選択後、ゲーム開始
      end

      if button_down?(Gosu::KB_SPACE) && @selected_stage == 3
        @state = :playing_extrastage # ステージ選択後、ゲーム開始
      end

    when :playing_stage1
      @ball.update(@bar.bar_x) # バーの位置を渡す 
      if button_down? Gosu::KB_RETURN
        @ball.start
        @bar.start
      end

      if button_down?(Gosu::KB_LEFT)
        @bar.move_left
      elsif button_down?(Gosu::KB_RIGHT)
        @bar.move_right
      end

      @bar.reset_if_ball_fallen(@ball)
      broken_block # ボールとブロックの衝突判定
      check_item_get # アイテム取得判定
      @items.delete_if { |item| item.y > 480 }# アイテムが画面外に出たら削除
      @items.each(&:update)# アイテムの位置を更新

    when :playing_stage2
      @ball.update(@bar.bar_x) # バーの位置を渡す 
      if button_down? Gosu::KB_RETURN
        @ball.start
        @bar.start
      end

      if button_down?(Gosu::KB_LEFT)
        @bar.move_left
      elsif button_down?(Gosu::KB_RIGHT)
        @bar.move_right
      end

    when :playing_stage3
      @ball.update(@bar.bar_x) # バーの位置を渡す 
      if button_down? Gosu::KB_RETURN
        @ball.start
        @bar.start
      end

      if button_down?(Gosu::KB_LEFT)
        @bar.move_left
      elsif button_down?(Gosu::KB_RIGHT)
        @bar.move_right
      end

    when :playing_extrastage
      @ball.update(@bar.bar_x) # バーの位置を渡す 
      if button_down? Gosu::KB_RETURN
        @ball.start
        @bar.start
      end

      if button_down?(Gosu::KB_LEFT)
        @bar.move_left
      elsif button_down?(Gosu::KB_RIGHT)
        @bar.move_right
      end

    end
  end

# ＝＝＝＝＝＝＝＝＝update＝＝＝＝＝＝＝＝＝＝＝＝＝



# ＝＝＝＝＝＝＝＝＝draw＝＝＝＝＝＝＝＝＝＝＝＝＝
# draw(テキスト内容, x座標, y座標, z座標, xスケール(拡大率), yスケール(拡大率), 色)

  def draw
    case @state

    # タイトル画面
    when :title
      @title_image.draw(0, 0, 0)
      draw_text("Press Enter to Start", 130, 390, 1, 1.5, 1.5, Gosu::Color::WHITE)
      if @title_ball_value == 0
        @title_ball.draw(230, 290, 0)
      elsif @title_ball_value == 1
        @title_ball.draw(230, 349, 0)        
      end

    # ステージ選択画面
    when :stage_select
      draw_text("Choose to Stage", 240, 20, 1, 1.5, 1.5, Gosu::Color::WHITE)
      draw_text("Press Space to Game Start ", 200, 420, 1, 1.2, 1.2, Gosu::Color::WHITE)
      @stages.each_with_index do |stage, i|
        if i == 3
          draw_text(stage, 26, 360, 1, 0.9, 0.9, Gosu::Color::WHITE)
        else
          draw_text(stage, 80, 50 + i * 100, 1, 1.5, 1.5, Gosu::Color::WHITE)
        end
      end
      @stage_select_blocks[@selected_stage].draw(15, 55 + @selected_stage * 100, 0 , 0.2,0.2)
    # ゲームプレイ画面
      
    
      when :playing_stage1
        @bar.draw
        @ball.draw
        @blocks.each(&:draw)
        @items.each(&:draw)
        draw_text("Bar control: ← →  |  Ball start: Enter", 140, 390, 1, 0.8, 0.8, Gosu::Color::WHITE)

      when :playing_stage2
        @bar.draw
        @ball.draw
        @blocks.each(&:draw)
        @items.each(&:draw)
        draw_text("Bar control: ← →  |  Ball start: Enter", 140, 390, 1, 0.8, 0.8, Gosu::Color::WHITE)

      when :playing_stage3
        @bar.draw
        @ball.draw
        @blocks.each(&:draw)
        @items.each(&:draw)
        draw_text("Bar control: ← →  |  Ball start: Enter", 140, 390, 1, 0.8, 0.8, Gosu::Color::WHITE)

      when :playing_extrastage
        @bar.draw
        @ball.draw
        @blocks.each(&:draw)
        @items.each(&:draw)
        draw_text("Bar control: ← →  |  Ball start: Enter", 140, 390, 1, 0.8, 0.8, Gosu::Color::WHITE)

    # draw_rect(0, 450, 48, 450, Gosu::Color::WHITE)
    # draw_line(320, 0, Gosu::Color::WHITE, 320, 480, Gosu::Color::WHITE)
    end
  end
end
# ＝＝＝＝＝＝＝＝＝draw＝＝＝＝＝＝＝＝＝＝＝＝＝


game = BlockBreaker.new
game.show