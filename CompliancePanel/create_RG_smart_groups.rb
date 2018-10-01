=begin 
		create_smart_groups.rb v1.0

		Written by Christopher Kemp for Accenture, with invaluable assistance from Chris Lasell at Pixar.
		This script uses ruby-jss to create Smart Groups in your Jamf Pro server, derived from a list of 
		Patch Software titles' ID numbers. 
		
		The Patch Titles must be set up within your Jamf Pro server; 
		and you must have a plain text list containing the IDs of the titles that you wish to set up groups for.

=end 
require 'ruby-jss'
		# "level" refers to how many prior versions you wish to put into the "Current" group. For example,
		# if your org considers N-2 current, then level = 2. For only the current version, level = 0.
level = 2

		# Server connection details
your_server = "" # Fill in the Blank!
your_user		= "" # Fill in the Blank!
your_pass		= "" # Fill in the Blank!
##### Do not edit below this line! #####
		# Connect to the server
JSS::API.connect server: your_server, port: 443, timeout: 600, use_ssl: true, user: your_user, pw: your_pass
		# Get the list of computer names to populate the group
print "Location of Patch Title ID List for group creation: "
id_list = gets.strip
		# Read in text file 
IO.foreach(id_list) do |line|
	pt_id = line.strip
	print "creating group for Patch ID #{pt_id}...\n"
		# get the Patch Title data from the ID
	title = JSS::PatchTitle.fetch id = pt_id.to_i
		# Pull the name of the Patch Title to use for the new group
	new_group = title.name
		# Set the version number according to level
	current = title.versions.keys[level]
		# Create new group with "Current" title
	group1 = JSS::ComputerGroup.make name: "COMPLIANCE - #{new_group} Current", type: :smart
		# Define the Smart Group criteria
	crtn_0 = JSS::Criteriable::Criterion.new(
  and_or: :and, 
  name: "Patch Reporting: #{new_group}", 
  search_type: "greater than or equal", 
  value: current
) 
		# Create the Criteria instance and assign to the group
	crta = JSS::Criteriable::Criteria.new [crtn_0]
	group1.criteria = crta
		# Save the group to the Jamf server
	group1.save
	print "COMPLIANCE - #{new_group} Current group created.\n"

		# Create new group with "NOT Current" title
	group2 = JSS::ComputerGroup.make name: "COMPLIANCE - #{new_group} NOT Current", type: :smart
	crtn_0 = JSS::Criteriable::Criterion.new(
  and_or: :and, 
  name: "Patch Reporting: #{new_group}", 
  search_type: "less than", 
  value: current
) 
	crtn_1 = JSS::Criteriable::Criterion.new(
  and_or: :and, 
  name: "Patch Reporting: #{new_group}", 
  search_type: "is not", 
  value: "Unknown Version"
)

		# Create the Criteria instance and assign to the group
	crta = JSS::Criteriable::Criteria.new [crtn_0, crtn_1]
	group2.criteria = crta
		# Save the group to the Jamf server
	group2.save
	print "COMPLIANCE - #{new_group} NOT Current group created.\n"     
end
