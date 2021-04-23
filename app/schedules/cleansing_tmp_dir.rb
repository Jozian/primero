module CleansingTmpDir

  CLEANUP_TIME = 10.minutes

  class << self

    def dir_name
      File.join Rails.root, 'tmp', 'cleanup'
    end

    def dir
      FileUtils.mkdir_p dir_name
      dir_name
    end

    def temp_file_name
      File.join dir, SecureRandom.uuid
    end

    def schedule(scheduler)
      scheduler.every('30m') do
        Rails.logger.info 'Cleaning up temporary encrypted files...'
        cleanup!
      rescue => e
        Rails.logger.error 'Error cleaning up temporary encrypted files'
        e.backtrace.each { |line| Rails.logger.error line }
      end
    end

    def cleanup!
      Dir.glob(File.join(dir, '*')) do |zip_file|
        if File.mtime(zip_file) < CLEANUP_TIME.ago
          Rails.logger.error "Deleting file: #{File.basename(zip_file)}"
          File.delete zip_file
        end
      end
    end
  end
end
