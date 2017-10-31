# require 'yaml'

# hsh = YAML.load_file 'default.conf/fields_semantics.yml'

class Fields
	def self.[](cls_name)
		case cls_name
		when "Statistics"
			{
				keys:"keys",
				top:"top",
				sort_type:"sort_type",
				sort_order:"sort_order",
			}
		when "LogFormat"
			{
				msg:"msg",
				service:"service",
				server:"server",
				date_fields:['year','month','day','hour','minute','second', 'timezone']
			}
		when "DistributionKeys"
			{
				"filename" => true,
				"server" => true,
				"service" => true,
				"type" => true,
				"date" => true,
				"errno" => true,
				"logline" => true,
				"msg" => true,
			}
		end
	end
	def self.special_format_fields
		# те поля, которые имеют специальное значение при определении формата лога
		[
			"year",
			"month",
			"day",
			"hour",
			"minute",
			"second",
			"timezone",
			"server",
			"service",
			"msg",
		]
	end
	def self.keys_to_sym(fields_list)
		fields_list.map {|field| Fields["DistributionKeys"].has_key?(field) ? field.to_sym : field}
	end
end
