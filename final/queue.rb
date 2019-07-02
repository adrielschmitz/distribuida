require 'yaml'

module Server
  class Queue
    attr_reader :id, :queue
    def initialize(id)
      @id = id
      initialize_queue
    end

    def initialize_queue
      @queue = YAML.load(File.read("temp/router_#{@id}.yml"))
    rescue Errno::ENOENT
      Dir.mkdir('temp/') unless File.exist?('temp/')
      File.open("temp/router_#{@id}.yml", 'w') { |file| file.write([].to_yaml) }
      retry
    end

    def add(pack)
      @queue << pack
      update_arq
    end

    def pop
      @queue.shift
      update_arq
    end

    def update_arq
      File.open("temp/router_#{@id}.yml", 'w') { |file| file.write(@queue.to_yaml) }
    rescue Errno::ENOENT
      Dir.mkdir('temp/') unless File.exist?('temp/')
      retry
    end

    def print
      puts '#------------------------ Queue ------------------------#'
      @queue.each do |element|
        puts "=> #{element[:message]}"
      end
      puts '#-------------------------------------------------------#'
    end

    def empty?
      @queue.empty?
    end

    def first
      @queue.first
    end
  end
end
