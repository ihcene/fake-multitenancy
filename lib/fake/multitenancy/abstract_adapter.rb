class ActiveRecord::ConnectionAdapters::AbstractAdapter
  concerning :MultitenantSchemaStatements do
    def create_table(table_name, options = {}, &block)
      multitenant = options.fetch(:multitenant, true) && table_name != "schema_migrations"

      if multitenant
        super table_name, options.merge(primary_key: :multitenant_id) do |t|
          t.integer     :id, null: false, unique: true
          t.string      :tenant, null: false

          block.call(t) if block_given?
        end

        add_index(table_name, [:id, :tenant], unique: true)
        add_index(table_name, :id)
        add_index(table_name, :tenant)
      else
        super(table_name, options, &block)
      end
    end
  end
end