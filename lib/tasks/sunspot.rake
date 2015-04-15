require 'sunspot/rails/tasks'

module Sunspot
  module Rails
    class Server
      # Use the same PID file for different rails envs
      # Because now, in the same Solr, we can have multiple cores (one each for every rails env)
      def pid_file
        'sunspot.pid'
      end
    end
  end
end

namespace :sunspot do
  desc "wait for solr to be started"
  task :wait, [:timeout] => :environment do |t, args|
    require 'rsolr'

    connected = false
    seconds = args[:timeout] ? args[:timeout].to_i : 30
    puts "Waiting #{seconds} seconds for Solr to start..."

    timeout(seconds) do
      until connected do
        begin
          connected = RSolr.connect(:url => Sunspot.config.solr.url).get "admin/ping"
        rescue => e
          sleep 1
        end
      end
    end

    raise "Solr is not responding" unless connected
  end

  Rake::Task["sunspot:reindex"].clear
  desc "re-index case/incident records"
  task :reindex => :wait do

    puts 'Reindexing Solr...'
    puts 'Reindexing cases...'

    Child.all.all.each do |child|
      child.index!

      if child.flags
        puts "  => Indexing #{child.id} Flags..."
        Sunspot.index(child.flags)
      end
    end

    puts 'Reindexing incidents...'
    Incident.all.all.each do |incident|
      incident.index!

      if incident.flags
        puts "  => Indexing #{incident.id} Flags..."
        Sunspot.index(incident.flags)
      end

      incident.index_violations
    end

    puts 'Reindexing Tracing Request...'
    TracingRequest.all.all.each do |tracing|
      tracing.index!

      if tracing.flags
        puts "  => Indexing #{tracing.id} Flags..."
        Sunspot.index(tracing.flags)
      end
    end
  end
end
