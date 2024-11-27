module SacExports
  class ClusterContext
    Credentials = Data.define(:username, :password)

    attr_reader :namespace, :host, :env

    def initialize(env)
      @env = env
      @host = "postgres05.cloud.puzzle.ch"
      @namespace = "hit-sac-cas-#{env}"
    end

    def with_database
      original = ActiveRecord::Base.remove_connection
      ActiveRecord::Base.establish_connection(dbconfig)
      yield
    ensure
      ActiveRecord::Base.establish_connection(original)
    end

    def credentials
      @credentials ||= Credentials.new(**JSON.parse(`oc get --namespace #{namespace} secret pg-database-credentials -o json | jq '.data'`))
    end

    def dbconfig
      @dbconfig ||= ActiveRecord::Base.configurations.find_db_config(:development).configuration_hash.merge(
        host: host,
        database: namespace,
        username: Base64.decode64(credentials.username),
        password: Base64.decode64(credentials.password),
        schema_search_path: :database
      )
    end
  end
end
