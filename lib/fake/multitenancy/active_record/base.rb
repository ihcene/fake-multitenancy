class ActiveRecord::Base
  def self.inherited(klass)
    super
    return if klass.name.eql?('SchemaMigration')

    klass.class_eval do
      default_scope do
        if multitenant?
          where(tenant: Tenant.current.name)
        else
          scoped
        end
      end
    end
  end
end