module BlocRecord
	class Collection < Array
		def update_all(updates)
			ids = self.map(&:id)

			self.any? ? self.first.class.update(ids, updates) : false 
		end

		def take(num=1)
			taken_entries = []
			if num > 1
				for i in (0...num) do
					taken_entries << self[i]
				end
			else
				return self.first
			end

			taken_entries
		end

		def where(args)
	      filtered_where = []
	      self.each do |entry|
	        args.each_key do |key|
	          if entry[key] == args[key]
	          	filtered_where << entry
	          end
	        end
	      end
	      filtered_where
	    end
	end
end