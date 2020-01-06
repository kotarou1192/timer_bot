# frozen_string_literal: true

require 'discordrb'

TOKEN = 'token'

@bot = Discordrb::Commands::CommandBot.new(
  token: TOKEN,
  client_id: id,
  prefix: 'timer!'
)

@bot.command :help do |event|
  message = <<-HELP
  バージョンアップにて複数サーバーに対応しました。
  指定の曜日・時間に1度だけ全員宛にメンションをつけて発言するタイマーBotです。
  コマンド一覧です

  ```timer!set label week hour minute```
  例:`timer!set お絵描き 水 23 8`
  水曜日の23時8分にタイマー名"お絵描き"をセットします。
  weekは月火水木金土日のいずれか、
  hourは0～23、timeは0～59で入力してください。
  ```timer!list```
  現在設定されているタイマー一覧を表示します。
  :の後がタイマー名です。
  ```timer!delete label```
  例:`timer!delete お絵描き`
  タイマー名を指定して削除します。

  HELP

  event.send_message(message)
end

@timer_list = {}

@bot.command :list do |event|
  if @timer_list[event.server.id].nil? || @timer_list[event.server.id].any? do |_channel, timers|
       timers.nil? || timers.empty?
     end
    event.send_message('タイマーは設定されていません')
    break
  end

  @timer_list[event.server.id].each do |_channel, timers|
    timers.each do |label, date|
      week, hour, minute = date
      week_list = %w[日 月 火 水 木 金 土]
      event.send_message("#{week_list[week]}曜日#{hour}時#{minute}分 : #{label}")
    end
  end
  nil
end

@bot.command :delete do |event, label|
  bot_server = event.server.id
  if @timer_list[bot_server].nil?
    event.send_message("そのようなタイマー:#{label} はありません")
    break
  end

  if @timer_list[bot_server].any? do |_channel, timers|
       timers.any? do |text, _date|
         timers.delete(label) if text == label
       end
     end
    event.send_message("タイマー：#{label}　を削除しました")
  else
    event.send_message("そのようなタイマー:#{label} はありません")
  end
end

@bot.command :set do |event, label, week, hour, minute|
  # if @timer_list[event.server.id].each_value.size >= 7
  #  event.send_message('タイマーは同時に最大7つまでしか設定できません。どれか消してください。')
  #  break
  # end

  if week !~ /月|火|水|木|金|土|日/
    event.send_message('曜日は「月、火、水、木、金、土、日」のいずれかで入力してください')
    break
  end

  if !@timer_list[event.server.id].nil? && @timer_list[event.server.id].any? do |_channel, timers|
       timers.key?(label)
     end
    event.send_message('そのタイマー名は既に登録されています')
    break
  end

  if hour !~ /\A[0-9]+\z/ || hour.to_i.negative? || hour.to_i >= 24
    event.send_message('時間(24H)は0～23で入力してください。詳しくはtimer!helpコマンドをどうぞ')
    break
  end

  if minute !~ /\A[0-9]+\z/ || minute.to_i.negative? || minute.to_i >= 60
    event.send_message('分は0～59で入力してください。詳しくはtimer!helpコマンドをどうぞ')
    break
  end

  week_list = %w[日 月 火 水 木 金 土]
  week = week_list.find_index(week) # 曜日を数字に変換

  bot_server = event.server.id
  bot_channel = event.channel.id
  @timer_list[bot_server] = {} if @timer_list[bot_server].nil?
  @timer_list[bot_server][bot_channel] = {} if @timer_list[bot_server][bot_channel].nil?
  @timer_list[bot_server][bot_channel][label] = [week, hour.to_i, minute.to_i]
  event.send_message("#{week_list[week]}曜日#{hour}時#{minute}分にタイマーをセットしました。
    停止する場合はtimer!delete タイマー名 と入力してください
    タイマー名はtimer!listで確認できます。")
nil
end

def its_time?
  @timer_list.each do |server, timers|
    t = Time.now.getutc.getlocal('+09:00')
    timers.each do |channel, timer|
      timer.each do |label, date|
        week, hour, minute = date

        if hour == t.hour && minute == t.min && week.to_s == t.strftime('%w')
          @bot.send_message(channel, '@here ' + label.to_s)
          @timer_list[server][channel].delete(label)
        end
      end
    end
  end
end

Thread.new do
  loop do
    sleep(10)
    its_time?
  end
end
@bot.run
