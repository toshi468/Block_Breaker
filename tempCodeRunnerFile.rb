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

  def create_blocks
    