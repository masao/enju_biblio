require 'active_record/fixtures'
desc "create initial records for enju_biblio"
namespace :enju_biblio do
  task :setup => :environment do
    Dir.glob(Rails.root.to_s + '/db/fixtures/enju_biblio/*.yml').each do |file|
      ActiveRecord::Fixtures.create_fixtures('db/fixtures/enju_biblio', File.basename(file, '.*'))
    end
  end
end
