require "heroku/command/base"

class Heroku::Command::Pg < Heroku::Command::Base

  # pg:transfer
  #
  # transfer data between databases
  #
  # -f, --from DATABASE  # source database, defaults to DATABASE_URL on the app
  # -t, --to   DATABASE  # target database, defaults to local $DATABASE_URL
  #
  def transfer
    from = options[:from] || "DATABASE"
    to   = options[:to]   || ENV["DATABASE_URL"] || env["DATABASE_URL"]

    error <<-ERROR unless to
No local DATABASE_URL detected and --to not specified.
For information on using config vars locally, see:
https://devcenter.heroku.com/articles/config-vars#local_setup
    ERROR

    from_url = transfer_resolve(from)
    to_url   = transfer_resolve(to)

    error "You cannot transfer a database to itself" if from_url == to_url

    validate_transfer_db from_url
    validate_transfer_db to_url

    puts "Source database: #{transfer_pretty_name(from)}"
    puts "Target database: #{transfer_pretty_name(to)}"

    return unless confirm_command

    system %{ #{pg_dump_command(from_url)} | #{pg_restore_command(to_url)} }
  end

private

  def env
    @env ||= begin
      File.read(".env").split("\n").inject({}) do |hash, line|
        if line =~ /\A([A-Za-z_0-9]+)=(.*)\z/
          key, val = [$1, $2]
          case val
            when /\A'(.*)'\z/ then hash[key] = $1
            when /\A"(.*)"\z/ then hash[key] = $1.gsub(/\\(.)/, '\1')
            else hash[key] = val
          end
        end
        hash
      end
    end
  end

  def pg_dump_command(url)
    uri = URI.parse(url)
    database = uri.path[1..-1]
    host = uri.host || "localhost"
    port = uri.port || "5432"
    user = uri.user ? "-U #{uri.user}" : ""
    %{ env PGPASSWORD=#{uri.password} pg_dump --verbose -F c -h #{host} #{user} -p #{port} #{database} }
  end

  def pg_restore_command(url)
    uri = URI.parse(url)
    database = uri.path[1..-1]
    host = uri.host || "localhost"
    port = uri.port || "5432"
    user = uri.user ? "-U #{uri.user}" : ""
    %{ env PGPASSWORD=#{uri.password} pg_restore --verbose --clean --no-acl -j 3 --no-owner #{user} -h #{host} -d #{database} -p #{port} }
  end

  def transfer_pretty_name(db_name)
    if (uri = URI.parse(db_name)).scheme
      "#{uri.path[1..-1]} on #{uri.host||"localhost"}:#{uri.port||5432}"
    else
      "#{hpg_resolve(db_name).first} on #{app}.herokuapp.com"
    end
  end

  def transfer_resolve(name_or_url)
    if URI.parse(name_or_url).scheme
      name_or_url
    else
      hpg_resolve(name_or_url).last
    end
  end

  def validate_transfer_db(url)
    unless %w( postgres postgresql ).include? URI.parse(url).scheme
      error <<-ERROR
Only PostgreSQL databases can be transferred with this command.
For information on transferring other database types, see:
https://devcenter.heroku.com/articles/import-data-heroku-postgres
      ERROR
    end
  end

end
