require 'eventmachine'
require 'json'
require "net/http"
require "uri"

$stdout.sync = true

kraken_uri = URI.parse("https://api.kraken.com/0/public/Depth?pair=etheur")

STORAGE_INTERVAL = 10
VOLUME_LIMIT = 100

def store timestamp, buys, sells
  open('data/kraken.etheur.book.data', 'a') do |f|
    buys = buys.map { |buy|
      "%0.8f-%0.8f" % [buy[0], buy[1]]
    }.join "|"
    sells = sells.map { |sell|
      "%0.8f-%0.8f" % [sell[0], sell[1]]
    }.join "|"

    f.puts "#{timestamp}:#{buys}:#{sells}"
  end
end

EM.run do
  sleep(Time.now.to_i % STORAGE_INTERVAL)
  EventMachine.add_periodic_timer(STORAGE_INTERVAL) do
    EM.defer do
      timestamp = Time.now.to_i
      response = JSON.parse(Net::HTTP.get_response(kraken_uri).body)
      book = response.dig('result','XETHZEUR')

      volume = 0
      buys = []
      book['bids'].each do |buy_order|
        volume += buy_order[1].to_f
        buys.push [buy_order[0], buy_order[1]]
        if volume > VOLUME_LIMIT
          break
        end
      end

      volume = 0
      sells = []
      book['asks'].each do |sell_order|
        volume += sell_order[1].to_f
        sells.push [sell_order[0], sell_order[1]]
        if volume > VOLUME_LIMIT
          break
        end
      end

      store timestamp, buys, sells
    end
  end
end
