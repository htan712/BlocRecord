require 'sqlite3'
require 'bloc_record/schema'

module Persistence

	def self.included(base)
		base.extend(ClassMethods)
	end

	module ClassMethods
		def create(attrs)
			attrs = BlocRecord::Utility.convert_keys(attrs)
			attrs.delete "id"
			vals = attributes.map {|key| BlocRecord::Utility.sql_strings(attrs[key])}

			connection.execute <<-SQL 
				INSERT INTO #{table} (#{attributes.join ","})
				VALUES (#{vals.join ","})
			SQL

			data = Hash[attributes.zip attrs.values]
			data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
			new(data)
		end

		def save!
			unless self.id
				self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
				BlocRecord::Utility.reload_obj(self)
				return true 
			end

			fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

			self.class.connection.execute <<-SQL 
				UPDATE #{self.class.table}
				SET #{fields}
				WHERE id = #{self.id};
			SQL

			true
		end

		def save
			self.save! rescue false 
		end

		def update(ids, updates)
			updates = BlocRecord::Utility.convert_keys(updates)
			update.delete "id"
			updates_array = updates.map { |k, v| "#{k}=#{BlocRecord::Utility.sql_strings(v)}" }

			if ids.class == Fixnum
				where_clause = "WHERE id = #{ids};"
			elsif ids.class == Array
				where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
			else 
				where_clause = ";"
			end

			connection.execute <<-SQL
				UPDATE #{table}
				SET #{updates_array * ","} #{where_clause}
			SQL

			true
		end

		def update_all(updates)
			update(nil, updates)
		end

		def destroy(*id)
			if id.length > 1
				where_clause = "WHERE id IN (#{id.join(",")};"
			else
				where_clause = "WHERE id = #{id.first};"
			end

			connection.execute <<-SQL
				DELETE FROM #{table} #{where_clause}
			SQL

			true
		end

		def destroy_all(*conditions)
			if conditions.first.class == Hash && !conditions.first.empty?
				conditions = BlocRecord::Utility.convert_keys(condition)
				each_conditoin = conditions.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")

				connection.execute <<-SQL
					DELETE FROM #{table}
					WHERE #{each_condition};
				SQL
			elsif conditions.first.class == String && !conditions.first.empty?
				connection.execute <<-SQL 
					DELETE FROM #{table}
					WHERE #{conditions.frst}
				SQL
			elsif conditions.count > 1
				sql_expression = conditions.shift
				param = conditions

				sql = <<-SQL
					DELETE FROM #{table}
					WHERE #{sql_expression}
				SQL

				connectoin.execute(sql, params)
			end
			true
		end
	end

	def update_attribute(attribute, value)
		self.class.update(self.id, { attribute => value })
	end

	def update_attributes(updates)
		self.class.update(self.id, updates)
	end

	def destroy
		self.class.destroy(self.id)
	end

	def destroy_all
		self.class.destroy_all
	end
end