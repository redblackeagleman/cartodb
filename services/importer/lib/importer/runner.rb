# encoding: utf-8
require_relative './loader'
require_relative './shp_loader'
require_relative './indexer'

module CartoDB
  module Importer2
    class Runner
      LOADERS = {
        csv:  Loader,
        txt:  Loader,
        xls:  Loader,
        shp:  ShpLoader
      }

      def initialize(job, downloader, georeferencer=nil, indexer=nil)
        self.job          = job
        self.downloader   = downloader
        self.indexer      = indexer
      end #initialize

      def run
        job.log "Starting import with job ID: #{job.id}"
        job.log "Getting file from #{downloader.url}"
        downloader.run
        job.log "Importing data from #{downloader.source_file.fullpath}"
        loader.run
        job.log "Loader exit code: #{loader.exit_code}"
        indexer.add(job.table_name)
        self
      end #run
      
      def report
        job.logger.to_s
      end #report

      def results
        [
          { 
            name:       downloader.source_file.name,
            table_name: job.table_name
          } 
        ]
      end #results

      def exit_code
        loader.exit_code
      end #exit_code

      private

      attr_accessor :job, :downloader, :georeferencer
      attr_writer   :loader, :indexer

      def indexer
        @indexer ||= Indexer.new(job.db)
      end #indexer

      def loader
        return @loader if @loader
        loader_klass = LOADERS.fetch(source_file.extension.delete('.').to_sym)
        @loader ||= loader_klass.new(job, source_file)
      end #loader

      def source_file
        downloader.source_file
      end #source_file
    end # Runner
  end # Importer2
end # CartoDB
