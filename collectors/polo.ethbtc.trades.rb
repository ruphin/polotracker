require 'faye/websocket'
require 'eventmachine'
require 'json'

$stdout.sync = true

trades = Hash.new {|h, k| h[k] = []}

STORAGE_INTERVAL = 10

def store values
  open('data/polo.ethbtc.trades.data', 'a') do |f|
    values.each do |value|
      f.puts "#{value[0]}:#{value[1]}:%0.8f" % value[2]
    end
  end
end

EM.run do
  ws = Faye::WebSocket::Client.new("wss://api2.poloniex.com")

  ws.on :open do |event|
    p [:open]
    ws.send('{"command":"subscribe","channel":"BTC_ETH"}')
  end

  ws.on :message do |event|

    tx = JSON.parse(event.data)
    if (tx[0] == 148) # ETHBTC channel
      tx[2].each do |event|
        if (event[0] == "t") # Trade event
          amount = event[3].to_f * event[4].to_f
          timestamp = event[5]
          trades[timestamp - (timestamp % STORAGE_INTERVAL)].push([timestamp, event[2], amount])
        end
      end
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    p "ERROR: POLONIEX WEBSOCKET FAILED"
    ws = nil
    exit 1
    # TODO: Recover
  end

  EventMachine.add_periodic_timer(10) do
    flushLimit = Time.now.to_i - ((Time.now.to_i % STORAGE_INTERVAL) - (STORAGE_INTERVAL * 2))

    trades.each do |time, values|
      if time < flushLimit
        store values
        trades.delete time
      end
    end
  end
end
