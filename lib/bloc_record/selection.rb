require 'sqlite3'

module Selection
	def find(*ids)
		if ids.length == 1
			find_one(ids.first)
		else
			rows = connection.execute <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				WHERE id IN (#{ids.join(",")});
			SQL
			rows_to_array(rows)
		end
	end

	def find_one(id)
		row = connection.get_first_row <<-SQL 
			SELECT #{columns.join ","} FROM #{table}
			WHERE id = #{id};
		SQL

		init_object_from_row(row)
	end

	def find_by(attribute, value)
		row = connection.get_first_row <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
		SQL

		init_object_from_row(row)
	end

	def take_one
		row = connection.get_first_row <<-SQL 
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY random()
			LIMIT 1;
		SQL

		init_object_from_row(row)
	end

	def take(num=1)
		if num > 1
			rows = connection.execute <<-SQL 
				SELECT #{columns.join ","} FROM #{table}
				ORDER BY random() 
				LIMIT #{num};
			SQL

			rows_to_array(rows)
		else
			take_one
		end
	end

	def first 
		row = connection.get_first_row <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY id
			ASC LIMIT 1;
		SQL

		init_object_from_row(row)
	end

	def last 
		row = connection.get_first_row <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY id
			DESC LIMIT 1;
		SQL

		init_object_from_row(row)
	end

	def all
		rows = connection.execute <<-SQL
			SELECT #{columns.join ","} FROM #{table};
		SQL

		rows_to_array(rows)
	end

	def where(*args)
		if args.count > 1
			expression = args.shift
			params = args
		else
			case args.first
			when String 
				expression = args.first 
			when Hash 
				expression_hash = BlocRecord::Utility.convert_keys(args.first)
				expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
			end
		end

		sql = <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{expression};
		SQL

		rows = connection.execute(sql, params)
		rows_to_array(rows)
	end

	def order(*args)
		if args.count > 1
		  order = []
		  args.map! { |x| 
		    if x.class == Hash
		      x.map { |k,v| 
		        x = "#{k} #{v}"
		      }
		    end
		    order << x
		  }
		  order = orders.join(', ')		  
		else
		  if args[0].class == Hash
  		  order_hash = convert_keys(args[0])
  		  order = order_hash.map { |key, value| "#{key} #{sql_strings(value)}"}.join(", ")
		  else
		    order = args.first.join(", ")
		  end
		end

		rows = connection.execute <<-SQL
			SELECT * FROM #{table}
			ORDER BY #{order};
		SQL
		rows_to_array(rows)
	end

	def join(*args)
		if args.count > 1
			joins = args.map {|arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
			rows = connection.execute <<-SQL
				SELECT * FROM #{table} #{joins}
			SQL
		else
			case arg.first
		      when String
		        rows = connection.execute <<-SQL
		          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(arg)};
		        SQL
		      when Symbol
		        rows = connection.execute <<-SQL
		          SELECT * FROM #{table}
		          INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id
		        SQL
		      when Hash
		        expression_hash = BlocRecord::Utility.convert_keys(args.first)
		        expression = expression_hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(",")
		        rows = connection.execute <<-SQL
		          SELECT * FROM #{table}
		          INNER JOIN #{expression[0]} ON #{expression[0]}.#{table}_id = #{table}.id
		          INNER JOIN #{expression[1]} ON #{expression[1]}.#{expression[0]}_id = #{table}.id
		        SQL
		      end
		    end
		end
		rows_to_array(rows)
	end

	private 

	def init_object_from_row(row)
		if row
			data = Hash[columns.zip(row)]
			new(data)
		end
	end

	def rows_to_array(rows)
		rows.map { |row| new(Hash[columns.zip(row)])}
	end
end