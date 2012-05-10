module Fluent
  class UDPInput < Fluent::Input
    Plugin.register_input('udp', self)
    include DetachMultiProcessMixin
    require 'socket'
    require 'json'
    def initialize
      super
    end

    config_param :port, :integer, :default => 8765
    config_param :bind, :string, :default => '0.0.0.0'

  
    def configure(conf)
      super
    end

    def start
     
      @udp_s = UDPSocket.new
   
 
      detach_multi_process do
        super
           @udp_s.bind(@bind, @port)
           $log.debug "listening UDP on #{@bind}:#{@port}"
        @thread = Thread.new(&method(:run))
      end
    end

    def shutdown
      @udp_s.close
      @thread.join
    end

    def run
       loop do
         text, sender =  @udp_s.recvfrom(1024)
         begin
         j_obj = JSON.parse(text)
         rescue
          $log.debug "Parse error : #{text} \n #{$!.to_s}" 
         j_obj = {}
         end
         time = j_obj['t']
         time = time.to_i
         if time == 0
           time = Engine.now
         end
         
         tag = j_obj['tag'] || "unknown"
         
         Engine.emit(tag, time, j_obj)
       end
    rescue
      $log.error "unexpected error", :error=>$!.to_s
      $log.error_backtrace
    end
  end
end
