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

		def take(num=1)
			taken_records = []
			if num > 1
				for i in (0..num) do
				  taken_records << self[i]
				end
			else
				return self.first
			end
			taken_records
		end
	end
end