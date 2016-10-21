require 'net/http'

class UrlAnalyzer

  attr_accessor :bad_urls, :good_urls

  GREEN = ['100', '101', '102', '200', '201', '202', '203', '204', '205', '206',
           '207', '226', '300', '301', '302', '303', '304', '305', '306', '307' ]

  RED = [ '400', '401', '402', '403', '404', '405', '406' '406', '407', '408',
          '409', '410', '411', '412', '413', '414', '415', '416', '417', '422',
          '423', '424', '425', '426', '428', '429', '431', '434', '444', '449',
          '451', '500', '501', '502', '503', '504', '505', '506', '507', '508',
          '509', '510', '511', 'DSL_ERROR' ]

  def initialize(urls)
    @bad_urls = Array.new
    @good_urls = Array.new
    urls.split.each do |u|
      @bad_urls << u if bad_url?(u)
      @good_urls << u if good_url?(u)
    end
  end

  def start_monitoring
    threads = []
    threads << Thread.new do
      loop do
        monitor_bad_urls
        puts 'bad urls checked'
        sleep 30
      end
    end
    threads << Thread.new do
      loop do
        monitor_good_urls
        puts 'good urls checked'
        sleep 60
      end
    end
    threads.each(&:join)
  end


  private

  def check_url(url)
    Net::HTTP.get_response(URI(url)).code
  rescue SocketError, Errno::ECONNREFUSED
    return 'DSL_ERROR'
  end

  def monitor_bad_urls
    changed_state = select_good_urls(bad_urls)
    unless changed_state.empty?
      good_urls << changed_state
      puts 'These urls became fine:', changed_state.join(',')
    end
  end

  def monitor_good_urls
    changed_state = select_bad_urls(good_urls)
    unless changed_state.empty?
      bad_urls << changed_state
      puts 'These urls felt down:', changed_state.join(',')
    end
  end

  def select_bad_urls(urls)
    urls.select { |u| RED.include?(check_url(u)) }
  end

  def select_good_urls(urls)
    urls.select { |u| GREEN.include?(check_url(u)) }
  end

  def bad_url?(url)
    RED.include?(check_url(url))
  end

  def good_url?(url)
    GREEN.include?(check_url(url))
  end

end
puts "введети ссылки через пробел: "
text = gets.chomp
UrlAnalyzer.new("#{text}").start_monitoring
