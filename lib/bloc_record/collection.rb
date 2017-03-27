module BlocRecord
	class Collection < Array
		def update_all(updates)
			ids = self.map(&:id)

			self.any? ? self.first.class.update(ids, updates) : false 
		end

		def destroy_all
			ids = ""
			self.each do |entry|
				ids << entry.id + ", "
			end

			connection.execute <<-SQL
				DELETE FROM #{table}
				WHERE id in (#{ids})
			SQL
		end

	end
end