class ActiveRecord::SchemaDumper
  def table(table, stream)
    columns = @connection.columns(table)
    begin
      tbl = StringIO.new

      # first dump primary key column
      if @connection.respond_to?(:pk_and_sequence_for)
        pk, _ = @connection.pk_and_sequence_for(table)
      elsif @connection.respond_to?(:primary_key)
        pk = @connection.primary_key(table)
      end

      multitenant = (pk == 'multitenant_id')

      tbl.print "  create_table #{remove_prefix_and_suffix(table).inspect}"
      pkcol = columns.detect { |c| c.name == pk }
      if pkcol
        unless multitenant
          tbl.print %Q(, multitenant: false)
        end

        if pk != 'id' && pk != 'multitenant_id'
          tbl.print %Q(, primary_key: "#{pk}")
        elsif pkcol.sql_type == 'uuid'
          tbl.print ", id: :uuid"
          tbl.print %Q(, default: "#{pkcol.default_function}") if pkcol.default_function
        else
        end
      else
        tbl.print ", id: false"
      end
      tbl.print ", force: true"
      tbl.puts " do |t|"

      # then dump all non-primary key columns
      column_specs = columns.map do |column|
        raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" unless @connection.valid_type?(column.type)
        next if column.name == pk
        @connection.column_spec(column, @types)
      end.compact

      # find all migration keys used in this table
      keys = @connection.migration_keys

      # figure out the lengths for each column based on above keys
      lengths = keys.map { |key|
        column_specs.map { |spec|
          spec[key] ? spec[key].length + 2 : 0
        }.max
      }

      # the string we're going to sprintf our values against, with standardized column widths
      format_string = lengths.map{ |len| "%-#{len}s" }

      # find the max length for the 'type' column, which is special
      type_length = column_specs.map{ |column| column[:type].length }.max

      # add column type definition to our format string
      format_string.unshift "    t.%-#{type_length}s "

      format_string *= ''

      column_specs.each do |colspec|
        next if multitenant && colspec[:name].in?(['"id"', '"tenant"'])

        values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
        values.unshift colspec[:type]
        tbl.print((format_string % values).gsub(/,\s*$/, ''))
        tbl.puts
      end

      tbl.puts "  end"
      tbl.puts

      indexes(table, tbl)

      tbl.rewind
      stream.print tbl.read
    rescue => e
      stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
      stream.puts "#   #{e.message}"
      stream.puts
    end

    stream
  end

  def indexes(table, stream)
    indexes = @connection.indexes(table)
                         .reject{ |index| index.columns.in?([['id'], ['tenant'] ,['id', 'tenant']]) }

    if indexes.any?
      add_index_statements = indexes.map do |index|
        statement_parts = [
          "add_index #{remove_prefix_and_suffix(index.table).inspect}",
          index.columns.inspect,
          "name: #{index.name.inspect}",
        ]
        statement_parts << 'unique: true' if index.unique

        index_lengths = (index.lengths || []).compact
        statement_parts << "length: #{Hash[index.columns.zip(index.lengths)].inspect}" if index_lengths.any?

        index_orders = index.orders || {}
        statement_parts << "order: #{index.orders.inspect}" if index_orders.any?
        statement_parts << "where: #{index.where.inspect}" if index.where
        statement_parts << "using: #{index.using.inspect}" if index.using
        statement_parts << "type: #{index.type.inspect}" if index.type

        "  #{statement_parts.join(', ')}"
      end

      stream.puts add_index_statements.sort.join("\n")
      stream.puts
    end
  end
end