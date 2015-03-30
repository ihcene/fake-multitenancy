ActiveRecord::Base.instance_eval do
  concerning :Multitenacy do
    included do
      before_create do
        if self.class.multitenant?
          self.tenant = Tenant.current.name
          self.id     = (self.class.where(tenant: tenant).maximum(:id) || 0) + 1
        end
      end
    end

    def save
      if self.class.multitenant? && !persisted?
        3.times do
          begin
            super
            break

          rescue ActiveRecord::RecordNotUnique
          end
        end

      else
        super

      end
    end

    module ClassMethods
      def primary_key
        multitenant? ? "id" : super
      end

      def multitenant?
        columns.map(&:name).include?("tenant")
      end
    end
  end
end